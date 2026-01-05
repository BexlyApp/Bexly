package com.joy.bexly

import android.content.Context
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.joy.bexly/device_location"

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
