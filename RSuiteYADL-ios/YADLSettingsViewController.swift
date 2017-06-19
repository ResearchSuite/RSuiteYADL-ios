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
    
 //   var center: UNUserNotificationCenter!
    var store: YADLStore!
    @IBOutlet weak var backButton: UIBarButtonItem!
    var fullAssessmentItem: RSAFScheduleItem!
    var spotAssessmentItem: RSAFScheduleItem!
    var notificationItem: RSAFScheduleItem!
    var items: [String] = ["Take the Full Assessment", "Take the Spot Assessment", "Set Notification Time", "Sign out"]
    
    @IBOutlet
    var tableView: UITableView!
    
    
    func hourConversion (hour: String, minute: String) -> [String] {
    
        var newHour: String!
        var newMinute: String!
        var am_pm: String!
        
        var minuteInt: Int = Int(minute)!
        if minuteInt < 10 {
            newMinute = "0" + minute
        }
        else {
            newMinute = minute
        }
        
        switch hour{
        case "00":
            newHour = "12"
            am_pm = "am"
        case "12":
            newHour = "12"
            am_pm = "pm"
        case "13":
            newHour = "1"
            am_pm = "pm"
        case "14":
            newHour = "2"
            am_pm = "pm"
        case "15":
            newHour = "3"
            am_pm = "pm"
        case "16":
            newHour = "4"
            am_pm = "pm"
        case "17":
            newHour = "5"
            am_pm = "pm"
        case "18":
            newHour = "6"
            am_pm = "pm"
        case "19":
            newHour = "7"
            am_pm = "pm"
        case "20":
            newHour = "8"
            am_pm = "pm"
        case "21":
            newHour = "9"
            am_pm = "pm"
        case "22":
            newHour = "10"
            am_pm = "pm"
        case "23":
            newHour = "11"
            am_pm = "pm"
        default:
            newHour = hour
            am_pm = "am"
        }
        
    
        return [newHour,am_pm,newMinute]
    
    }

    
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        var deselectedCell = tableView.cellForRow(at: indexPath)!
        deselectedCell.backgroundColor = UIColor.clear
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "cell")!
        
        let notificationHour = self.store.valueInState(forKey: "notificationHour") as! String
        let notificationMinutes = self.store.valueInState(forKey: "notificationMinutes") as! String
        
        var convertedTime:[String]! = []
        
        convertedTime = self.hourConversion(hour: notificationHour,minute: notificationMinutes)
        
        let notificationString = self.items[2] + ":      " + convertedTime[0] + ":" + convertedTime[2] + " " + convertedTime[1]
        
        if(indexPath.row == 2) {
            cell.textLabel?.text = notificationString
        }
        else {
            
            cell.textLabel?.text = self.items[indexPath.row]
        }
        
        cell.textLabel?.textColor = UIColor.init(colorLiteralRed: 0.44, green: 0.66, blue: 0.86, alpha: 1.0)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      
           return 60.0
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NSLog(String(describing: indexPath.row))
        tableView.deselectRow(at: indexPath, animated: true)
        

        
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
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func backButtonAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
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
                    DispatchQueue.main.async{
                        self?.tableView.reloadData()
                    }
                    
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
        
        var fireDate = NSDateComponents()
        
        let hour = resultAnswer.hour
        let minutes = resultAnswer.minute
        
        fireDate.hour = hour!
        fireDate.minute = minutes!
        
        self.store.setValueInState(value: String(describing:hour!) as NSSecureCoding, forKey: "notificationHour")
        self.store.setValueInState(value: String(describing:minutes!) as NSSecureCoding, forKey: "notificationMinutes")
        
        
        if #available(iOS 10.0, *) {
            let content = UNMutableNotificationContent()
            content.title = "YADL"
            content.body = "It'm time to complete your YADL Spot Assessment"
            content.sound = UNNotificationSound.default()
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: fireDate as DateComponents,
                                                        repeats: true)
            
            let identifier = "UYLLocalNotification"
            let request = UNNotificationRequest(identifier: identifier,
                                                content: content, trigger: trigger)
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            appDelegate?.center.add(request, withCompletionHandler: { (error) in
                if let error = error {
                    // Something went wrong
                }
            })
            
        } else {
            // Fallback on earlier versions
            
            let dateToday = Date()
            let day = userCalendar.component(.day, from: dateToday)
            let month = userCalendar.component(.month, from: dateToday)
            let year = userCalendar.component(.year, from: dateToday)
            
            fireDate.day = day
            fireDate.month = month
            fireDate.year = year
            
            let fireDateLocal = userCalendar.date(from:fireDate as DateComponents)
            
            let localNotification = UILocalNotification()
            localNotification.fireDate = fireDateLocal
            localNotification.alertBody = "It'm time to complete your YADL Spot Assessment"
            localNotification.alertTitle = "YADL"
            localNotification.timeZone = TimeZone(abbreviation: "EDT")!
            //set the notification
            UIApplication.shared.scheduleLocalNotification(localNotification)
        }
        
        
    }
    
    

}







