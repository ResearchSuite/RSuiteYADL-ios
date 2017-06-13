//
//  SettingsViewController.swift
//  RSuiteDemo
//
//  Created by Christina Tsangouri on 6/9/17.
//  Copyright © 2017 ResearchSuite. All rights reserved.
//

import UIKit
import ResearchKit
import ResearchSuiteTaskBuilder
import Gloss
import ResearchSuiteAppFramework
import UserNotifications

class YADLSettingsViewController: UIViewController {
    
    let kActivityIdentifiers = "activity_identifiers"
    
    var store: YADLStore!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var spotAssessmentButton: UIButton!
    @IBOutlet weak var fullAssessmentButton: UIButton!
    @IBOutlet weak var notificationButton: UIButton!
    var fullAssessmentItem: RSAFScheduleItem!
    var spotAssessmentItem: RSAFScheduleItem!
    var notificationItem: RSAFScheduleItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.store = YADLStore()
     
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func fullAssessmentAction(_ sender: Any) {
        
        self.launchFullAssessment()

    }
    
    @IBAction func spotAssessmentAction(_ sender: Any) {
        
        self.launchSpotAssessment()
    }
    
    
    
    @IBAction func notificationAction(_ sender: Any) {
        
        self.launchSetNotification()
        
    }
    
    func launchSetNotification() {
        self.notificationItem = AppDelegate.loadScheduleItem(filename: "notification")
        self.launchActivity(forItem: notificationItem)

    }
    
    @IBAction func signoutAction(_ sender: Any) {
       
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.signOut()
    }

    func launchFullAssessment() {
        self.fullAssessmentItem = AppDelegate.loadScheduleItem(filename: "YADLFull")
        self.launchActivity(forItem: fullAssessmentItem)
        
    }
    
    func launchSpotAssessment() {
        self.spotAssessmentItem = AppDelegate.loadScheduleItem(filename: "YADLSpot")
        self.launchActivity(forItem: spotAssessmentItem)
    }
    
    func launchActivity(forItem item: RSAFScheduleItem) {
      
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let steps = appDelegate.taskBuilder.steps(forElement: item.activity as JsonElement) else {
                return
        }
        
        let task = ORKOrderedTask(identifier: item.identifier, steps: steps)
        
        let taskFinishedHandler: ((ORKTaskViewController, ORKTaskViewControllerFinishReason, Error?) -> ()) = { [weak self] (taskViewController, reason, error) in
            //when finised, if task was successful (e.g., wasn't canceled)
            //process results
            if reason == ORKTaskViewControllerFinishReason.completed {
                let taskResult = taskViewController.result
                appDelegate.resultsProcessor.processResult(taskResult: taskResult, resultTransforms: item.resultTransforms)
                
                if(item.identifier == "notification_date"){
                    
                    let result = taskResult.stepResult(forStepIdentifier: "notification_time_picker")
                    let timeAnswer = result?.firstResult as? ORKTimeOfDayQuestionResult
                    
                    let resultAnswer = timeAnswer?.dateComponentsAnswer
                    
                    let userCalendar = Calendar.current // user calendar
                    let someDateTime = userCalendar.date(from: resultAnswer!)
                    
                    let notification = UILocalNotification()
                    notification.fireDate = someDateTime
                    notification.alertBody = "It's time to complete your YADL Spot Assessment!"
                    notification.alertAction = ""
                    notification.soundName = UILocalNotificationDefaultSoundName
                    UIApplication.shared.scheduleLocalNotification(notification)
                    
                    
                    
                }
                

                
                if(item.identifier == "yadl_full"){
                    
                    NSLog("at yadl full")
                    
                    // save date full assessment was completed
                    
                    let date = Date()
                    
                    self?.store.setValueInState(value: date as NSSecureCoding, forKey: "fullDate")

                    
                    // save for spot assessment
                    
                    if let difficultActivities: [String]? = taskResult.results?.flatMap({ (stepResult) in
                        if let stepResult = stepResult as? ORKStepResult,
                            stepResult.identifier.hasPrefix("yadl_full."),
                            let choiceResult = stepResult.firstResult as? ORKChoiceQuestionResult,
                            let answer = choiceResult.choiceAnswers?.first as? String,
                            answer == "hard" || answer == "moderate"
                        {
                            var tempResult = stepResult.identifier
                            let index = tempResult.index(tempResult.startIndex, offsetBy: 10)
                            tempResult = tempResult.substring(from:index)
                            
                            
                            NSLog(tempResult)
                            
                            return tempResult.replacingOccurrences(of: "yadl_full.", with: "")
                            
                        }
                        return nil
                    }) {
                        if let answers = difficultActivities {
                            self?.store.setValueInState(value: answers as NSSecureCoding, forKey: "activity_identifiers")
                            
                            NSLog("answers")
                            NSLog(String(describing:answers))
                            
                            // save when completed full assessment
                           
                            
                        }
                    }
                    
                }
           
            }
            
            self?.dismiss(animated: true, completion: nil)
        }
        
        let tvc = RSAFTaskViewController(
            activityUUID: UUID(),
            task: task,
            taskFinishedHandler: taskFinishedHandler
        )
        
        self.present(tvc, animated: true, completion: nil)
        
    }
    

    
    



}







