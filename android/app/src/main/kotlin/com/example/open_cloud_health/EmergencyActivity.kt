package com.example.open_cloud_health

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.graphics.*
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

class EmergencyActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 1. Show on top of secure lockscreen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        
        setContentView(R.layout.activity_emergency)
        
        // 2. Setup Close Button
        findViewById<ImageView>(R.id.closeBtn).setOnClickListener {
            finish()
        }
        
        // 3. Load data
        loadEmergencyData()
    }

    private fun loadEmergencyData() {
        val dbFile = getDatabasePath("opencloudhealth.db")
        if (!dbFile.exists()) {
            showError("No profiles or medical data set up yet.")
            return
        }

        var db: SQLiteDatabase? = null
        try {
            db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READONLY)
            
            // Check all enabled lock screen settings
            val settingsCursor = db.rawQuery("SELECT * FROM lock_screen_settings WHERE isEnabled = 'true'", null)
            val settingsList = mutableListOf<Map<String, String>>()
            
            if (settingsCursor.moveToFirst()) {
                do {
                    val settingsMap = mutableMapOf<String, String>()
                    val columnNames = settingsCursor.columnNames
                    for (col in columnNames) {
                        settingsMap[col] = settingsCursor.getString(settingsCursor.getColumnIndexOrThrow(col)) ?: ""
                    }
                    settingsList.add(settingsMap)
                } while (settingsCursor.moveToNext())
            }
            settingsCursor.close()

            if (settingsList.isEmpty()) {
                showError("Emergency Medical ID is not enabled.\nConfigure it under settings first.")
                return
            }

            // Hide Error screen, show Content layout
            findViewById<View>(R.id.errorContainer).visibility = View.GONE
            findViewById<View>(R.id.scrollContainer).visibility = View.VISIBLE

            val profilesListContainer = findViewById<LinearLayout>(R.id.profilesListContainer)
            profilesListContainer.removeAllViews()

            for (i in 0 until settingsList.size) {
                val settings = settingsList[i]
                val profileId = settings["profileId"] ?: ""
                val showName = settings["showName"] == "true"
                val showAge = settings["showAge"] == "true"
                val showBloodType = settings["showBloodType"] == "true"
                val showOrganDonor = settings["showOrganDonor"] == "true"
                val showChronicConditions = settings["showChronicConditions"] == "true"
                val showAllergies = settings["showAllergies"] == "true"
                val showMedications = settings["showMedications"] == "true"
                val showContacts = settings["showContacts"] == "true"

                // Fetch Profile
                val profileCursor = db.rawQuery("SELECT * FROM profiles WHERE id = ?", arrayOf(profileId))
                if (!profileCursor.moveToFirst()) {
                    profileCursor.close()
                    continue
                }
                
                val name = profileCursor.getString(profileCursor.getColumnIndexOrThrow("name"))
                val middleNames = profileCursor.getString(profileCursor.getColumnIndexOrThrow("middleNames")) ?: ""
                val surname = profileCursor.getString(profileCursor.getColumnIndexOrThrow("surname"))
                val dateOfBirthStr = profileCursor.getString(profileCursor.getColumnIndexOrThrow("dateOfBirth"))
                val bloodType = profileCursor.getString(profileCursor.getColumnIndexOrThrow("bloodType"))
                val isOrganDonor = profileCursor.getString(profileCursor.getColumnIndexOrThrow("isOrganDonor")) == "true"
                val chronicConditionsStr = profileCursor.getString(profileCursor.getColumnIndexOrThrow("chronicConditions")) ?: ""
                profileCursor.close()

                // Inflate a profile layout card
                val profileView = layoutInflater.inflate(R.layout.item_profile_emergency, profilesListContainer, false)

                // Render Profile Image
                val profileImageView = profileView.findViewById<ImageView>(R.id.profileImage)
                loadCircularProfileImage(this, profileId, profileImageView)

                // Render Name
                val nameTextView = profileView.findViewById<TextView>(R.id.nameText)
                if (showName) {
                    nameTextView.text = "$name $middleNames $surname".replace("\\s+".toRegex(), " ").trim()
                    nameTextView.visibility = View.VISIBLE
                } else {
                    nameTextView.text = "Medical Information"
                    nameTextView.visibility = View.VISIBLE
                }

                // Render Quick Tags (Age, Blood, Donor)
                val tagsLayout = profileView.findViewById<LinearLayout>(R.id.tagsLayout)
                tagsLayout.removeAllViews()
                
                if (showAge && dateOfBirthStr.isNotEmpty()) {
                    val age = calculateAge(dateOfBirthStr)
                    addTag(tagsLayout, "AGE", "$age", R.drawable.tag_age_background, 0xFF9C27B0.toInt())
                }
                if (showBloodType && bloodType.isNotEmpty()) {
                    addTag(tagsLayout, "BLOOD", bloodType, R.drawable.tag_blood_background, 0xFFE53935.toInt())
                }
                if (showOrganDonor) {
                    addTag(tagsLayout, "DONOR", if (isOrganDonor) "YES" else "NO", R.drawable.tag_donor_background, 0xFFE91E63.toInt())
                }

                // Render Chronic Conditions
                val conditionsCard = profileView.findViewById<View>(R.id.conditionsCard)
                val conditionsContainer = profileView.findViewById<LinearLayout>(R.id.conditionsContainer)
                conditionsContainer.removeAllViews()
                if (showChronicConditions && chronicConditionsStr.isNotEmpty()) {
                    val conditions = chronicConditionsStr.split(",").map { it.trim() }.filter { it.isNotEmpty() }
                    if (conditions.isNotEmpty()) {
                        conditionsCard.visibility = View.VISIBLE
                        for (cond in conditions) {
                            addConditionChip(conditionsContainer, cond)
                        }
                    } else {
                        conditionsCard.visibility = View.GONE
                    }
                } else {
                    conditionsCard.visibility = View.GONE
                }

                // Render Allergies
                val allergiesCard = profileView.findViewById<View>(R.id.allergiesCard)
                val allergiesContainer = profileView.findViewById<LinearLayout>(R.id.allergiesContainer)
                allergiesContainer.removeAllViews()
                if (showAllergies) {
                    val allergyCursor = db.rawQuery("SELECT * FROM allergy WHERE profileId = ?", arrayOf(profileId))
                    if (allergyCursor.moveToFirst()) {
                        allergiesCard.visibility = View.VISIBLE
                        do {
                            val allergyName = allergyCursor.getString(allergyCursor.getColumnIndexOrThrow("name"))
                            val note = allergyCursor.getString(allergyCursor.getColumnIndexOrThrow("note")) ?: ""
                            addAllergyRow(allergiesContainer, allergyName, note)
                        } while (allergyCursor.moveToNext())
                    } else {
                        allergiesCard.visibility = View.GONE
                    }
                    allergyCursor.close()
                } else {
                    allergiesCard.visibility = View.GONE
                }

                // Render Medications
                val medicationsCard = profileView.findViewById<View>(R.id.medicationsCard)
                val medicationsContainer = profileView.findViewById<LinearLayout>(R.id.medicationsContainer)
                medicationsContainer.removeAllViews()
                if (showMedications) {
                    val medsCursor = db.rawQuery("SELECT * FROM medications WHERE profileId = ? AND isActive = 'true'", arrayOf(profileId))
                    if (medsCursor.moveToFirst()) {
                        medicationsCard.visibility = View.VISIBLE
                        do {
                            val medName = medsCursor.getString(medsCursor.getColumnIndexOrThrow("name"))
                            val dosage = medsCursor.getString(medsCursor.getColumnIndexOrThrow("dosage")) ?: ""
                            addMedicationRow(medicationsContainer, medName, dosage)
                        } while (medsCursor.moveToNext())
                    } else {
                        medicationsCard.visibility = View.GONE
                    }
                    medsCursor.close()
                } else {
                    medicationsCard.visibility = View.GONE
                }

                // Render ICE Contacts
                val contactsCard = profileView.findViewById<View>(R.id.contactsCard)
                val contactsContainer = profileView.findViewById<LinearLayout>(R.id.contactsContainer)
                contactsContainer.removeAllViews()
                if (showContacts) {
                    val contactsCursor = db.rawQuery("SELECT * FROM emergency_contacts WHERE profileId = ?", arrayOf(profileId))
                    if (contactsCursor.moveToFirst()) {
                        contactsCard.visibility = View.VISIBLE
                        do {
                            val contactName = contactsCursor.getString(contactsCursor.getColumnIndexOrThrow("name"))
                            val rel = contactsCursor.getString(contactsCursor.getColumnIndexOrThrow("relationship"))
                            val phone = contactsCursor.getString(contactsCursor.getColumnIndexOrThrow("phoneNumber"))
                            addContactRow(contactsContainer, contactName, rel, phone)
                        } while (contactsCursor.moveToNext())
                    } else {
                        contactsCard.visibility = View.GONE
                    }
                    contactsCursor.close()
                } else {
                    contactsCard.visibility = View.GONE
                }

                // Hide Divider for the last item
                if (i == settingsList.size - 1) {
                    profileView.findViewById<View>(R.id.profileDivider).visibility = View.GONE
                }

                profilesListContainer.addView(profileView)
            }

        } catch (e: Exception) {
            showError("Failed to load emergency data: ${e.localizedMessage}")
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

    private fun addTag(container: LinearLayout, label: String, value: String, backgroundRes: Int, textColor: Int) {
        val view = layoutInflater.inflate(R.layout.item_emergency_tag, container, false)
        view.setBackgroundResource(backgroundRes)
        view.findViewById<TextView>(R.id.tagLabel).text = label
        view.findViewById<TextView>(R.id.tagValue).run {
            text = value
            setTextColor(textColor)
        }
        container.addView(view)
    }

    private fun addConditionChip(container: LinearLayout, text: String) {
        val textView = TextView(this).apply {
            this.text = text
            setTextColor(0xFFFFFFFF.toInt())
            textSize = 14f
            setTypeface(null, android.graphics.Typeface.BOLD)
            setBackgroundResource(R.drawable.chip_background)
            setPadding(24, 12, 24, 12)
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            lp.setMargins(0, 0, 0, 16)
            layoutParams = lp
        }
        container.addView(textView)
    }

    private fun addAllergyRow(container: LinearLayout, name: String, note: String) {
        val view = layoutInflater.inflate(R.layout.item_allergy_med, container, false)
        view.findViewById<TextView>(R.id.itemName).text = name
        view.findViewById<TextView>(R.id.itemSub).run {
            if (note.isNotEmpty()) {
                text = note
                visibility = View.VISIBLE
            } else {
                visibility = View.GONE
            }
        }
        view.findViewById<ImageView>(R.id.itemIcon).setImageResource(R.drawable.ic_warning_red)
        container.addView(view)
    }

    private fun addMedicationRow(container: LinearLayout, name: String, dosage: String) {
        val view = layoutInflater.inflate(R.layout.item_allergy_med, container, false)
        view.findViewById<TextView>(R.id.itemName).text = name
        view.findViewById<TextView>(R.id.itemSub).run {
            if (dosage.isNotEmpty()) {
                text = dosage
                visibility = View.VISIBLE
            } else {
                visibility = View.GONE
            }
        }
        view.findViewById<ImageView>(R.id.itemIcon).setImageResource(R.drawable.ic_meds_blue)
        container.addView(view)
    }

    private fun addContactRow(container: LinearLayout, name: String, relationship: String, phone: String) {
        val view = layoutInflater.inflate(R.layout.item_ice_contact, container, false)
        view.findViewById<TextView>(R.id.contactName).text = name
        view.findViewById<TextView>(R.id.contactSub).text = relationship
        view.findViewById<TextView>(R.id.contactPhone).text = phone
        
        view.setOnClickListener {
            try {
                val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$phone"))
                startActivity(intent)
            } catch (e: Exception) {
                // Ignore if dialer is not available
            }
        }
        container.addView(view)
    }

    private fun loadCircularProfileImage(context: Context, profileId: String, imageView: ImageView) {
        try {
            val appFlutterDir = File(context.filesDir.parentFile, "app_flutter")
            val imageFile = File(appFlutterDir, "profileImages/${profileId}.jpg")
            if (imageFile.exists() && imageFile.length() > 0) {
                val bitmap = BitmapFactory.decodeFile(imageFile.absolutePath)
                if (bitmap != null) {
                    val circularBitmap = getCircularBitmap(bitmap)
                    imageView.setImageBitmap(circularBitmap)
                    return
                }
            }
        } catch (e: Exception) {
            Log.e("EmergencyActivity", "Error loading profile image: ${e.localizedMessage}")
        }
        // Fallback: launcher icon
        imageView.setImageResource(R.mipmap.launcher_icon)
    }

    private fun getCircularBitmap(srcBitmap: Bitmap): Bitmap {
        val squareBitmap = if (srcBitmap.width >= srcBitmap.height) {
            Bitmap.createBitmap(srcBitmap, srcBitmap.width / 2 - srcBitmap.height / 2, 0, srcBitmap.height, srcBitmap.height)
        } else {
            Bitmap.createBitmap(srcBitmap, 0, srcBitmap.height / 2 - srcBitmap.width / 2, srcBitmap.width, srcBitmap.width)
        }
        
        val dstBitmap = Bitmap.createBitmap(squareBitmap.width, squareBitmap.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(dstBitmap)
        val paint = Paint()
        val rect = Rect(0, 0, squareBitmap.width, squareBitmap.height)
        
        paint.isAntiAlias = true
        canvas.drawARGB(0, 0, 0, 0)
        paint.color = Color.WHITE
        canvas.drawCircle(squareBitmap.width / 2f, squareBitmap.height / 2f, squareBitmap.width / 2f, paint)
        
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        canvas.drawBitmap(squareBitmap, rect, rect, paint)
        return dstBitmap
    }

    private fun showError(message: String) {
        findViewById<View>(R.id.scrollContainer).visibility = View.GONE
        findViewById<View>(R.id.errorContainer).visibility = View.VISIBLE
        findViewById<TextView>(R.id.errorText).text = message
    }
}
