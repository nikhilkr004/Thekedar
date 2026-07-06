package com.thekedar.core.localization

import android.content.Context
import android.content.SharedPreferences

class PreferenceManager(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences(
        PREFS_NAME,
        Context.MODE_PRIVATE
    )

    companion object {
        private const val PREFS_NAME = "thekedar_localization_prefs"
        private const val KEY_PREFERRED_LANGUAGE = "preferred_language"
        private const val KEY_HAS_SELECTED_LANG = "has_selected_language"
    }

    fun getPreferredLanguage(): String {
        return prefs.getString(KEY_PREFERRED_LANGUAGE, "en") ?: "en"
    }

    fun setPreferredLanguage(langCode: String) {
        prefs.edit().apply {
            putString(KEY_PREFERRED_LANGUAGE, langCode)
            putBoolean(KEY_HAS_SELECTED_LANG, true)
            apply()
        }
    }

    fun hasSelectedLanguage(): Boolean {
        return prefs.getBoolean(KEY_HAS_SELECTED_LANG, false)
    }

    fun clear() {
        prefs.edit().clear().apply()
    }
}
