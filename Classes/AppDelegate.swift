//
//  AppDelegate.swift
//  facile
//
//  Created by Renaud Pradenc on 25/10/2018.
//

import Foundation
import UIKit
import FirebaseCore
import FirebaseCrashlytics

let HostName = "www.incwo.com"
let BaseUrl = "https://www.incwo.com"

class AppDelegate: NSObject, UIApplicationDelegate {
    @IBOutlet var window: UIWindow?
    
    let businessFilesList = BusinessFilesList()
    
    lazy var sidePanelController = SidePanelController(businessFilesList: businessFilesList)
    
    lazy var officeCoordinator: OfficeCoordinator = {
        let officeRouter = OfficeCoordinator()
        officeRouter.navigationController.tabBarItem = UITabBarItem(title: "Bureau", image: UIImage(named: "FCLTabBarOffice"), selectedImage: UIImage(named: "FCLTabBarOfficeSelected"))
        return officeRouter
    } ()
    
    lazy var scanCoordinator: ScanCoordinator = {
        let scanRouter = ScanCoordinator()
        scanRouter.navigationController.tabBarItem = UITabBarItem(title: "Scan", image: UIImage(named: "FCLTabBarScan"), selectedImage: UIImage(named: "FCLTabBarScanSelected"))
        return scanRouter
    } ()
    
    lazy var videosViewController: FCLVideosViewController = {
        let controller = FCLVideosViewController.catalog()
        controller!.tabBarItem = UITabBarItem(title: "Vidéos", image: UIImage(named: "FCLTabBarVideos"), selectedImage: UIImage(named: "FCLTabBarVideosSelected"))
        return controller!
    } ()
    
    lazy var newsViewController: FCLNewsViewController = {
        let controller = UIStoryboard(name: "News", bundle: nil).instantiateInitialViewController() as! FCLNewsViewController
        controller.tabBarItem = UITabBarItem(title: "Actualités", image: UIImage(named: "FCLTabBarNews"), selectedImage: UIImage(named: "FCLTabBarNewsSelected"))
        return controller
    } ()
    
    lazy var tabBarController: UITabBarController = {
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [
            officeCoordinator.navigationController,
            scanCoordinator.navigationController,
            UINavigationController(rootViewController: videosViewController),
            UINavigationController(rootViewController: newsViewController)
        ]
        tabBarController.view.backgroundColor = Appearance.tabBarControllerBackgroundColor()
        return tabBarController
    } ()
    
    var appCoordinator: AppCoordinator!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {        

        FirebaseApp.configure() // Enables Crashlytics, notably
        // Because we don't want to make our API key public, the GoogleService-Info.plist file is not commited
        // in our git repo. You will need to generate you own in Firebase (or remove all Firebase dependencies).
        
        FCLUploader.shared()?.start()
        Appearance.setup()

        appCoordinator = AppCoordinator(rootViewController: self.tabBarController, businessFilesList: businessFilesList, sidePanelController: sidePanelController, officeCoordinator: officeCoordinator, scanCoordinator: scanCoordinator)
        
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
