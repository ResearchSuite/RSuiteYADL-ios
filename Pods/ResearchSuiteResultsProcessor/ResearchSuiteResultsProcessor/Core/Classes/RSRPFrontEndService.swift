//
//  RSRPFrontEndService.swift
//  Pods
//
//  Created by James Kizer on 2/10/17.
//
//

import UIKit
import ResearchKit

class RSRPFrontEndService: NSObject {
    
    let transformers: [RSRPFrontEndTransformer.Type]
    
    public init(frontEndTransformers: [RSRPFrontEndTransformer.Type]) {
        self.transformers = frontEndTransformers
    }
    
    open func processResult(taskResult: ORKTaskResult, resultTransforms: [RSRPResultTransform]) -> [RSRPIntermediateResult] {
        
        let intermediateResults = resultTransforms.flatMap { (resultTransform) -> RSRPIntermediateResult? in
            
            var parameters: [String: AnyObject] = [:]
            resultTransform.inputMapping.forEach({ (inputMapping) in
                
                switch inputMapping.mappingType {
                case .stepIdentifier:
                    if let stepIdentifier = inputMapping.value as? String,
                        let result = taskResult.stepResult(forStepIdentifier: stepIdentifier) {
                        parameters[inputMapping.parameter] = result
                    }
                
                case .constant:
                    parameters[inputMapping.parameter] = inputMapping.value
                    
                case .stepIdentifierRegex:
                    if let regex = inputMapping.value as? String,
                        let stepResults = taskResult.results as? [ORKStepResult] {
                        let matchingStepResults: [ORKStepResult] = stepResults.filter({ (result) -> Bool in
                            let identifier: String = result.identifier
                            return identifier.range(of: regex, options: String.CompareOptions.regularExpression, range: nil, locale: nil) != nil
                        })
                        parameters[inputMapping.parameter] = matchingStepResults as AnyObject
                    }
                
                default:
                    break
                }
                
            })
            
            return self.transformResult(
                type: resultTransform.transform,
                taskIdentifier: taskResult.identifier,
                taskRunUUID: taskResult.taskRunUUID,
                parameters: parameters
            )
        }
        
        
        return intermediateResults
        
    }
    
    
    fileprivate func transformResult(
        type: String,
        taskIdentifier: String,
        taskRunUUID: UUID,
        parameters: [String: AnyObject]
    ) -> RSRPIntermediateResult? {
        
        for transformer in self.transformers {
            if transformer.supportsType(type: type),
                let intermediateResult = transformer.transform(taskIdentifier: taskIdentifier, taskRunUUID: taskRunUUID, parameters: parameters) {
                return intermediateResult
            }
        }
        
        return nil
        
    }

}
