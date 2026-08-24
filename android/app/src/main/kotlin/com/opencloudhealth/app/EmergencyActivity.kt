package com.opencloudhealth.app

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
            val settingsCursor = db.rawQuery("SELECT * FROM lock_screen_settings WHERE isEnabled = 1", null)
            val settingsList = mutableListOf<LockScreenConfig>()
            
            if (settingsCursor.moveToFirst()) {
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
            }
            settingsCursor.close()

            if (settingsList.isEmpty()) {
                showError("Emergency Medical ID is not enabled.\nConfigure it under settings first.")
                return
            }

            // Check if there is a primary profile to sort first
            var primaryProfileId: String? = null
            val primaryCursor = db.rawQuery("SELECT value FROM settings WHERE key = 'primary_profile_id' LIMIT 1", null)
            if (primaryCursor.moveToFirst()) {
                primaryProfileId = primaryCursor.getString(0)
            }
            primaryCursor.close()

            if (primaryProfileId != null) {
                val primaryIndex = settingsList.indexOfFirst { it.profileId == primaryProfileId }
                if (primaryIndex != -1) {
                    val primarySettings = settingsList.removeAt(primaryIndex)
                    settingsList.add(0, primarySettings)
                }
            }

            // Hide Error screen, show Content layout
            findViewById<View>(R.id.errorContainer).visibility = View.GONE
            findViewById<View>(R.id.scrollContainer).visibility = View.VISIBLE

            val profilesListContainer = findViewById<LinearLayout>(R.id.profilesListContainer)
            profilesListContainer.removeAllViews()

            for (i in 0 until settingsList.size) {
                val settings = settingsList[i]
                val profileId = settings.profileId

                // Fetch Profile
                val profileCursor = db.rawQuery("SELECT * FROM profiles WHERE id = ?", arrayOf(profileId))
                if (!profileCursor.moveToFirst()) {
                    profileCursor.close()
                    continue
                }
                
                val name = profileCursor.getString(profileCursor.getColumnIndexOrThrow("name")) ?: ""
                val middleNames = profileCursor.getString(profileCursor.getColumnIndexOrThrow("middleNames")) ?: ""
                val surname = profileCursor.getString(profileCursor.getColumnIndexOrThrow("surname")) ?: ""
                val dateOfBirthEpoch = profileCursor.getLong(profileCursor.getColumnIndexOrThrow("dateOfBirth"))
                val bloodType = profileCursor.getString(profileCursor.getColumnIndexOrThrow("bloodType")) ?: ""
                val isOrganDonor = profileCursor.getInt(profileCursor.getColumnIndexOrThrow("isOrganDonor")) == 1
                val chronicConditionsStr = profileCursor.getString(profileCursor.getColumnIndexOrThrow("chronicConditions")) ?: ""
                profileCursor.close()

                // Inflate a profile layout card
                val profileView = layoutInflater.inflate(R.layout.item_profile_emergency, profilesListContainer, false)

                // Render Profile Image
                val profileImageView = profileView.findViewById<ImageView>(R.id.profileImage)
                loadCircularProfileImage(this, profileId, profileImageView)

                // Render Name
                val nameTextView = profileView.findViewById<TextView>(R.id.nameText)
                if (settings.showName) {
                    nameTextView.text = "$name $middleNames $surname".replace("\\s+".toRegex(), " ").trim()
                    nameTextView.visibility = View.VISIBLE
                } else {
                    nameTextView.text = "Medical Information"
                    nameTextView.visibility = View.VISIBLE
                }

                // Render DOB
                val dobTextView = profileView.findViewById<TextView>(R.id.dobText)
                if (settings.showAge && dateOfBirthEpoch > 0) {
                    val dobFormatted = formatDob(dateOfBirthEpoch)
                    dobTextView.text = "Date of Birth: $dobFormatted"
                    dobTextView.visibility = View.VISIBLE
                } else {
                    dobTextView.visibility = View.GONE
                }

                // Render Quick Tags (Age, Blood, Donor)
                val tagsLayout = profileView.findViewById<LinearLayout>(R.id.tagsLayout)
                tagsLayout.removeAllViews()
                
                if (settings.showAge && dateOfBirthEpoch > 0) {
                    val age = calculateAge(dateOfBirthEpoch)
                    addTag(tagsLayout, "AGE", "$age", R.drawable.tag_age_background, 0xFF9C27B0.toInt())
                }
                if (settings.showBloodType && bloodType.isNotEmpty()) {
                    addTag(tagsLayout, "BLOOD", bloodType, R.drawable.tag_blood_background, 0xFFE53935.toInt())
                }
                if (settings.showOrganDonor) {
                    addTag(tagsLayout, "DONOR", if (isOrganDonor) "YES" else "NO", R.drawable.tag_donor_background, 0xFFE91E63.toInt())
                }

                // Render Chronic Conditions
                val conditionsCard = profileView.findViewById<View>(R.id.conditionsCard)
                val conditionsContainer = profileView.findViewById<LinearLayout>(R.id.conditionsContainer)
                conditionsContainer.removeAllViews()
                if (settings.showChronicConditions) {
                    conditionsCard.visibility = View.VISIBLE
                    val conditions = if (chronicConditionsStr.isNotEmpty()) {
                        chronicConditionsStr.split(",").map { it.trim() }.filter { it.isNotEmpty() }
                    } else {
                        emptyList()
                    }
                    if (conditions.isNotEmpty()) {
                        for (cond in conditions) {
                            addConditionChip(conditionsContainer, cond)
                        }
                    } else {
                        addConditionChip(conditionsContainer, "None")
                    }
                } else {
                    conditionsCard.visibility = View.GONE
                }

                // Render Allergies
                val allergiesCard = profileView.findViewById<View>(R.id.allergiesCard)
                val allergiesContainer = profileView.findViewById<LinearLayout>(R.id.allergiesContainer)
                allergiesContainer.removeAllViews()
                if (settings.showAllergies) {
                    allergiesCard.visibility = View.VISIBLE
                    val allergyCursor = db.rawQuery("SELECT * FROM allergy WHERE profileId = ?", arrayOf(profileId))
                    if (allergyCursor.moveToFirst()) {
                        do {
                            val allergyName = allergyCursor.getString(allergyCursor.getColumnIndexOrThrow("name"))
                            val note = allergyCursor.getString(allergyCursor.getColumnIndexOrThrow("note")) ?: ""
                            addAllergyRow(allergiesContainer, allergyName, note)
                        } while (allergyCursor.moveToNext())
                    } else {
                        addAllergyRow(allergiesContainer, "None", "")
                    }
                    allergyCursor.close()
                } else {
                    allergiesCard.visibility = View.GONE
                }

                // Render Medications
                val medicationsCard = profileView.findViewById<View>(R.id.medicationsCard)
                val medicationsContainer = profileView.findViewById<LinearLayout>(R.id.medicationsContainer)
                medicationsContainer.removeAllViews()
                if (settings.showMedications) {
                    val medsCursor = db.rawQuery("SELECT * FROM medications WHERE profileId = ? AND isActive = 1", arrayOf(profileId))
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
                if (settings.showContacts) {
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
            val loadedFromCache = loadFromEmergencyCache()
            if (!loadedFromCache) {
                showError("Failed to load emergency data: ${e.localizedMessage}")
            }
        } finally {
            db?.close()
        }
    }

    private fun loadFromEmergencyCache(): Boolean {
        try {
            val dpContext = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                createDeviceProtectedStorageContext()
            } else {
                this
            }
            val prefs = dpContext.getSharedPreferences("emergency_cache", Context.MODE_PRIVATE)
            val isEnabled = prefs.getBoolean("isEnabled", false)
            val title = prefs.getString("title", null)
            val body = prefs.getString("body", null)
            if (isEnabled && !title.isNullOrEmpty() && !body.isNullOrEmpty()) {
                findViewById<View>(R.id.errorContainer).visibility = View.GONE
                findViewById<View>(R.id.scrollContainer).visibility = View.VISIBLE

                val profilesListContainer = findViewById<LinearLayout>(R.id.profilesListContainer)
                profilesListContainer.removeAllViews()

                val profileView = layoutInflater.inflate(R.layout.item_profile_emergency, profilesListContainer, false)
                val cleanTitle = title.replace("🚨 Emergency Medical ID: ", "").replace("🚨 ", "").trim()
                profileView.findViewById<TextView>(R.id.nameText).text = cleanTitle
                profileView.findViewById<TextView>(R.id.dobText).run {
                    visibility = View.VISIBLE
                    text = body
                }
                profileView.findViewById<LinearLayout>(R.id.tagsLayout).visibility = View.GONE
                profileView.findViewById<View>(R.id.conditionsCard).visibility = View.GONE
                profileView.findViewById<View>(R.id.allergiesCard).visibility = View.GONE
                profileView.findViewById<View>(R.id.medicationsCard).visibility = View.GONE
                profileView.findViewById<View>(R.id.contactsCard).visibility = View.GONE
                profileView.findViewById<View>(R.id.profileDivider).visibility = View.GONE

                profilesListContainer.addView(profileView)
                return true
            }
        } catch (ex: Exception) {
            Log.e("EmergencyActivity", "Error loading emergency cache: ${ex.localizedMessage}")
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

    private fun addTag(container: LinearLayout, label: String, value: String, backgroundRes: Int, textColor: Int) {
        val view = layoutInflater.inflate(R.layout.item_emergency_tag, container, false)
        view.setBackgroundResource(backgroundRes)
        view.findViewById<TextView>(R.id.tagLabel).text = label
        view.findViewById<TextView>(R.id.tagValue).run {
            if (label == "DOB" && value.contains(" (Age ")) {
                val spannable = android.text.SpannableStringBuilder(value)
                val ageStart = value.indexOf(" (Age ")
                val ageEnd = value.length
                
                // Make the age portion smaller (e.g. 75% of DOB text size)
                spannable.setSpan(
                    android.text.style.RelativeSizeSpan(0.75f),
                    ageStart,
                    ageEnd,
                    android.text.Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                )
                
                // Make the age portion gray (e.g. #78909C)
                spannable.setSpan(
                    android.text.style.ForegroundColorSpan(0xFF78909C.toInt()),
                    ageStart,
                    ageEnd,
                    android.text.Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                )
                
                // Make the age portion not bold (normal weight)
                spannable.setSpan(
                    android.text.style.StyleSpan(android.graphics.Typeface.NORMAL),
                    ageStart,
                    ageEnd,
                    android.text.Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                )
                
                text = spannable
            } else {
                text = value
            }
            setTextColor(textColor)
            if (value.length > 8) {
                textSize = 12f
            }
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
