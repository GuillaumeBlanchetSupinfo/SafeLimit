//
//  AppDelegate.swift
//  SafeLimit
//
//  Created by DotVision DotVision on 22/03/2020.
//  Copyright © 2020 Guillaume Blanchet. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let locationManager = CLLocationManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions:[UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        let options: UNAuthorizationOptions = [.badge, .sound, .alert]
        UNUserNotificationCenter.current()
            .requestAuthorization(options: options) { success, error in
                if let error = error {
                    print("Error: \(error)")
                }
        }
        return true
    }

//    func applicationDidBecomeActive(_ application: UIApplication) {
//        application.applicationIconBadgeNumber = 0
//        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
//        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
//    }

    func handleEvent(for region: CLRegion!) {
        // Show an alert if application is active
    if UIApplication.shared.applicationState == .active {
        guard let message = note(from: region.identifier) else { return }
        window?.rootViewController?.showAlert(withTitle: "Attention", message: message)
    } else {
      // Otherwise present a local notification
        guard let body = note(from: region.identifier) else { return }
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "Attention"
        notificationContent.body = body
        notificationContent.sound = UNNotificationSound.default
        notificationContent.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "location_change",
                                          content: notificationContent,
                                          trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error: \(error)")
            }
        }
    }
  }
  
  func note(from identifier: String) -> String? {
    let geotifications = Geolocation.allGeolocations()
    guard let matched = geotifications.filter({
      $0.identifier == identifier
    }).first else { return nil }
    return matched.note
  }
  
}

extension AppDelegate: CLLocationManagerDelegate {
  
  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    if region is CLCircularRegion {
      handleEvent(for: region)
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    if region is CLCircularRegion {
      handleEvent(for: region)
    }
  }
}
