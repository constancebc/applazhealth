//
//  NotificationClient.swift
//  Mustage
//
//  Created by Oleg Baidalka on 09/03/2018.
//  Copyright © 2018 Bossly. All rights reserved.
//

import UIKit
import UserNotifications
import FirebaseMessaging
import FirebaseAuth
import FirebaseDatabase

protocol NotificationClient {
    func setupNotification()
}

// register Push Notification
extension NotificationClient {

    func setupNotification() {
        let application = UIApplication.shared
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound],
                completionHandler: {_,_ in })
            
            // For iOS 10 display notification (sent via APNS)
            if let appDelegate = application.delegate as? AppDelegate {
                UNUserNotificationCenter.current().delegate = appDelegate
            }
        } else {
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
    }
}

// handle Push Notification
extension AppDelegate {
    
    func messageReceived(_ userInfo: [AnyHashable: Any]) {
        // Print message ID.
        //print("Message ID: \(userInfo["gcm.message_id"]!)")
        
        // Print full message.

        
        guard
            let type = userInfo["type"] as? String,
            let id = userInfo["id"] as? String else { return }
        guard let recipient = userInfo["recipientID"] as? String,
              recipient == Auth.auth().currentUser?.uid else { return }
        ApplazActivityInbox.shared.start()
        switch type {
        case "notebookInvite", "notebookAccepted":
            navigateTo(NotificationViewController())
        case "story":
            let storyboard = UIStoryboard(name: "Story", bundle: Bundle.main)
            
            if let controller = storyboard.instantiateInitialViewController() as? FeedViewController {
                controller.singleStoryId = id
                navigateTo(controller)
            }

        case "comment":
            let storyboard = UIStoryboard(name: "Story", bundle: Bundle.main)
            
            if let controller = storyboard.instantiateViewController(withIdentifier: "comments") as? CommentsTableViewController {
                controller.storyId = id
                navigateTo(controller)
            }
            
        default:
            return
        }
    }
    
    func navigateTo(_ controller: UIViewController) {
        // wait when application is opened
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let rootController = self.window?.rootViewController as? UINavigationController
            let tabController = rootController?.viewControllers.last as? UITabBarController
            let navigation = tabController?.selectedViewController as? UINavigationController
            navigation?.pushViewController(controller, animated: true)
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        
        // Save the token to UserDefaults
        UserDefaults.standard.set(tokenString, forKey: "deviceToken")
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let recipient = userInfo["recipientID"] as? String,
              recipient == Auth.auth().currentUser?.uid else { completionHandler(.noData); return }
        ApplazActivityInbox.shared.start()
        completionHandler(.newData)
    }

}

@available(iOS 10, *)
extension AppDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        messageReceived(response.notification.request.content.userInfo)
        completionHandler()
    }
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        guard let recipient = userInfo["recipientID"] as? String, recipient == Auth.auth().currentUser?.uid else { completionHandler([]); return }
        ApplazActivityInbox.shared.start()
        completionHandler([.alert, .badge, .sound])
    }
}
