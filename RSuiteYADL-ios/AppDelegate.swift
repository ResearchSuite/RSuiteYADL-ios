//
//  AppDelegate.swift
//
//  Created by James Kizer on 5/24/17.
//  Copyright © 2017 ResearchSuite. All rights reserved.
//

import UIKit
import OhmageOMHSDK
import ResearchSuiteTaskBuilder
import ResearchSuiteResultsProcessor
import ResearchSuiteAppFramework
import Gloss
import sdlrkx
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    var store: YADLStore!
    var ohmageManager: OhmageOMHManager!
    var taskBuilder: RSTBTaskBuilder!
    var resultsProcessor: RSRPResultsProcessor!
    var center: UNUserNotificationCenter!

    func initializeOhmage(credentialsStore: OhmageOMHSDKCredentialStore) -> OhmageOMHManager {
        
        //load OMH client application credentials from OMHClient.plist
        guard let file = Bundle.main.path(forResource: "OMHClient", ofType: "plist") else {
                fatalError("Could not initialze OhmageManager")
        }
        
        
        let omhClientDetails = NSDictionary(contentsOfFile: file)
        
        guard let baseURL = omhClientDetails?["OMHBaseURL"] as? String,
            let clientID = omhClientDetails?["OMHClientID"] as? String,
            let clientSecret = omhClientDetails?["OMHClientSecret"] as? String else {
                fatalError("Could not initialze OhmageManager")
        }
        
        if let ohmageManager = OhmageOMHManager(baseURL: baseURL,
                                                clientID: clientID,
                                                clientSecret: clientSecret,
                                                queueStorageDirectory: "ohmageSDK",
                                                store: credentialsStore) {
            return ohmageManager
        }
        else {
            fatalError("Could not initialze OhmageManager")
        }
        
    }

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        self.store = YADLStore()
        self.ohmageManager = self.initializeOhmage(credentialsStore: self.store)
        self.store.setValueInState(value: false as NSSecureCoding, forKey: "shouldDoSpot")

        
        self.taskBuilder = RSTBTaskBuilder(
            stateHelper: self.store,
            elementGeneratorServices: AppDelegate.elementGeneratorServices,
            stepGeneratorServices: AppDelegate.stepGeneratorServices,
            answerFormatGeneratorServices: AppDelegate.answerFormatGeneratorServices
        )
        
        self.resultsProcessor = RSRPResultsProcessor(
            frontEndTransformers: AppDelegate.resultsTransformers,
            backEnd: ORBEManager(ohmageManager: self.ohmageManager)
        )
        
        self.showViewController(animated: false)
        
        if #available(iOS 10.0, *) {
            self.center = UNUserNotificationCenter.current()
            self.center.delegate = self
            self.center.requestAuthorization(options: [UNAuthorizationOptions.sound ], completionHandler: { (granted, error) in
                if error == nil{
                   // UIApplication.shared.registerForRemoteNotifications()
                }
            })
        } else {
            let settings  = UIUserNotificationSettings(types: [UIUserNotificationType.alert , UIUserNotificationType.badge , UIUserNotificationType.sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            
        }
        
        return true
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle code here.
        completionHandler([UNNotificationPresentationOptions.sound , UNNotificationPresentationOptions.alert , UNNotificationPresentationOptions.badge])
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        NSLog("this gets called")
        self.store.setValueInState(value: true as NSSecureCoding, forKey: "shouldDoSpot")
        NSLog(String(describing: self.store.valueInState(forKey: "shouldDoSpot")))
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc = storyboard.instantiateInitialViewController()
        self.transition(toRootViewController: vc!, animated: true)
        
        
        completionHandler()
    }
    
    open func signOut() {
        
        self.ohmageManager.signOut { (error) in
            
            self.store.reset()
            DispatchQueue.main.async {
                self.showViewController(animated: true)
            }
            
        }
    }
    
    open func showViewController(animated: Bool) {
        //if not signed in, go to sign in screen
        if !self.ohmageManager.isSignedIn {
            
            let storyboard = UIStoryboard(name: "YADLOnboarding", bundle: Bundle.main)
            let vc = storyboard.instantiateInitialViewController()
            self.transition(toRootViewController: vc!, animated: animated)
            
        }
        else {

            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let vc = storyboard.instantiateInitialViewController()
            self.transition(toRootViewController: vc!, animated: animated)
            
        }
    }
    
    open class var stepGeneratorServices: [RSTBStepGenerator] {
        return [
            CTFOhmageLoginStepGenerator(),
            YADLFullStepGenerator(),
            YADLSpotStepGenerator(),
            CTFDelayDiscountingStepGenerator(),
            CTFBARTStepGenerator(),
            RSTBInstructionStepGenerator(),
            RSTBTextFieldStepGenerator(),
            RSTBIntegerStepGenerator(),
            RSTBDecimalStepGenerator(),
            RSTBTimePickerStepGenerator(),
            RSTBFormStepGenerator(),
            RSTBDatePickerStepGenerator(),
            RSTBSingleChoiceStepGenerator(),
            RSTBMultipleChoiceStepGenerator(),
            RSTBBooleanStepGenerator(),
            RSTBPasscodeStepGenerator(),
            RSTBScaleStepGenerator()
        ]
    }
    
    open class var answerFormatGeneratorServices:  [RSTBAnswerFormatGenerator] {
        return [
            RSTBTextFieldStepGenerator(),
            RSTBSingleChoiceStepGenerator(),
            RSTBIntegerStepGenerator(),
            RSTBDecimalStepGenerator(),
            RSTBTimePickerStepGenerator(),
            RSTBDatePickerStepGenerator(),
            RSTBScaleStepGenerator()
        ]
    }
    
    open class var elementGeneratorServices: [RSTBElementGenerator] {
        return [
            RSTBElementListGenerator(),
            RSTBElementFileGenerator(),
            RSTBElementSelectorGenerator()
        ]
    }
    
    open class var resultsTransformers: [RSRPFrontEndTransformer.Type] {
        return [
            YADLFullRaw.self,
            YADLSpotRaw.self,
            CTFBARTSummaryResultsTransformer.self,
            CTFDelayDiscountingRawResultsTransformer.self
        ]
    }
    
    
    /**
     Convenience method for transitioning to the given view controller as the main window
     rootViewController.
     */
    open func transition(toRootViewController: UIViewController, animated: Bool, completion: ((Bool) -> Swift.Void)? = nil) {
        guard let window = self.window else { return }
        if (animated) {
            let snapshot:UIView = (self.window?.snapshotView(afterScreenUpdates: true))!
            toRootViewController.view.addSubview(snapshot);
            
            self.window?.rootViewController = toRootViewController;
            
            UIView.animate(withDuration: 0.3, animations: {() in
                snapshot.layer.opacity = 0;
            }, completion: {
                (value: Bool) in
                snapshot.removeFromSuperview()
                completion?(value)
            })
        }
        else {
            window.rootViewController = toRootViewController
            completion?(true)
        }
    }
    
    
    //utilities
    static func loadSchedule(filename: String) -> RSAFSchedule? {
        guard let json = AppDelegate.getJson(forFilename: filename) as? JSON else {
            return nil
        }
        
        return RSAFSchedule(json: json)
    }
    
    static func loadScheduleItem(filename: String) -> RSAFScheduleItem? {
        guard let json = AppDelegate.getJson(forFilename: filename) as? JSON else {
            return nil
        }
        
        return RSAFScheduleItem(json: json)
    }
    
    static func loadActivity(filename: String) -> JSON? {
        return AppDelegate.getJson(forFilename: filename) as? JSON
    }
    
    static func getJson(forFilename filename: String, inBundle bundle: Bundle = Bundle.main) -> JsonElement? {
        
        guard let filePath = bundle.path(forResource: filename, ofType: "json")
            else {
                assertionFailure("unable to locate file \(filename)")
                return nil
        }
        
        guard let fileContent = try? Data(contentsOf: URL(fileURLWithPath: filePath))
            else {
                assertionFailure("Unable to create NSData with content of file \(filePath)")
                return nil
        }
        
        let json = try! JSONSerialization.jsonObject(with: fileContent, options: JSONSerialization.ReadingOptions.mutableContainers)
        
        return json as JsonElement?
    }
    
    
    

}

