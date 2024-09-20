//
//  RefDataModel.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-02.
//

import Foundation

import Foundation
import SwiftUI
import GoogleSignIn
import GoogleAPIClientForREST

@Observable class RefDataVM  {
    
//
// This function loads the main reference data from the ReferenceData sheet.
// 1) Call Google Drive to search for for the Tutor's timesheet file name in order to get the file's Google File ID
// 2) If only a single file is retreived, call loadStudentServices to retrieve the Tutor's assigned Student list, Services list and Notes options as well as the Tutor service history for the month
//
  
    
   
    func loadReferenceData(referenceData: ReferenceData)  {
        var referenceFileID: String
        var tutorDataFileID: String

        if runMode == "PROD" {
            referenceFileID = PgmConstants.prodReferenceDataFileID
            tutorDataFileID = PgmConstants.prodTutorDataFileID
            
        } else {
            referenceFileID = PgmConstants.testReferenceDataFileID
            tutorDataFileID = PgmConstants.testTutorDataFileID
        }
        
        referenceData.dataCounts.loadDataCounts(referenceFileID: referenceFileID, tutorDataFileID: tutorDataFileID, referenceData: referenceData)
        if referenceData.dataCounts.isDataCountsLoaded {
 
        }
        
    }
    


    
}
