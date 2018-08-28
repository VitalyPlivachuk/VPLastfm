//
//  Collection+Safe.swift
//  VPLastfmTest
//
//  Created by Vitaly Plivachuk on 8/28/18.
//  Copyright © 2018 Vitaly Plivachuk. All rights reserved.
//

import Foundation

extension Collection{
    public subscript (safe index: Index) -> Element?{
        return indices.contains(index) ? self[index] : nil
    }
}
