//
//  OnboardingViewController.swift
//
//  Created by Christina Tsangouri on 6/8/17.
//  Copyright © 2017 ResearchSuite. All rights reserved.
//

import UIKit
import ResearchKit
import ResearchSuiteTaskBuilder
import Gloss
import ResearchSuiteAppFramework
import UserNotifications

class YADLOnboardingViewController: UIViewController {
    
    let kActivityIdentifiers = "activity_identifiers"
    
    var store: YADLStore!
    
    let delegate = UIApplication.shared.delegate as! AppDelegate
    @IBOutlet weak var loginButton: UIButton!
    var notifItem: RSAFScheduleItem!
    var signInItem: RSAFScheduleItem!
    var fullAssessmentItem: RSAFScheduleItem!
    var spotAssessmentItem: RSAFScheduleItem!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let color = UIColor.init(colorLiteralRed: 0.44, green: 0.66, blue: 0.86, alpha: 1.0)
        loginButton.layer.borderWidth = 1.0
        loginButton.layer.borderColor = color.cgColor
        loginButton.layer.cornerRadius = 5
        loginButton.clipsToBounds = true

    }

    
    @IBAction func signInTapped(_ sender: Any) {
        

        guard let signInActivity = AppDelegate.loadActivity(filename: "signIn"),
        let appDelegate = UIApplication.shared.delegate as? AppDelegate,
        let steps = appDelegate.taskBuilder.steps(forElement: signInActivity as JsonElement) else {
            return
        }
        
        let task = ORKOrderedTask(identifier: "signIn", steps: steps)
        
        let taskFinishedHandler: ((ORKTaskViewController, ORKTaskViewControllerFinishReason, Error?) -> ()) = { [weak self] (taskViewController, reason, error) in
            
            //when done, tell the app delegate to go back to the correct screen
            self?.dismiss(animated: true, completion: {
                self!.notifItem = AppDelegate.loadScheduleItem(filename: "notification")
                self?.launchActivity(forItem: (self?.notifItem)!)
                
            })
            
        }
        
        let tvc = RSAFTaskViewController(
            activityUUID: UUID(),
            task: task,
            taskFinishedHandler: taskFinishedHandler
        )
        
        self.present(tvc, animated: true, completion: nil)
        

    }
    
    
    func launchActivity(forItem item: RSAFScheduleItem) {
        
        self.store = YADLStore()
        
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
                    self?.setNotification(resultAnswer: resultAnswer!)
                    
                }
                
                if(item.identifier == "yadl_full"){
                    
                    // save date that full assessment was completed
                    
                    let date = Date()
                                    
                    self?.store.setValueInState(value: date as NSSecureCoding, forKey: "dateFull")
                
                    
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
            
            self?.dismiss(animated: true, completion: {
                
                if(item.identifier == "notification_date"){
                    self!.fullAssessmentItem = AppDelegate.loadScheduleItem(filename:"YADLFull")
                    self?.launchActivity(forItem: (self?.fullAssessmentItem)!)

                }
                
                if(item.identifier == "yadl_full"){
                    self!.spotAssessmentItem = AppDelegate.loadScheduleItem(filename:"YADLSpot")
                    self?.launchActivity(forItem: (self?.spotAssessmentItem)!)
                }
                
                if(item.identifier == "yadl_spot"){
                    let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                    let vc = storyboard.instantiateInitialViewController()
                    appDelegate.transition(toRootViewController: vc!, animated: true)
                }
                
            })
            
            
        
            
        }
        
        let tvc = RSAFTaskViewController(
            activityUUID: UUID(),
            task: task,
            taskFinishedHandler: taskFinishedHandler
        )
        
        self.present(tvc, animated: true, completion: nil)
        
    }
    
    func setNotification(resultAnswer: DateComponents) {
        
        var userCalendar = Calendar.current
        userCalendar.timeZone = TimeZone(abbreviation: "EDT")!
        let someDateTime = userCalendar.date(from: resultAnswer)
        var dateToday = Date()
        var fireDate = NSDateComponents()
        let day = userCalendar.component(.day, from: dateToday)
        let month = userCalendar.component(.month, from: dateToday)
        let year = userCalendar.component(.year, from: dateToday)
        let hour = resultAnswer.hour
        let minutes = resultAnswer.minute
        
        NSLog(String(describing: hour))
        NSLog(String(describing: minutes))
        
        fireDate.hour = hour!
        fireDate.minute = minutes!
        fireDate.day = day
        fireDate.month = month
        fireDate.year = year
        
        let dateFire = userCalendar.date(from:fireDate as DateComponents)
        
        NSLog(String(describing: dateFire))
        
        let content = UNMutableNotificationContent()
        content.title = "YADL"
        content.body = "It'm time to complete your YADL Spot Assessment"
        content.sound = UNNotificationSound.default()
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: fireDate as DateComponents,
                                                    repeats: false)
        
        let identifier = "UYLLocalNotification"
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content, trigger: trigger)
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.center.add(request, withCompletionHandler: { (error) in
            if let error = error {
                // Something went wrong
            }
        })
        
        
    }

}
    

        

       
        





  


