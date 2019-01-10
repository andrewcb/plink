//
//  DocumentFormatMigration.swift
//  Plink
//
//  Created by acb on 10/01/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Foundation

fileprivate struct Migration {
    ///
    enum Error: Swift.Error {
        /// Thrown in the event of a migration failing unrecoverably; i.e., the data being corrupt or similar
        case migrationFailure
        /// Thrown by the migration engine in the event of its input data being fundamentally corrupt; i.e., not being a property list with a document version number or similar
        case dataError
    }
    
    // The version at which this change kicks in
    let version: Int
    // A function to mutate the data object (in the form of a [String:Any] dictionary
    let migrate: ((inout [String:Any]) throws ->())
}

fileprivate let migrations: [Migration] = [
    Migration(version: 0x000100010000, migrate: { ( dict: inout [String:Any]) in
        dict["metronome"] = dict["transport"]
        dict["transport"] = nil
    })
]

/**
 Given file data containing a well-formed data file of a potentially older version, return file data containing the data in the current version of the file format. This will be the same data as was given if no migrations need to be applied.
 */
func migratedData(from oldData: Data, toVersion targetVersion: Int) throws -> Data {
    guard
        var dict = (try? PropertyListSerialization.propertyList(from: oldData, options: [], format: nil)).flatMap({ $0 as? [String:Any] }),
        let inputVersion = dict["documentVersion"] as? Int
    else { throw Migration.Error.dataError }

    let migrationsToApply = migrations.filter { $0.version <= targetVersion && $0.version > inputVersion }
    if migrationsToApply.isEmpty { return oldData }
    for migration in migrationsToApply {
        try migration.migrate(&dict)
    }
    return try PropertyListSerialization.data(fromPropertyList: dict, format: PropertyListSerialization.PropertyListFormat.binary, options: 0)
    
}
