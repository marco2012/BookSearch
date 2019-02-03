//
//  Copyright (c) 2016 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import FirebaseCore
import GoogleMaps
import GooglePlaces

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  var shortcutItemToProcess: UIApplicationShortcutItem?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    FirebaseApp.configure()
    
    //maps
    GMSServices.provideAPIKey("AIzaSyBUk8EzISX7cRF05orUf_VSdcfMGPKJs2U")
    GMSPlacesClient.provideAPIKey("AIzaSyBUk8EzISX7cRF05orUf_VSdcfMGPKJs2U")
    
    //quick actions
    // If launchOptions contains the appropriate launch options key, a Home screen quick action
    // is responsible for launching the app. Store the action for processing once the app has
    // completed initialization.
    if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
        shortcutItemToProcess = shortcutItem
    }
    
    return true
  }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        // Alternatively, a shortcut item may be passed in through this delegate method if the app was
        // still in memory when the Home screen quick action was used. Again, store it for processing.
        shortcutItemToProcess = shortcutItem
    }
    
    //manage quick actions
    //https://developer.apple.com/documentation/uikit/peek_and_pop/add_home_screen_quick_actions
    //https://stackoverflow.com/a/46372440/1440037
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Is there a shortcut item that has not yet been processed?
        if let shortcutItem = shortcutItemToProcess {
            
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let vc = storyBoard.instantiateViewController(withIdentifier: "tabBar")
            self.window = UIWindow(frame: UIScreen.main.bounds)
            self.window?.rootViewController = vc
            let myTabBar = self.window?.rootViewController as! UITabBarController
            
            switch shortcutItem.type {
            case "HomeAction":
                myTabBar.selectedIndex = 0
            case "ScanAction":
                myTabBar.selectedIndex = 1
            case "MapAction":
                myTabBar.selectedIndex = 2
            case "UserAction":
                myTabBar.selectedIndex = 3
                default:
                myTabBar.selectedIndex = 0
            }
                        
            self.window?.makeKeyAndVisible()
            
            // Reset the shorcut item so it's never processed twice.
            shortcutItemToProcess = nil
        }
    }

}

