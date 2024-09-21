package com.rkroom.simple_account

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.content.Context
import android.content.ComponentName
import androidx.core.app.NotificationManagerCompat
import android.app.Notification
import io.flutter.plugin.common.MethodChannel

import android.content.SharedPreferences

import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class MyNotificationListenerService : NotificationListenerService() {

    private val sharedPreferencesManager by lazy {
        SharedPreferencesManager.getInstance(this)
    }

    private val allowPackageName = listOf(
        "com.eg.android.AlipayGphone",
        "com.tencent.mm",
    ) 
    private val allowKeywords = listOf("交易", "支付", )
    private val regExp = Regex("(\\d+\\.\\d{2})")


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

    private fun saveNotificationData(title: String?, content: String?, packageName: String?, postTime: Long?) {
        val notificationData = NotificationData(
            title = title,
            content = content,
            packageName = packageName,
            postTime = postTime
        )
        
        // 使用 Kotlinx.serialization 序列化为 JSON 字符串
        val jsonString = Json.encodeToString(notificationData)
    
        sharedPreferencesManager.addBill(jsonString)

        //发送账单，以便在打开bill_listener页面时也能及时添加新的账单
        //在需要的情况下
        //可以调用MisAppRunning检查应用的运行情况
        //同时设置一个标志位（isSendNotification）,在进入bill_listener时修改其状态，退出时还原状态
        //在两者同时满足的情况下才发送账单
        channel?.invokeMethod("onNotificationPosted", mapOf(
            "title" to title,
            "content" to content,
            "packageName" to packageName,
            "postTime" to postTime,
        ))
    }

    private fun handleNotification(title: String?, content: String?, packageName: String?,postTime: Long?) {

        // 检查 packageName 是否在允许的列表中
        if (!allowPackageName.contains(packageName)) {
            return
        }

        // 检查 title 中是否包含允许的关键字
        if (!allowKeywords.any { title?.contains(it, ignoreCase = true) == true }) {
            return
        }
        
        if (regExp.find(content ?: "") == null) {
            return
        }

        saveNotificationData(title, content, packageName, postTime)
        
    }

    //检测APP是否运行中
    /*
    private fun isAppRunning(): Boolean {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val runningProcesses = activityManager.runningAppProcesses
        runningProcesses?.forEach { processInfo ->
            if (processInfo.processName == packageName) {
                return true
            }
        }
        return false
    }
    */

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

        //var isSendNotification: Boolean = false

        fun isNotificationListenerEnabled(context: Context): Boolean {
            val packageName = context.packageName
            val enabledPackages = NotificationManagerCompat.getEnabledListenerPackages(context)
            return enabledPackages.contains(packageName)
        }

        fun flutterPrint(message:Any?){
            channel?.invokeMethod("flutterPrint",message.toString())
        }
    }
}


class SharedPreferencesManager private constructor(context: Context) {

    companion object {
        private const val PREFERENCES_NAME = "BillPreferences"
        private const val BILLS_KEY = "bills"
        
        @Volatile
        private var instance: SharedPreferencesManager? = null

        fun getInstance(context: Context): SharedPreferencesManager =
            instance ?: synchronized(this) {
                instance ?: SharedPreferencesManager(context).also { instance = it }
            }
    }

    private val sharedPreferences: SharedPreferences = context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
    // 添加账单，返回添加的索引 (相当于Hive的add操作)
    fun addBill(bill: String): Int {
        val bills = getBills().toMutableList() // 获取当前所有账单
        bills.add(bill) // 添加新账单
        saveBills(bills) // 保存到SharedPreferences
        return bills.size - 1 // 返回新账单的索引
    }

    // 删除指定索引的账单 (相当于Hive的deleteAt操作)
    fun delBill(index: Int) {
        val bills = getBills().toMutableList()
        if (index >= 0 && index < bills.size) {
            bills.removeAt(index) // 删除指定索引的账单
            saveBills(bills) // 保存修改后的账单列表
        }
    }

    // 获取所有账单 (相当于Hive的values操作)
    fun getBills(): List<String> {
        val billsJson = sharedPreferences.getString(BILLS_KEY, null)
        return if (billsJson != null) {
            // 反序列化JSON字符串为List
            Json.decodeFromString(billsJson)
        } else {
            emptyList() // 如果没有账单，则返回空列表
        }
    }

    // 清空所有账单 (相当于Hive的clear操作)
    fun clearBills(): Int {
        val editor = sharedPreferences.edit()
        val count = getBills().size // 获取当前账单的数量，用于返回
        editor.remove(BILLS_KEY) // 清空存储的账单
        editor.apply() // 提交更改
        return count // 返回清空的数量
    }

    // 私有方法，用于保存账单列表
    private fun saveBills(bills: List<String>) {
        // 将List序列化为JSON字符串
        val billsJson = Json.encodeToString(bills)
        sharedPreferences.edit().putString(BILLS_KEY, billsJson).apply()
    }
}

@Serializable
data class NotificationData(
    val title: String?,
    val content: String?,
    val packageName: String?,
    val postTime: Long?
)