//
//  CodeValueConvertible.swift
//  Plink
//
//  Created by acb on 2019-07-21.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Foundation

/// A protocol guaranteeing that its type can be converted to internal types by any CodeLanguageEngine. The details of the conversion are left to the engine implementation
protocol CodeValueConvertible {}

///MARK: instances for CodeValueConvertible
extension Int: CodeValueConvertible {}

