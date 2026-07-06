package com.thekedar.core.localization

import android.content.Context
import android.content.res.Configuration
import androidx.appcompat.app.AppCompatActivity

abstract class BaseActivity : AppCompatActivity() {

    override fun attachBaseContext(newBase: Context) {
        val prefs = PreferenceManager(newBase)
        val langCode = prefs.getPreferredLanguage()
        val locale = java.util.Locale(langCode)
        java.util.Locale.setDefault(locale)
        
        val config = Configuration(newBase.resources.configuration)
        config.setLocale(locale)
        val context = newBase.createConfigurationContext(config)
        
        super.attachBaseContext(context)
    }
}
