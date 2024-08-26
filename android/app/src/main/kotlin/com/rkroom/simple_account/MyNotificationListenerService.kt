package com.rkroom.simple_account

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.content.Context
import android.content.ComponentName
import androidx.core.app.NotificationManagerCompat
import android.app.Notification
import io.flutter.plugin.common.MethodChannel

class MyNotificationListenerService : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        super.onNotificationPosted(sbn)

        val notification = sbn.notification
        if (notification != null) {
            val title = notification.extras.getString(Notification.EXTRA_TITLE)
            val content = notification.extras.getString(Notification.EXTRA_TEXT)
            val packageName = sbn.packageName
            val postTime = sbn.postTime

            handleNotification(title, content, packageName, postTime)
        }
    }

    private fun handleNotification(title: String?, content: String?, packageName: String?,postTime: Long?) {
        // 通过 MethodChannel 发送数据到 Flutter
        channel?.invokeMethod("onNotificationPosted", mapOf(
            "title" to title,
            "content" to content,
            "packageName" to packageName,
            "postTime" to postTime,
        ))
    }

    /* 
    override fun onCreate() {
        super.onCreate()
    }

    override fun onDestroy() {
        super.onDestroy()
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
    }
    */
    
    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        //当监听断开时，触发rebind
        val componentName = ComponentName(this, MyNotificationListenerService::class.java)
        requestRebind(componentName)
    }

    companion object {
        var channel: MethodChannel? = null

        const val PERMISSION_REQUEST_CODE = 1

        fun isNotificationListenerEnabled(context: Context): Boolean {
            val packageName = context.packageName
            val enabledPackages = NotificationManagerCompat.getEnabledListenerPackages(context)
            return enabledPackages.contains(packageName)
        }
    }
}