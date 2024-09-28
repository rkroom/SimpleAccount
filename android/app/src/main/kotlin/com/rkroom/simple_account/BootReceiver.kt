package com.rkroom.simple_account

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            if (MyNotificationListenerService.isNotificationListenerEnabled(context)) {
                val serviceIntent = Intent(context, MyNotificationListenerService::class.java)
                context.startService(serviceIntent)
            }
        }
    }
}

/*
import androidx.work.Worker;
import androidx.work.WorkerParameters;
import androidx.work.WorkManager
import androidx.work.OneTimeWorkRequest

class BootCompletedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (Intent.ACTION_BOOT_COMPLETED == intent.action) {
            // 这里调度 WorkManager
            WorkManager.getInstance(context)
                .enqueue(OneTimeWorkRequest.Builder(MyWorker::class.java).build())
        }
    }
}

class MyWorker(context: Context, workerParams: WorkerParameters) : Worker(context, workerParams) {
    override fun doWork(): Result {
        // 启动 NotificationListenerService
        val intent = Intent(applicationContext, MyNotificationListenerService::class.java)
        applicationContext.startService(intent)
        return Result.success()
    }
}
 */