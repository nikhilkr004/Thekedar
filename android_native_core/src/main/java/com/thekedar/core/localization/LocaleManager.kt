package com.thekedar.core.localization

import android.content.Context
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import java.util.Locale

object LocaleManager {

    fun applyLocale(langCode: String) {
        val appLocale = LocaleListCompat.forLanguageTags(langCode)
        // AppCompatDelegate.setApplicationLocales handles persisting and applying locale dynamically
        AppCompatDelegate.setApplicationLocales(appLocale)
    }

    fun getCurrentLocale(context: Context): Locale {
        val locales = AppCompatDelegate.getApplicationLocales()
        if (!locales.isEmpty) {
            return locales.get(0) ?: Locale.getDefault()
        }
        return Locale.getDefault()
    }

    fun getSupportedLanguages(): List<LanguageItem> {
        return listOf(
            LanguageItem("en", "English", "🇺🇸"),
            LanguageItem("hi", "हिन्दी", "🇮🇳")
        )
    }
}

data class LanguageItem(
    val code: String,
    val name: String,
    val flag: String
)
