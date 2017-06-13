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

class YADLSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let kActivityIdentifiers = "activity_identifiers"
    
    var center: UNUserNotificationCenter!
    var store: YADLStore!
    var fullAssessmentItem: RSAFScheduleItem!
    var spotAssessmentItem: RSAFScheduleItem!
    var notificationItem: RSAFScheduleItem!
    var items: [String] = ["Take the Full Assessment", "Take the Spot Assessment", "Set Notification Time", "Sign out"]
    
    @IBOutlet
    var tableView: UITableView!
    
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "cell")!
        
        cell.textLabel?.text = self.items[indexPath.row]
        cell.textLabel?.textColor = UIColor.init(colorLiteralRed: 0.44, green: 0.66, blue: 0.86, alpha: 1.0)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NSLog(String(describing: indexPath.row))
        
        if indexPath.row == 0 {
            NSLog("full")
            self.launchFullAssessment()
        }
        
        if indexPath.row == 1 {
            self.launchSpotAssessment()
        }
        
        if indexPath.row == 2 {
            self.launchSetNotification()
        }
        
        if indexPath.row == 3 {
            self.signOut()
        }

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.store = YADLStore()
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
//        self.center = UNUserNotificationCenter.current()
//
//        center.requestAuthorization(options: options) {
//            (granted, error) in
//            if !granted {
//                print("Something went wrong")
//            }
//        }
     
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func signOut () {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.signOut()
    }
    
    func launchSetNotification() {
        self.notificationItem = AppDelegate.loadScheduleItem(filename: "notification")
        self.launchActivity(forItem: notificationItem)

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
                    self?.setNotification(resultAnswer: resultAnswer!)
                    
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
    
    func setNotification(resultAnswer: DateComponents) {
        
        var userCalendar = Calendar.current
        userCalendar.timeZone = TimeZone(abbreviation: "EDT")!
        let someDateTime = userCalendar.date(from: resultAnswer)
       // let easternDateTime = userCalendar.date(byAdding: .hour, value: -5, to: someDateTime!)
        
//        NSLog(String(describing:easternDateTime!))
        
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







