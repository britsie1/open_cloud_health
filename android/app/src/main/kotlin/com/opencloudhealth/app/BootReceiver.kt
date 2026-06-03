package com.opencloudhealth.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.util.Log
import java.text.SimpleDateFormat
import java.util.*

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || 
            intent.action == "android.intent.action.QUICKBOOT_POWERON" ||
            intent.action == "com.htc.intent.action.QUICKBOOT_POWERON") {
            Log.d("BootReceiver", "Device booted. Syncing emergency notification.")
            syncEmergencyNotification(context)
        }
    }

    private fun syncEmergencyNotification(context: Context) {
        val dbFile = context.getDatabasePath("opencloudhealth.db")
        if (!dbFile.exists()) return

        var db: SQLiteDatabase? = null
        try {
            db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READONLY)
            
            val settingsCursor = db.rawQuery("SELECT * FROM lock_screen_settings WHERE isEnabled = 'true' LIMIT 1", null)
            if (!settingsCursor.moveToFirst()) {
                settingsCursor.close()
                return
            }
            
            val profileId = settingsCursor.getString(settingsCursor.getColumnIndexOrThrow("profileId"))
            val showName = settingsCursor.getString(settingsCursor.getColumnIndexOrThrow("showName")) == "true"
            val showAge = settingsCursor.getString(settingsCursor.getColumnIndexOrThrow("showAge")) == "true"
            val showBloodType = settingsCursor.getString(settingsCursor.getColumnIndexOrThrow("showBloodType")) == "true"
            val showOrganDonor = settingsCursor.getString(settingsCursor.getColumnIndexOrThrow("showOrganDonor")) == "true"
            val showChronicConditions = settingsCursor.getString(settingsCursor.getColumnIndexOrThrow("showChronicConditions")) == "true"
            val showAllergies = settingsCursor.getString(settingsCursor.getColumnIndexOrThrow("showAllergies")) == "true"
            val showMedications = settingsCursor.getString(settingsCursor.getColumnIndexOrThrow("showMedications")) == "true"
            val showContacts = settingsCursor.getString(settingsCursor.getColumnIndexOrThrow("showContacts")) == "true"
            settingsCursor.close()

            val profileCursor = db.rawQuery("SELECT * FROM profiles WHERE id = ?", arrayOf(profileId))
            if (!profileCursor.moveToFirst()) {
                profileCursor.close()
                return
            }
            val name = profileCursor.getString(profileCursor.getColumnIndexOrThrow("name"))
            val surname = profileCursor.getString(profileCursor.getColumnIndexOrThrow("surname"))
            val dateOfBirthStr = profileCursor.getString(profileCursor.getColumnIndexOrThrow("dateOfBirth"))
            val bloodType = profileCursor.getString(profileCursor.getColumnIndexOrThrow("bloodType"))
            val isOrganDonor = profileCursor.getString(profileCursor.getColumnIndexOrThrow("isOrganDonor")) == "true"
            val chronicConditionsStr = profileCursor.getString(profileCursor.getColumnIndexOrThrow("chronicConditions")) ?: ""
            profileCursor.close()

            val age = calculateAge(dateOfBirthStr)
            val details = mutableListOf<String>()
            if (showAge) details.add("Age: $age")
            if (showBloodType) details.add("Blood: $bloodType")
            if (showOrganDonor) details.add("Donor: ${if (isOrganDonor) "Yes" else "No"}")

            val bodyBuilder = StringBuilder()
            if (details.isNotEmpty()) bodyBuilder.append(details.joinToString(" | ")).append("\n")

            if (showChronicConditions && chronicConditionsStr.isNotEmpty()) {
                val conditions = chronicConditionsStr.split(",").map { it.trim() }.filter { it.isNotEmpty() }
                if (conditions.isNotEmpty()) {
                    bodyBuilder.append("Conditions: ").append(conditions.joinToString(", ")).append("\n")
                }
            }

            if (showAllergies) {
                val allergyCursor = db.rawQuery("SELECT * FROM allergy WHERE profileId = ?", arrayOf(profileId))
                val allergies = mutableListOf<String>()
                if (allergyCursor.moveToFirst()) {
                    do {
                        allergies.add(allergyCursor.getString(allergyCursor.getColumnIndexOrThrow("name")))
                    } while (allergyCursor.moveToNext())
                }
                allergyCursor.close()
                if (allergies.isNotEmpty()) {
                    bodyBuilder.append("Allergies: ").append(allergies.joinToString(", ")).append("\n")
                }
            }

            if (showMedications) {
                val medsCursor = db.rawQuery("SELECT * FROM medications WHERE profileId = ? AND isActive = 'true'", arrayOf(profileId))
                val medications = mutableListOf<String>()
                if (medsCursor.moveToFirst()) {
                    do {
                        medications.add(medsCursor.getString(medsCursor.getColumnIndexOrThrow("name")))
                    } while (medsCursor.moveToNext())
                }
                medsCursor.close()
                if (medications.isNotEmpty()) {
                    bodyBuilder.append("Meds: ").append(medications.joinToString(", ")).append("\n")
                }
            }

            if (showContacts) {
                val contactsCursor = db.rawQuery("SELECT * FROM emergency_contacts WHERE profileId = ?", arrayOf(profileId))
                if (contactsCursor.moveToFirst()) {
                    bodyBuilder.append("Emergency Contacts:\n")
                    do {
                        val cName = contactsCursor.getString(contactsCursor.getColumnIndexOrThrow("name"))
                        val rel = contactsCursor.getString(contactsCursor.getColumnIndexOrThrow("relationship"))
                        val phone = contactsCursor.getString(contactsCursor.getColumnIndexOrThrow("phoneNumber"))
                        bodyBuilder.append("• $cName ($rel): $phone\n")
                    } while (contactsCursor.moveToNext())
                }
                contactsCursor.close()
            }

            val title = "🚨 Emergency Medical ID: ${if (showName) "$name $surname" else "Medical Information"}"
            val body = bodyBuilder.toString().trim()

            NotificationHelper.showNotification(context, title, body)
        } catch (e: Exception) {
            Log.e("BootReceiver", "Error re-posting notification: ${e.localizedMessage}")
        } finally {
            db?.close()
        }
    }

    private fun calculateAge(dobStr: String): Int {
        try {
            val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)
            val dob = sdf.parse(dobStr) ?: return 0
            val today = Calendar.getInstance()
            val birthDate = Calendar.getInstance()
            birthDate.time = dob
            var age = today.get(Calendar.YEAR) - birthDate.get(Calendar.YEAR)
            if (today.get(Calendar.DAY_OF_YEAR) < birthDate.get(Calendar.DAY_OF_YEAR)) {
                age--
            }
            return age
        } catch (e: Exception) {
            return 0
        }
    }
}
