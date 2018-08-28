//
//  Sequence+UniqueElements.swift
//  VPLastfmTest
//
//  Created by Vitaly Plivachuk on 8/28/18.
//  Copyright © 2018 Vitaly Plivachuk. All rights reserved.
//

import Foundation

public extension Sequence where Iterator.Element: Hashable {
    var uniqueElements: [Iterator.Element] {
        return Array( Set(self) )
    }
}
public extension Sequence where Iterator.Element: Equatable {
    var uniqueElements: [Iterator.Element] {
        return self.reduce([]){
            uniqueElements, element in
            
            uniqueElements.contains(element)
                ? uniqueElements
                : uniqueElements + [element]
        }
    }
}
