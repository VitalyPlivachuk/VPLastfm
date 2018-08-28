//
//  String+MD5.swift
//  VPLastfm
//
//  Created by Vitaly Plivachuk on 8/28/18.
//  Copyright © 2018 Vitaly Plivachuk. All rights reserved.
//

import Foundation
import CommonCrypto

extension String{
    func getMD5hex() -> String {
        let messageData = self.data(using:.utf8)!
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        let MD5hex = digestData.map{String(format:"%02hhx",$0)}.joined()
        return MD5hex
    }
}
