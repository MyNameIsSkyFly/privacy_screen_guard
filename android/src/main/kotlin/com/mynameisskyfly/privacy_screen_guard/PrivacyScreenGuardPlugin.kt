package com.mynameisskyfly.privacy_screen_guard

import android.app.Activity
import android.view.WindowManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PrivacyScreenGuardPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var enabled = false
    private var pauseDepth = 0

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "privacy_screen_guard")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "enable" -> {
                enabled = true
                applyState(result)
            }
            "disable" -> {
                enabled = false
                pauseDepth = 0
                applyState(result)
            }
            "pause" -> {
                pauseDepth++
                applyState(result)
            }
            "resume" -> {
                if (pauseDepth > 0) pauseDepth--
                applyState(result)
            }
            "isEnabled" -> result.success(enabled)
            else -> result.notImplemented()
        }
    }

    private fun applyState(result: MethodChannel.Result? = null) {
        val currentActivity = activity
        if (currentActivity == null) {
            result?.error("NO_ACTIVITY", "PrivacyScreenGuard requires a foreground Activity", null)
            return
        }
        currentActivity.runOnUiThread {
            if (enabled && pauseDepth == 0) {
                currentActivity.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            } else {
                currentActivity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
            result?.success(null)
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        applyState()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        applyState()
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
