//
//  CloudantSyncClient.swift
//  BluePic
//
//  Created by Rolando Asmat on 11/21/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import Foundation



class CloudantSyncClient {
    /**
     * Instance variables
     */
    var manager:CDTDatastoreManager
    var datastore:CDTDatastore
    var apiKey:String
    var apiPassword:String
    var dbName:String
    var username:String
    var pushDlgt:pushDelegate
    var pullDlgt:pullDelegate
    var pushReplicator:CDTReplicator
    var pullReplicator:CDTReplicator
    
    /**
    * Constructor
    */
    init(apiKey:String, apiPassword:String, dbName:String, username:String) {
        self.apiKey = apiKey
        self.apiPassword = apiPassword
        self.dbName = dbName
        self.username = username
        manager = CDTDatastoreManager()
        datastore = CDTDatastore()
        pushDlgt = pushDelegate()
        pullDlgt = pullDelegate()
        self.pushReplicator = CDTReplicator()
        self.pullReplicator = CDTReplicator()
        do {
            let fileManager = NSFileManager.defaultManager()
            let documentsDir = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
            let storeURL = documentsDir.URLByAppendingPathComponent("cloudant-sync-datastore")
            let path = storeURL.path
            manager = try CDTDatastoreManager(directory: path)
            datastore = try manager.datastoreNamed(dbName)
            //Initialize replicators
            let replicatorFactory = CDTReplicatorFactory(datastoreManager: manager)
            let s = "https://"+apiKey+":"+apiPassword+"@"+username+".cloudant.com/"+dbName
            let remoteDatabaseURL = NSURL(string: s)
            // Push Replicate from the local to remote database
            let pushReplication = CDTPushReplication(source: datastore, target: remoteDatabaseURL)
            self.pushReplicator =  try replicatorFactory.oneWay(pushReplication)
            pushReplicator.delegate = pushDlgt;
            // Pull Replicate from remote database to the local
            let pullReplication = CDTPullReplication(source: remoteDatabaseURL, target: datastore)
            self.pullReplicator =  try replicatorFactory.oneWay(pullReplication)
            pullReplicator.delegate = pullDlgt;
            
        } catch {
            print("Init, ERROR: \(error)")
        }
    }
    
    // Return document with passed ID, if it exists.
    func getDoc(id:String) -> CDTDocumentRevision {
        var retrieved:CDTDocumentRevision = CDTDocumentRevision()
        do {
            retrieved = try datastore.getDocumentWithId(id)
        }
        catch {
            print("getDocumentWithId, ERROR: \(error)")
        }
        return retrieved
    }
    
    // Checks if document with given ID exists or not.
    func doesExist(id:String) -> Bool {
        var count = 1
        while(pullReplicator.isActive())
        {
            NSThread.sleepForTimeInterval(1.0)
            print(count)
            count++
        }
        var exists:Bool
        do {
            try datastore.getDocumentWithId(id)
            exists = true
            print("Document with id "+id+" does exist.")
        }
        catch {
            exists = false
            print("Document with id "+id+" does NOT exist.")
        }
        return exists
    }
    
    // Push changes to remote database
    func pushToRemoteDatabase()
    {
        do {
            //Start the replicator
            try pushReplicator.start()
            
        } catch {
            print("Encountered an error: \(error)")
        }
    }
    
    // Pull changes from remote database
    func pullFromRemoteDatabase()
    {
        do {
            //Start the replicator
            try pullReplicator.start()
            
        } catch {
            print("Encountered an error: \(error)")
        }
    }
    
    // Create a local profile document given an ID and name.
    func createProfileDoc(id:String, name:String) -> CDTDocumentRevision {
        let rev:CDTDocumentRevision = CDTDocumentRevision()
        do {
            // Create a document
            let rev = CDTDocumentRevision(docId: id)
            rev.body = ["profile_name":name, "Type":"profile"]
            // Save the document to the database
            try datastore.createDocumentFromRevision(rev)
        } catch {
            print("createProfileDoc: Encountered an error: \(error)")
        }
        return rev
    }
    
    // Create a local picture document given an display name, file name, URL, owner.
    func createPictureDoc(id:String, displayName:String, fileName:String, url:String, ownerID:String) -> CDTDocumentRevision {
        let rev:CDTDocumentRevision = CDTDocumentRevision()
        do {
            // Create a document
            let rev = CDTDocumentRevision(docId: id)
            rev.body = ["display_name":displayName,
                        "file_name":fileName,
                        "URL":url,
                        "ownerID":ownerID,
                        "Type":"picture"]
            // Save the document to the database
            try datastore.createDocumentFromRevision(rev)
        } catch {
            print("createProfileDoc: Encountered an error: \(error)")
        }
        return rev
    }
}


class pushDelegate:NSObject, CDTReplicatorDelegate {
    /**
     * Called when the replicator changes state.
     */
    func replicatorDidChangeState(replicator:CDTReplicator) {
        print("PUSH Replicator changed state.")
        
    }
    
    /**
     * Called whenever the replicator changes progress
     */
    func replicatorDidChangeProgress(replicator:CDTReplicator) {
        print("PUSH Replicator changed progess.")
    }
    
    /**
     * Called when a state transition to COMPLETE or STOPPED is
     * completed.
     */
    func replicatorDidComplete(replicator:CDTReplicator) {
        print("PUSH Replicator completed.")
    }
    
    /**
     * Called when a state transition to ERROR is completed.
     */
    func replicatorDidError(replicator:CDTReplicator, info:NSError) {
        print("PUSH Replicator ERROR: ")
        print(info)
    }
}

class pullDelegate:NSObject, CDTReplicatorDelegate {
    /**
     * Called when the replicator changes state.
     */
    func replicatorDidChangeState(replicator:CDTReplicator) {
        print("PULL Replicator changed state.")
        
    }
    
    /**
     * Called whenever the replicator changes progress
     */
    func replicatorDidChangeProgress(replicator:CDTReplicator) {
        print("PULL Replicator changed progess.")
    }
    
    /**
     * Called when a state transition to COMPLETE or STOPPED is
     * completed.
     */
    func replicatorDidComplete(replicator:CDTReplicator) {
        print("PULL Replicator completed.")
    }
    
    /**
     * Called when a state transition to ERROR is completed.
     */
    func replicatorDidError(replicator:CDTReplicator, info:NSError) {
        print("PULL Replicator ERROR: ")
        print(info)
    }
}

