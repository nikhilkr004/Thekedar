package com.thekedar.core.localization

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.core.app.NotificationCompat
import androidx.lifecycle.lifecycleScope
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.thekedar.core.localization.databinding.ActivityMainBinding
import kotlinx.coroutines.launch
import java.util.Date

class MainActivity : BaseActivity() {

    private lateinit var binding: ActivityMainBinding
    private lateinit var prefManager: PreferenceManager
    private val repository = LanguageRepository()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        prefManager = PreferenceManager(this)

        setupUI()
    }

    private fun setupUI() {
        // Set dynamic date, currency and number formats in text views
        binding.tvDate.text = LocalizationHelper.formatDate(this, Date())
        binding.tvCurrency.text = LocalizationHelper.formatCurrency(this, 125000.50)
        binding.tvNumber.text = LocalizationHelper.formatNumber(this, 9876543)

        // Select English
        binding.btnSelectEnglish.setOnClickListener {
            changeLanguage("en")
        }

        // Select Hindi
        binding.btnSelectHindi.setOnClickListener {
            changeLanguage("hi")
        }

        // Show Dialog
        binding.btnShowDialog.setOnClickListener {
            showSampleDialog()
        }

        // Show BottomSheet
        binding.btnShowBottomSheet.setOnClickListener {
            showSampleBottomSheet()
        }

        // Trigger Notification
        binding.btnTriggerNotification.setOnClickListener {
            triggerSampleNotification()
        }
    }

    private fun changeLanguage(langCode: String) {
        prefManager.setPreferredLanguage(langCode)
        LocaleManager.applyLocale(langCode)
        
        // Sync setting to Firebase in background thread
        lifecycleScope.launch {
            val result = repository.syncLanguageToFirebase(langCode)
            if (result.isSuccess) {
                Toast.makeText(this@MainActivity, getString(R.string.sync_success), Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(this@MainActivity, getString(R.string.sync_failed), Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun showSampleDialog() {
        AlertDialog.Builder(this)
            .setTitle(R.string.dialog_title)
            .setMessage(R.string.dialog_message)
            .setPositiveButton(R.string.ok) { dialog, _ -> dialog.dismiss() }
            .setNegativeButton(R.string.cancel) { dialog, _ -> dialog.dismiss() }
            .show()
    }

    private fun showSampleBottomSheet() {
        val bottomSheet = BottomSheetDialog(this)
        bottomSheet.setContentView(R.layout.bottom_sheet_sample)
        bottomSheet.show()
    }

    private fun triggerSampleNotification() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "thekedar_local_channel"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                getString(R.string.notification_channel_name),
                NotificationManager.IMPORTANCE_DEFAULT
            )
            notificationManager.createNotificationChannel(channel)
        }

        val builder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(getString(R.string.notification_title))
            .setContentText(getString(R.string.notification_body))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)

        notificationManager.notify(1, builder.build())
    }
}
