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
public class BootCompletedReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) {
            // 这里调度 WorkManager
            WorkManager.getInstance(context).enqueue(new OneTimeWorkRequest.Builder(MyWorker.class).build());
        }
    }
}

import androidx.work.Worker;
import androidx.work.WorkerParameters;

public class MyWorker extends Worker {
    public MyWorker(@NonNull Context context, @NonNull WorkerParameters workerParams) {
        super(context, workerParams);
    }
    public Result doWork() {
        // 启动 NotificationListenerService
        Intent intent = new Intent(applicationContext(), MyNotificationListenerService.class);
        applicationContext().startService(intent);
        return Result.success();
    }
}
*/