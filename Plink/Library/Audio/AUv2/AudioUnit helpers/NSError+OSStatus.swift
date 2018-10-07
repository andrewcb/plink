//
//  NSError+OSStatus.swift
//  Plink
//
//  Created by acb on 07/12/2017.
//  Copyright © 2017 acb. All rights reserved.
//

import Foundation

extension NSError {
    convenience init(osstatus: OSStatus) {
        self.init(domain: NSOSStatusErrorDomain, code: Int(osstatus), userInfo: nil)
    }
}
