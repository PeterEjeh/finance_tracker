package com.example.finance_tracker

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.example.finance_tracker/email_link"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Handle the intent when the app is launched from an email link
        intent?.let { handleIntent(it) }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val data: Uri? = intent.data
        if (data != null && data.toString().contains("finishSignUp")) {
            // Extract email from the URL
            val email = data.getQueryParameter("email")
            val link = data.toString()

            if (email != null && link != null) {
                // Send the email link data to Flutter
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, CHANNEL).invokeMethod("handleEmailLink", mapOf(
                        "email" to email,
                        "link" to link
                    ))
                }
            }
        }
    }
}
