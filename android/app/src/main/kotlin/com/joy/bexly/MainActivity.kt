package com.joy.bexly

import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.joy.bexly/device_location"

    // Fix crash bug in notification_listener_service plugin:
    // When user navigates back from Notification Access settings, the plugin
    // calls reply() twice causing IllegalStateException crash.
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        try {
            super.onActivityResult(requestCode, resultCode, data)
        } catch (e: IllegalStateException) {
            // Suppress "Reply already submitted" from notification_listener_service plugin
        }
    }


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSimCountryCode" -> {
                    val countryCode = getSimCountryCode()
                    result.success(countryCode)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getSimCountryCode(): String? {
        return try {
            val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

            // Try to get country from SIM card
            val simCountry = telephonyManager.simCountryIso
            if (!simCountry.isNullOrEmpty()) {
                return simCountry.uppercase()
            }

            // Fallback: Try to get country from network
            val networkCountry = telephonyManager.networkCountryIso
            if (!networkCountry.isNullOrEmpty()) {
                return networkCountry.uppercase()
            }

            null
        } catch (e: Exception) {
            // No SIM card or permission denied - return null
            null
        }
    }
}
