//
//  AppDelegate.swift
//  BLEPeriferal
//
//  Created by Tomas Radvansky on 20/10/2015.
//  Copyright © 2015 Radvansky Solutions. All rights reserved.
//

import UIKit
import CoreBluetooth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,BLEPeriferalServerDelegate {

    var window: UIWindow?

    var peripheral:BLEPeriferalServer?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        peripheral = BLEPeriferalServer(withDelegate: self)
        peripheral?.serviceName = "Test"
        peripheral?.serviceUUID = CBUUID(string: "7e56")
        peripheral?.characteristicUUID = CBUUID(string: "b72e")
        peripheral?.startAdvertising()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quit
        self.peripheral?.applicationDidEnterBackground()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        self.peripheral?.applicationWillEnterForeground()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func periferalServer(periferal: BLEPeriferalServer, centralDidSubscribe: CBCentral) {
        self.peripheral?.sendToSubscribers("Hello".dataUsingEncoding(NSUTF8StringEncoding)!)
    }

    func periferalServer(periferal: BLEPeriferalServer, centralDidUnsubscribe: CBCentral) {
    }
}

