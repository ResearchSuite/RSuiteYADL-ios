//
//  RSAFTaskViewController.swift
//  Pods
//
//  Created by James Kizer on 3/22/17.
//
//

import UIKit
import ResearchKit

open class RSAFTaskViewController: ORKTaskViewController, ORKTaskViewControllerDelegate {
    
    var taskFinishedHandler: ((ORKTaskViewController, ORKTaskViewControllerFinishReason, Error?) -> ())
    
    let activityUUID: UUID

    
    public init(activityUUID: UUID, task: ORKTask, taskFinishedHandler: @escaping ((ORKTaskViewController, ORKTaskViewControllerFinishReason, Error?) -> ())) {
        
        self.activityUUID = activityUUID
        self.taskFinishedHandler = taskFinishedHandler
        super.init(task: task, taskRun: nil)
        self.delegate = self
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        
        self.taskFinishedHandler(taskViewController, reason, error)
       // taskViewController.dismiss(animated: true, completion: nil)
        
        
    }
    
    public func taskViewController(_ taskViewController: ORKTaskViewController, stepViewControllerWillAppear stepViewController: ORKStepViewController) {
        stepViewController.cancelButtonItem = nil
    }

}
