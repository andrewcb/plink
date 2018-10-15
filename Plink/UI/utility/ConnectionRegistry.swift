//
//  ConnectionRegistry.swift
//  Plink
//
//  Created by acb on 15/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation

/** A class implementing a registry for removable connections such as callbacks */
struct ConnectionRegistry<T> {
    typealias Id = Int
    
    private var _connections: [Id:T] = [:]
    private var nextId: Int = 0
    
    mutating func add(connection: T) -> Id {
        let id = self.nextId
        self.nextId += 1
        self._connections[id] = connection
        return id
    }
    
    /** The connections to iterate through */
    var connections: AnySequence<T> { return AnySequence<T>(self._connections.values.lazy) }
    
    mutating func removeConnection(withId id: Int) {
        self._connections.removeValue(forKey: id)
    }
}
