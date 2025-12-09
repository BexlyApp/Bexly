package com.joy.bexly

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * NotificationListenerService that enables the app to appear in system's
 * "Notification access" settings. The actual notification handling is done
 * by the notification_listener_service Flutter package.
 *
 * This service is required for the app to be listed in the system's
 * notification access permissions screen.
 */
class NotificationListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        // Notification handling is done by the Flutter plugin
        // This service just enables the permission to be granted
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // Not needed for our use case
    }
}
