//
//  NotificationClient.swift
//  intention
//
//  Created by Benjamin Tryon on 12/5/25.
//

import Foundation
import UserNotifications

//@MainActor
protocol NotificationClient {
    /// Schedule a one-shot local notification at `fireDate`.
    func schedule(id: String, title: String, body: String, fireDate: Date) async
    /// Cancel a pending or delivered notification by id.
    func cancel(id: String) async
}

struct NoopNotificationClient: NotificationClient {
    func schedule(id: String, title: String, body: String, fireDate: Date) async {}
    func cancel(id: String) async {}
}

final class LiveNotificationClient: NotificationClient {
    func schedule(id: String, title: String, body: String, fireDate: Date) async {
        let center = UNUserNotificationCenter.current()
        // Request auth if not yet determined (silent if already granted/denied)
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])

        // Remove any stale one with the same id
        await cancel(id: id)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let interval = max(1, Int(fireDate.timeIntervalSinceNow.rounded()))
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(interval), repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancel(id: String) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.removeDeliveredNotifications(withIdentifiers: [id])
    }
}
