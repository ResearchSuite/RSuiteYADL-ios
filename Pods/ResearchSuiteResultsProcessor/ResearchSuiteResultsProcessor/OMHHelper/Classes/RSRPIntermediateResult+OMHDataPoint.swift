//
//  RSRPBackEnd.swift
//  Pods
//
//  Created by James Kizer on 2/10/17.
//
//

import UIKit
import OMHClient

//note that this will be added once extensions are allowed to override

//extension RSRPIntermediateResult: OMHDataPointBuilder {
//    
//    open var creationDateTime: Date {
//        return self.startDate ?? Date()
//    }
//    
//    open var dataPointID: String {
//        return self.uuid.uuidString
//    }
//    
//    open var acquisitionModality: OMHAcquisitionProvenanceModality? {
//        return .Sensed
//    }
//    
//    open var acquisitionSourceCreationDateTime: Date? {
//        return self.startDate
//    }
//    
//    open var acquisitionSourceName: String? {
//        return Bundle.main.infoDictionary![kCFBundleNameKey as String] as? String
//    }
//    
//    open var schema: OMHSchema {
//        fatalError("must override this")
//    }
//    
//    open var body: [String: Any] {
//        
//        fatalError("must override this")
//        return [:]
//        
//    }
//    
//}
