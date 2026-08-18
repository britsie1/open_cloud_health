package com.opencloudhealth.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.util.Log
import java.text.SimpleDateFormat
import java.util.*

import android.os.Build
import android.os.UserManager

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_LOCKED_BOOT_COMPLETED ||
            action == Intent.ACTION_BOOT_COMPLETED || 
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON") {
            Log.d("BootReceiver", "Device boot event: $action")

            val isUserUnlocked = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                val userManager = context.getSystemService(Context.USER_SERVICE) as? UserManager
                userManager?.isUserUnlocked ?: true
            } else {
                true
            }

            if (!isUserUnlocked) {
                Log.d("BootReceiver", "User is locked (Direct Boot state). Restoring notification from Device-Protected storage.")
                restoreFromDeviceProtectedStorage(context)
            } else {
                val synced = syncEmergencyNotification(context)
                if (!synced) {
                    Log.d("BootReceiver", "Database sync did not post notification. Falling back to Device-Protected storage.")
                    restoreFromDeviceProtectedStorage(context)
                }
            }
        }
    }

    private fun restoreFromDeviceProtectedStorage(context: Context): Boolean {
        try {
            val dpContext = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                context.createDeviceProtectedStorageContext()
            } else {
                context
            }
            val prefs = dpContext.getSharedPreferences("emergency_cache", Context.MODE_PRIVATE)
            val isEnabled = prefs.getBoolean("isEnabled", false)
            val title = prefs.getString("title", null)
            val body = prefs.getString("body", null)
            if (isEnabled && !title.isNullOrEmpty() && !body.isNullOrEmpty()) {
                NotificationHelper.showNotification(context, title, body)
                return true
            }
        } catch (e: Exception) {
            Log.e("BootReceiver", "Error restoring from Device-Protected storage: ${e.localizedMessage}")
        }
        return false
    }

    private fun syncEmergencyNotification(context: Context): Boolean {
        val dbFile = context.getDatabasePath("opencloudhealth.db")
        if (!dbFile.exists()) return false

        var db: SQLiteDatabase? = null
        try {
            db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READONLY)
            
            val settingsCursor = db.rawQuery("SELECT * FROM lock_screen_settings WHERE isEnabled = 1", null)
            if (!settingsCursor.moveToFirst()) {
                settingsCursor.close()
                return false
            }

            var primaryProfileId: String? = null
            val primaryCursor = db.rawQuery("SELECT value FROM settings WHERE key = 'primary_profile_id' LIMIT 1", null)
            if (primaryCursor.moveToFirst()) {
                primaryProfileId = primaryCursor.getString(0)
            }
            primaryCursor.close()

            val settingsList = mutableListOf<LockScreenConfig>()
            val profileIdCol = settingsCursor.getColumnIndexOrThrow("profileId")
            val showNameCol = settingsCursor.getColumnIndexOrThrow("showName")
            val showAgeCol = settingsCursor.getColumnIndexOrThrow("showAge")
            val showBloodTypeCol = settingsCursor.getColumnIndexOrThrow("showBloodType")
            val showOrganDonorCol = settingsCursor.getColumnIndexOrThrow("showOrganDonor")
            val showChronicConditionsCol = settingsCursor.getColumnIndexOrThrow("showChronicConditions")
            val showAllergiesCol = settingsCursor.getColumnIndexOrThrow("showAllergies")
            val showMedicationsCol = settingsCursor.getColumnIndexOrThrow("showMedications")
            val showContactsCol = settingsCursor.getColumnIndexOrThrow("showContacts")

            do {
                settingsList.add(
                    LockScreenConfig(
                        profileId = settingsCursor.getString(profileIdCol) ?: "",
                        showName = settingsCursor.getInt(showNameCol) == 1,
                        showAge = settingsCursor.getInt(showAgeCol) == 1,
                        showBloodType = settingsCursor.getInt(showBloodTypeCol) == 1,
                        showOrganDonor = settingsCursor.getInt(showOrganDonorCol) == 1,
                        showChronicConditions = settingsCursor.getInt(showChronicConditionsCol) == 1,
                        showAllergies = settingsCursor.getInt(showAllergiesCol) == 1,
                        showMedications = settingsCursor.getInt(showMedicationsCol) == 1,
                        showContacts = settingsCursor.getInt(showContactsCol) == 1
                    )
                )
            } while (settingsCursor.moveToNext())
            settingsCursor.close()

            var targetRowIndex = 0
            if (primaryProfileId != null) {
                val idx = settingsList.indexOfFirst { it.profileId == primaryProfileId }
                if (idx != -1) {
                    targetRowIndex = idx
                }
            }
            val setRow = settingsList[targetRowIndex]
            val profileId = setRow.profileId

            val profileCursor = db.rawQuery("SELECT * FROM profiles WHERE id = ?", arrayOf(profileId))
            if (!profileCursor.moveToFirst()) {
                profileCursor.close()
                return false
            }
            val name = profileCursor.getString(profileCursor.getColumnIndexOrThrow("name")) ?: ""
            val surname = profileCursor.getString(profileCursor.getColumnIndexOrThrow("surname")) ?: ""
            val dateOfBirthEpoch = profileCursor.getLong(profileCursor.getColumnIndexOrThrow("dateOfBirth"))
            val bloodType = profileCursor.getString(profileCursor.getColumnIndexOrThrow("bloodType")) ?: ""
            val isOrganDonor = profileCursor.getInt(profileCursor.getColumnIndexOrThrow("isOrganDonor")) == 1
            val chronicConditionsStr = profileCursor.getString(profileCursor.getColumnIndexOrThrow("chronicConditions")) ?: ""
            profileCursor.close()

            val age = calculateAge(dateOfBirthEpoch)
            val dobFormatted = formatDob(dateOfBirthEpoch)
            val details = mutableListOf<String>()
            if (setRow.showAge && dateOfBirthEpoch > 0) {
                details.add("DOB: $dobFormatted")
                details.add("Age: $age")
            }
            if (setRow.showBloodType && bloodType.isNotEmpty()) details.add("Blood: $bloodType")
            if (setRow.showOrganDonor) details.add("Donor: ${if (isOrganDonor) "Yes" else "No"}")

            val bodyBuilder = StringBuilder()
            if (details.isNotEmpty()) bodyBuilder.append(details.joinToString(" | ")).append("\n")

            if (setRow.showChronicConditions) {
                val conditions = if (chronicConditionsStr.isNotEmpty()) chronicConditionsStr.split(",").map { it.trim() }.filter { it.isNotEmpty() } else emptyList()
                bodyBuilder.append("Conditions: ").append(if (conditions.isNotEmpty()) conditions.joinToString(", ") else "None").append("\n")
            }

            if (setRow.showAllergies) {
                val allergyCursor = db.rawQuery("SELECT * FROM allergy WHERE profileId = ?", arrayOf(profileId))
                val allergies = mutableListOf<String>()
                if (allergyCursor.moveToFirst()) {
                    do {
                        allergies.add(allergyCursor.getString(allergyCursor.getColumnIndexOrThrow("name")))
                    } while (allergyCursor.moveToNext())
                }
                allergyCursor.close()
                bodyBuilder.append("Allergies: ").append(if (allergies.isNotEmpty()) allergies.joinToString(", ") else "None").append("\n")
            }

            if (setRow.showMedications) {
                val medsCursor = db.rawQuery("SELECT * FROM medications WHERE profileId = ? AND isActive = 1", arrayOf(profileId))
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

            if (setRow.showContacts) {
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

            val title = "🚨 Emergency Medical ID: ${if (setRow.showName) "$name $surname" else "Medical Information"}"
            val body = bodyBuilder.toString().trim()

            NotificationHelper.showNotification(context, title, body)
            return true
        } catch (e: Exception) {
            Log.e("BootReceiver", "Error re-posting notification: ${e.localizedMessage}")
        } finally {
            db?.close()
        }
        return false
    }

    private data class LockScreenConfig(
        val profileId: String,
        val showName: Boolean,
        val showAge: Boolean,
        val showBloodType: Boolean,
        val showOrganDonor: Boolean,
        val showChronicConditions: Boolean,
        val showAllergies: Boolean,
        val showMedications: Boolean,
        val showContacts: Boolean
    )

    private fun formatDob(epoch: Long): String {
        if (epoch <= 0L) return ""
        try {
            val millis = if (epoch < 100000000000L) epoch * 1000L else epoch
            val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)
            return sdf.format(Date(millis))
        } catch (e: Exception) {
            return ""
        }
    }

    private fun calculateAge(epoch: Long): Int {
        if (epoch <= 0L) return 0
        try {
            val millis = if (epoch < 100000000000L) epoch * 1000L else epoch
            val dobDate = Date(millis)
            val today = Calendar.getInstance()
            val birthDate = Calendar.getInstance().apply { time = dobDate }
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
