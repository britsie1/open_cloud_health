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
import org.json.JSONArray
import org.json.JSONObject
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
        // 1. First priority: Structured JSON cache in Device Protected Storage
        if (loadFromEmergencyJsonCache()) {
            return
        }

        // 2. Fallback: Direct SQLite query (if database is unencrypted)
        if (loadFromDatabase()) {
            return
        }

        // 3. Fallback: Legacy emergency text cache
        if (loadFromLegacyEmergencyCache()) {
            return
        }

        showError("No profiles or medical data set up yet.\nConfigure Emergency Medical ID under Settings.")
    }

    private fun loadFromEmergencyJsonCache(): Boolean {
        try {
            val dpContext = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                createDeviceProtectedStorageContext()
            } else {
                this
            }
            val prefs = dpContext.getSharedPreferences("emergency_cache", Context.MODE_PRIVATE)
            val isEnabled = prefs.getBoolean("isEnabled", false)
            val dataJson = prefs.getString("data_json", null)
            
            if (!isEnabled || dataJson.isNullOrEmpty()) {
                return false
            }

            val jsonArray = JSONArray(dataJson)
            if (jsonArray.length() == 0) {
                return false
            }

            val profiles = mutableListOf<EmergencyProfileData>()
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                
                val conditionsList = mutableListOf<String>()
                val condArray = obj.optJSONArray("chronicConditions")
                if (condArray != null) {
                    for (c in 0 until condArray.length()) {
                        conditionsList.add(condArray.getString(c))
                    }
                }

                val allergiesList = mutableListOf<Pair<String, String>>()
                val algArray = obj.optJSONArray("allergies")
                if (algArray != null) {
                    for (a in 0 until algArray.length()) {
                        val aObj = algArray.getJSONObject(a)
                        allergiesList.add(Pair(aObj.optString("name", ""), aObj.optString("note", "")))
                    }
                }

                val medsList = mutableListOf<Pair<String, String>>()
                val medArray = obj.optJSONArray("medications")
                if (medArray != null) {
                    for (m in 0 until medArray.length()) {
                        val mObj = medArray.getJSONObject(m)
                        medsList.add(Pair(mObj.optString("name", ""), mObj.optString("dosage", "")))
                    }
                }

                val contactsList = mutableListOf<Triple<String, String, String>>()
                val conArray = obj.optJSONArray("contacts")
                if (conArray != null) {
                    for (ct in 0 until conArray.length()) {
                        val ctObj = conArray.getJSONObject(ct)
                        contactsList.add(Triple(
                            ctObj.optString("name", ""),
                            ctObj.optString("relationship", ""),
                            ctObj.optString("phoneNumber", ctObj.optString("phone", ""))
                        ))
                    }
                }

                var insurance: InsuranceData? = null
                val insObj = obj.optJSONObject("insurance")
                if (insObj != null && insObj.optString("provider", "").isNotEmpty()) {
                    insurance = InsuranceData(
                        provider = insObj.optString("provider", ""),
                        planName = insObj.optString("planName", ""),
                        policyNumber = insObj.optString("policyNumber", ""),
                        groupNumber = insObj.optString("groupNumber", ""),
                        subscriberName = insObj.optString("subscriberName", ""),
                        emergencyPhone = insObj.optString("emergencyPhone", "")
                    )
                }

                profiles.add(
                    EmergencyProfileData(
                        profileId = obj.optString("profileId", ""),
                        name = obj.optString("name", "Medical Information"),
                        fullName = obj.optString("fullName", obj.optString("name", "")),
                        dobFormatted = obj.optString("dobFormatted", obj.optString("dob", "")),
                        age = obj.optInt("age", 0),
                        bloodType = obj.optString("bloodType", ""),
                        isOrganDonor = obj.optBoolean("isOrganDonor", false),
                        chronicConditions = conditionsList,
                        allergies = allergiesList,
                        medications = medsList,
                        contacts = contactsList,
                        insurance = insurance,
                        showName = obj.optBoolean("showName", true),
                        showAge = obj.optBoolean("showAge", true),
                        showBloodType = obj.optBoolean("showBloodType", true),
                        showOrganDonor = obj.optBoolean("showOrganDonor", true),
                        showChronicConditions = obj.optBoolean("showChronicConditions", true),
                        showAllergies = obj.optBoolean("showAllergies", true),
                        showMedications = obj.optBoolean("showMedications", true),
                        showContacts = obj.optBoolean("showContacts", true),
                        showInsurance = obj.optBoolean("showInsurance", true)
                    )
                )
            }

            if (profiles.isNotEmpty()) {
                renderProfiles(profiles)
                return true
            }
        } catch (e: Exception) {
            Log.e("EmergencyActivity", "Error loading JSON emergency cache: ${e.localizedMessage}")
        }
        return false
    }

    private fun loadFromDatabase(): Boolean {
        val dbFile = getDatabasePath("opencloudhealth.db")
        if (!dbFile.exists()) {
            return false
        }

        var db: SQLiteDatabase? = null
        try {
            db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READONLY)
            
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
                val showInsuranceCol = settingsCursor.getColumnIndex("showInsurance")

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
                            showContacts = settingsCursor.getInt(showContactsCol) == 1,
                            showInsurance = if (showInsuranceCol != -1) settingsCursor.getInt(showInsuranceCol) == 1 else true
                        )
                    )
                } while (settingsCursor.moveToNext())
            }
            settingsCursor.close()

            if (settingsList.isEmpty()) {
                return false
            }

            var primaryProfileId: String? = null
            try {
                val primaryCursor = db.rawQuery("SELECT value FROM settings WHERE key = 'primary_profile_id' LIMIT 1", null)
                if (primaryCursor.moveToFirst()) {
                    primaryProfileId = primaryCursor.getString(0)
                }
                primaryCursor.close()
            } catch (e: Exception) {}

            if (primaryProfileId != null) {
                val primaryIndex = settingsList.indexOfFirst { it.profileId == primaryProfileId }
                if (primaryIndex != -1) {
                    val primarySettings = settingsList.removeAt(primaryIndex)
                    settingsList.add(0, primarySettings)
                }
            }

            val profiles = mutableListOf<EmergencyProfileData>()
            for (settings in settingsList) {
                val profileId = settings.profileId

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

                val fullName = "$name $middleNames $surname".replace("\\s+".toRegex(), " ").trim()
                val dobFormatted = formatDob(dateOfBirthEpoch)
                val age = calculateAge(dateOfBirthEpoch)

                val conditionsList = if (chronicConditionsStr.isNotEmpty()) {
                    chronicConditionsStr.split(",").map { it.trim() }.filter { it.isNotEmpty() }
                } else {
                    emptyList()
                }

                val allergiesList = mutableListOf<Pair<String, String>>()
                try {
                    val allergyCursor = db.rawQuery("SELECT * FROM allergy WHERE profileId = ?", arrayOf(profileId))
                    if (allergyCursor.moveToFirst()) {
                        do {
                            val aName = allergyCursor.getString(allergyCursor.getColumnIndexOrThrow("name"))
                            val note = allergyCursor.getString(allergyCursor.getColumnIndexOrThrow("note")) ?: ""
                            allergiesList.add(Pair(aName, note))
                        } while (allergyCursor.moveToNext())
                    }
                    allergyCursor.close()
                } catch (e: Exception) {}

                val medsList = mutableListOf<Pair<String, String>>()
                try {
                    val medsCursor = db.rawQuery("SELECT * FROM medications WHERE profileId = ? AND isActive = 1", arrayOf(profileId))
                    if (medsCursor.moveToFirst()) {
                        do {
                            val mName = medsCursor.getString(medsCursor.getColumnIndexOrThrow("name"))
                            val dosage = medsCursor.getString(medsCursor.getColumnIndexOrThrow("dosage")) ?: ""
                            medsList.add(Pair(mName, dosage))
                        } while (medsCursor.moveToNext())
                    }
                    medsCursor.close()
                } catch (e: Exception) {}

                val contactsList = mutableListOf<Triple<String, String, String>>()
                try {
                    val contactsCursor = db.rawQuery("SELECT * FROM emergency_contacts WHERE profileId = ?", arrayOf(profileId))
                    if (contactsCursor.moveToFirst()) {
                        do {
                            val cName = contactsCursor.getString(contactsCursor.getColumnIndexOrThrow("name"))
                            val rel = contactsCursor.getString(contactsCursor.getColumnIndexOrThrow("relationship"))
                            val phone = contactsCursor.getString(contactsCursor.getColumnIndexOrThrow("phoneNumber"))
                            contactsList.add(Triple(cName, rel, phone))
                        } while (contactsCursor.moveToNext())
                    }
                    contactsCursor.close()
                } catch (e: Exception) {}

                var insurance: InsuranceData? = null
                try {
                    val insCursor = db.rawQuery("SELECT * FROM insurance WHERE profileId = ? LIMIT 1", arrayOf(profileId))
                    if (insCursor.moveToFirst()) {
                        insurance = InsuranceData(
                            provider = insCursor.getString(insCursor.getColumnIndexOrThrow("provider")),
                            planName = insCursor.getString(insCursor.getColumnIndexOrThrow("planName")) ?: "",
                            policyNumber = insCursor.getString(insCursor.getColumnIndexOrThrow("policyNumber")),
                            groupNumber = insCursor.getString(insCursor.getColumnIndexOrThrow("groupNumber")) ?: "",
                            subscriberName = insCursor.getString(insCursor.getColumnIndexOrThrow("subscriberName")) ?: "",
                            emergencyPhone = insCursor.getString(insCursor.getColumnIndexOrThrow("emergencyPhone")) ?: ""
                        )
                    }
                    insCursor.close()
                } catch (e: Exception) {}

                profiles.add(
                    EmergencyProfileData(
                        profileId = profileId,
                        name = if (settings.showName) fullName else "Medical Information",
                        fullName = fullName,
                        dobFormatted = dobFormatted,
                        age = age,
                        bloodType = bloodType,
                        isOrganDonor = isOrganDonor,
                        chronicConditions = conditionsList,
                        allergies = allergiesList,
                        medications = medsList,
                        contacts = contactsList,
                        insurance = insurance,
                        showName = settings.showName,
                        showAge = settings.showAge,
                        showBloodType = settings.showBloodType,
                        showOrganDonor = settings.showOrganDonor,
                        showChronicConditions = settings.showChronicConditions,
                        showAllergies = settings.showAllergies,
                        showMedications = settings.showMedications,
                        showContacts = settings.showContacts,
                        showInsurance = settings.showInsurance
                    )
                )
            }

            if (profiles.isNotEmpty()) {
                renderProfiles(profiles)
                return true
            }
        } catch (e: Exception) {
            Log.e("EmergencyActivity", "Direct SQLite read failed (database may be encrypted): ${e.localizedMessage}")
        } finally {
            db?.close()
        }
        return false
    }

    private fun loadFromLegacyEmergencyCache(): Boolean {
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
                profileView.findViewById<View>(R.id.insuranceCard).visibility = View.GONE
                profileView.findViewById<View>(R.id.profileDivider).visibility = View.GONE

                profilesListContainer.addView(profileView)
                return true
            }
        } catch (ex: Exception) {
            Log.e("EmergencyActivity", "Error loading legacy emergency cache: ${ex.localizedMessage}")
        }
        return false
    }

    private fun renderProfiles(profiles: List<EmergencyProfileData>) {
        findViewById<View>(R.id.errorContainer).visibility = View.GONE
        findViewById<View>(R.id.scrollContainer).visibility = View.VISIBLE

        val profilesListContainer = findViewById<LinearLayout>(R.id.profilesListContainer)
        profilesListContainer.removeAllViews()

        for (i in 0 until profiles.size) {
            val p = profiles[i]
            val profileView = layoutInflater.inflate(R.layout.item_profile_emergency, profilesListContainer, false)

            // 1. Profile Header Row with Image, Name, and DOB
            val profileImageView = profileView.findViewById<ImageView>(R.id.profileImage)
            loadCircularProfileImage(this, p.profileId, profileImageView)

            val nameTextView = profileView.findViewById<TextView>(R.id.nameText)
            nameTextView.text = if (p.showName) p.fullName else "Medical Information"
            nameTextView.visibility = View.VISIBLE

            val dobTextView = profileView.findViewById<TextView>(R.id.dobText)
            if (p.showAge && p.dobFormatted.isNotEmpty()) {
                dobTextView.text = "Date of Birth: ${p.dobFormatted}"
                dobTextView.visibility = View.VISIBLE
            } else {
                dobTextView.visibility = View.GONE
            }

            // 2. The 3 Metric Blocks (Age, Blood Type, Organ Donor)
            val tagsLayout = profileView.findViewById<LinearLayout>(R.id.tagsLayout)
            tagsLayout.removeAllViews()

            if (p.showAge && p.age > 0) {
                addTag(tagsLayout, "AGE", "${p.age} yrs", R.drawable.tag_age_background, 0xFF9C27B0.toInt())
            }
            if (p.showBloodType && p.bloodType.isNotEmpty()) {
                addTag(tagsLayout, "BLOOD TYPE", p.bloodType, R.drawable.tag_blood_background, 0xFFE53935.toInt())
            }
            if (p.showOrganDonor) {
                addTag(tagsLayout, "ORGAN DONOR", if (p.isOrganDonor) "YES" else "NO", R.drawable.tag_donor_background, 0xFFE91E63.toInt())
            }

            // 3. Chronic Conditions Card
            val conditionsCard = profileView.findViewById<View>(R.id.conditionsCard)
            val conditionsContainer = profileView.findViewById<LinearLayout>(R.id.conditionsContainer)
            conditionsContainer.removeAllViews()
            if (p.showChronicConditions) {
                conditionsCard.visibility = View.VISIBLE
                if (p.chronicConditions.isNotEmpty()) {
                    for (cond in p.chronicConditions) {
                        addConditionChip(conditionsContainer, cond)
                    }
                } else {
                    addConditionChip(conditionsContainer, "None")
                }
            } else {
                conditionsCard.visibility = View.GONE
            }

            // 4. Allergies & Reaction Notes Card
            val allergiesCard = profileView.findViewById<View>(R.id.allergiesCard)
            val allergiesContainer = profileView.findViewById<LinearLayout>(R.id.allergiesContainer)
            allergiesContainer.removeAllViews()
            if (p.showAllergies) {
                allergiesCard.visibility = View.VISIBLE
                if (p.allergies.isNotEmpty()) {
                    for (alg in p.allergies) {
                        addAllergyRow(allergiesContainer, alg.first, alg.second)
                    }
                } else {
                    addAllergyRow(allergiesContainer, "None", "")
                }
            } else {
                allergiesCard.visibility = View.GONE
            }

            // 5. Active Medications Card
            val medicationsCard = profileView.findViewById<View>(R.id.medicationsCard)
            val medicationsContainer = profileView.findViewById<LinearLayout>(R.id.medicationsContainer)
            medicationsContainer.removeAllViews()
            if (p.showMedications) {
                if (p.medications.isNotEmpty()) {
                    medicationsCard.visibility = View.VISIBLE
                    for (med in p.medications) {
                        addMedicationRow(medicationsContainer, med.first, med.second)
                    }
                } else {
                    medicationsCard.visibility = View.GONE
                }
            } else {
                medicationsCard.visibility = View.GONE
            }

            // 6. In Case of Emergency (ICE) Contacts Card
            val contactsCard = profileView.findViewById<View>(R.id.contactsCard)
            val contactsContainer = profileView.findViewById<LinearLayout>(R.id.contactsContainer)
            contactsContainer.removeAllViews()
            if (p.showContacts) {
                if (p.contacts.isNotEmpty()) {
                    contactsCard.visibility = View.VISIBLE
                    for (contact in p.contacts) {
                        addContactRow(contactsContainer, contact.first, contact.second, contact.third)
                    }
                } else {
                    contactsCard.visibility = View.GONE
                }
            } else {
                contactsCard.visibility = View.GONE
            }

            // 7. Health Insurance / Medical Aid Card
            val insuranceCard = profileView.findViewById<View>(R.id.insuranceCard)
            val insuranceContainer = profileView.findViewById<LinearLayout>(R.id.insuranceContainer)
            insuranceContainer.removeAllViews()
            if (p.showInsurance && p.insurance != null) {
                insuranceCard.visibility = View.VISIBLE
                addInsuranceRow(
                    insuranceContainer,
                    p.insurance.provider,
                    p.insurance.planName,
                    p.insurance.policyNumber,
                    p.insurance.groupNumber,
                    p.insurance.subscriberName,
                    p.insurance.emergencyPhone
                )
            } else {
                insuranceCard.visibility = View.GONE
            }

            // Hide Divider for the last item
            if (i == profiles.size - 1) {
                profileView.findViewById<View>(R.id.profileDivider).visibility = View.GONE
            }

            profilesListContainer.addView(profileView)
        }
    }

    private data class EmergencyProfileData(
        val profileId: String,
        val name: String,
        val fullName: String,
        val dobFormatted: String,
        val age: Int,
        val bloodType: String,
        val isOrganDonor: Boolean,
        val chronicConditions: List<String>,
        val allergies: List<Pair<String, String>>,
        val medications: List<Pair<String, String>>,
        val contacts: List<Triple<String, String, String>>,
        val insurance: InsuranceData?,
        val showName: Boolean,
        val showAge: Boolean,
        val showBloodType: Boolean,
        val showOrganDonor: Boolean,
        val showChronicConditions: Boolean,
        val showAllergies: Boolean,
        val showMedications: Boolean,
        val showContacts: Boolean,
        val showInsurance: Boolean
    )

    private data class InsuranceData(
        val provider: String,
        val planName: String,
        val policyNumber: String,
        val groupNumber: String,
        val subscriberName: String,
        val emergencyPhone: String
    )

    private data class LockScreenConfig(
        val profileId: String,
        val showName: Boolean,
        val showAge: Boolean,
        val showBloodType: Boolean,
        val showOrganDonor: Boolean,
        val showChronicConditions: Boolean,
        val showAllergies: Boolean,
        val showMedications: Boolean,
        val showContacts: Boolean,
        val showInsurance: Boolean
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
            text = value
            setTextColor(textColor)
            if (value.length > 8) {
                textSize = 13f
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

    private fun addInsuranceRow(
        container: LinearLayout,
        provider: String,
        plan: String,
        policy: String,
        group: String,
        subscriber: String,
        emergencyPhone: String
    ) {
        val view = layoutInflater.inflate(R.layout.item_insurance, container, false)
        view.findViewById<TextView>(R.id.insuranceProvider).text = provider
        
        view.findViewById<TextView>(R.id.insurancePlan).run {
            if (plan.isNotEmpty()) {
                text = "Plan: $plan"
                visibility = View.VISIBLE
            } else {
                visibility = View.GONE
            }
        }
        
        val policyText = StringBuilder("Policy / Member ID: $policy")
        if (group.isNotEmpty()) {
            policyText.append(" • Group: $group")
        }
        view.findViewById<TextView>(R.id.insurancePolicy).text = policyText.toString()
        
        view.findViewById<TextView>(R.id.insuranceSubscriber).run {
            if (subscriber.isNotEmpty()) {
                text = "Subscriber: $subscriber"
                visibility = View.VISIBLE
            } else {
                visibility = View.GONE
            }
        }
        
        val emergencyRow = view.findViewById<View>(R.id.insuranceEmergencyRow)
        if (emergencyPhone.isNotEmpty()) {
            emergencyRow.visibility = View.VISIBLE
            view.findViewById<TextView>(R.id.insuranceEmergencyPhone).text = emergencyPhone
            emergencyRow.setOnClickListener {
                try {
                    val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$emergencyPhone"))
                    startActivity(intent)
                } catch (e: Exception) {
                    // Ignore
                }
            }
        } else {
            emergencyRow.visibility = View.GONE
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

