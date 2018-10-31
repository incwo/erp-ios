//
//  AppDelegate.swift
//  facile
//
//  Created by Renaud Pradenc on 25/10/2018.
//

import Foundation
import UIKit
import Fabric
import Crashlytics

let HostName = "www.incwo.com"
let BaseUrl = "https://www.incwo.com"

class AppDelegate: NSObject, UIApplicationDelegate {
    @IBOutlet var window: UIWindow?
    
    let businessFilesList = BusinessFilesList()
    
    lazy var sidePanelController = SidePanelController(businessFilesList: businessFilesList)
    
    lazy var officeRouter: OfficeRouter = {
        let officeRouter = OfficeRouter()
        officeRouter.navigationController.tabBarItem = UITabBarItem(title: "Bureau", image: UIImage(named: "FCLTabBarOffice"), selectedImage: UIImage(named: "FCLTabBarOfficeSelected"))
        return officeRouter
    } ()
    
    lazy var scanRouter: ScanRouter = {
        let scanRouter = ScanRouter()
        scanRouter.navigationController.tabBarItem = UITabBarItem(title: "Scan", image: UIImage(named: "FCLTabBarScan"), selectedImage: UIImage(named: "FCLTabBarScanSelected"))
        return scanRouter
    } ()
    
    lazy var videosViewController: FCLVideosViewController = {
        let controller = FCLVideosViewController.catalog()
        controller!.tabBarItem = UITabBarItem(title: "Vidéos", image: UIImage(named: "FCLTabBarVideos"), selectedImage: UIImage(named: "FCLTabBarVideosSelected"))
        return controller!
    } ()
    
    lazy var newsViewController: FCLNewsViewController = {
        let controller = FCLNewsViewController(nibName: nil, bundle: nil)
        controller.tabBarItem = UITabBarItem(title: "Actualités", image: UIImage(named: "FCLTabBarNews"), selectedImage: UIImage(named: "FCLTabBarNewsSelected"))
        return controller
    } ()
    
    lazy var tabBarController: UITabBarController = {
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [
            officeRouter.navigationController,
            scanRouter.navigationController,
            UINavigationController(rootViewController: videosViewController),
            UINavigationController(rootViewController: newsViewController)
        ]
        tabBarController.view.backgroundColor = UIColor.white
        return tabBarController
    } ()
    
    var appRouter: AppRouter!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        PHTTPConnection.setSSLTrustedHosts(["www.incwo.com", "dev.incwo.com"])
        
        // WebView causes memory leaks without this configuration.
        // See http://discussions.apple.com/thread.jspa?threadID=1785052
        // Also without this NSURLConnection caches everything
        URLCache.shared.memoryCapacity = 0
        
        FCLUploader.shared()?.start()
        FCLAppearance.setup()
        
        // Fabric insists that its framework must be the last one initalized, since it catches exceptions.
        if let fabricDic = Bundle.main.object(forInfoDictionaryKey: "Fabric") as? [String: Any],
            fabricDic["APIKey"] != nil {
            // Only init if the key is set in info.plist.
            // The key is set at build time using a script.
            // We did not open-source our key, for good reasons!
            Fabric.with([Crashlytics.self()])
        }

        appRouter = AppRouter(rootViewController: self.tabBarController, businessFilesList: businessFilesList, sidePanelController: sidePanelController, officeRouter: officeRouter, scanRouter: scanRouter)
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = tabBarController
        window!.makeKeyAndVisible()
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        FCLUploader.shared()?.stop()
    }
    
    deinit {
        FCLUploader.releaseSharedUploader()
    }
}
