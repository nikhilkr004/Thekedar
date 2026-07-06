package com.thekedar.core.localization

import android.content.Context
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object LocalizationHelper {

    fun formatDate(context: Context, date: Date, pattern: String = "dd MMM yyyy"): String {
        val locale = LocaleManager.getCurrentLocale(context)
        val sdf = SimpleDateFormat(pattern, locale)
        return sdf.format(date)
    }

    fun formatTime(context: Context, date: Date, pattern: String = "hh:mm a"): String {
        val locale = LocaleManager.getCurrentLocale(context)
        val sdf = SimpleDateFormat(pattern, locale)
        return sdf.format(date)
    }

    fun formatNumber(context: Context, number: Number): String {
        val locale = LocaleManager.getCurrentLocale(context)
        val formatter = NumberFormat.getInstance(locale)
        return formatter.format(number)
    }

    fun formatCurrency(context: Context, amount: Double, currencyCode: String = "INR"): String {
        val locale = LocaleManager.getCurrentLocale(context)
        val formatter = NumberFormat.getCurrencyInstance(locale)
        try {
            formatter.currency = java.util.Currency.getInstance(currencyCode)
        } catch (e: Exception) {
            // Fallback if code invalid
        }
        return formatter.format(amount)
    }
}
