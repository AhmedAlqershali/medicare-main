package com.example.medicare

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.provider.Settings
import android.util.Random
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MedicareMessagingService : FirebaseMessagingService() {
    override fun onCreate() {
        super.onCreate()
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Medicare notifications",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Notifications for Medicare patients and doctors."
                enableVibration(true)
                lightColor = Color.GREEN
                setShowBadge(true)
            }
            manager.createNotificationChannel(channel)
        }
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        val title = remoteMessage.notification?.title ?: remoteMessage.data["title"]
        val body = remoteMessage.notification?.body ?: remoteMessage.data["body"]
        if (title.isNullOrBlank() && body.isNullOrBlank()) return

        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("notification_message", remoteMessage.data)
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            Random.nextInt(0xFFFF),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = android.app.Notification.Builder(
            this,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) NOTIFICATION_CHANNEL_ID else "default",
        )
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setSound(Settings.System.DEFAULT_NOTIFICATION_URI)
            .build()

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, notification)
    }

    companion object {
        const val NOTIFICATION_CHANNEL_ID = "medicare_notifications"
        private const val NOTIFICATION_ID = 1
    }
}
