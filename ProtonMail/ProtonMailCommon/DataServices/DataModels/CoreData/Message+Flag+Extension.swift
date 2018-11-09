//
//  Message+Flag+Extension.swift
//  ProtonMail - Created on 11/5/18.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

import Foundation


extension Message {
    
    /// Flags
    struct Flag : OptionSet {
        let rawValue: Int
        
        /// whether a message is received
        static let received    = Flag(rawValue: 1 << 0 ) //const FLAG_RECEIVED = 1; //this it TYPE:INBOXS
        /// whether a message is sent
        static let sent        = Flag(rawValue: 1 << 1 ) //const FLAG_SENT = 2; //this is TYPE:SENT
        /// whether the message is between ProtonMail recipients
        static let `internal`  = Flag(rawValue: 1 << 2 ) //const FLAG_INTERNAL = 4;
        /// whether the message is end-to-end encrypted
        static let e2e         = Flag(rawValue: 1 << 3 ) //const FLAG_E2E = 8;
        
        /// whether the message is an autoresponse
        static let auto        = Flag(rawValue: 1 << 4 ) //const FLAG_AUTO = 16;
        /// whether the message is replied to
        static let replied     = Flag(rawValue: 1 << 5 ) //const FLAG_REPLIED = 32;
        /// whether the message is replied all to
        static let repliedAll  = Flag(rawValue: 1 << 6 ) //const FLAG_REPLIEDALL = 64;
        /// whether the message is forwarded
        static let forwarded   = Flag(rawValue: 1 << 7 ) //const FLAG_FORWARDED = 128;
        
        /// whether the message has been responded to with an autoresponse
        static let autoReplied = Flag(rawValue: 1 << 8 ) //const FLAG_AUTOREPLIED = 256;
        /// whether the message is an import
        static let imported    = Flag(rawValue: 1 << 9 ) //const FLAG_IMPORTED = 512;
        /// whether the message has ever been opened by the user
        static let opened      = Flag(rawValue: 1 << 10) //const FLAG_OPENED = 1024;
        /// whether a read receipt has been sent in response to the message
        static let receiptSent = Flag(rawValue: 1 << 11) //const FLAG_RECEIPT_SENT = 2048;
        
        //static let spam        = Flag(rawValue: 1 << 12) //const FLAG_SPAM = 4096;
        //static let phishing    = Flag(rawValue: 1 << 13) //const FLAG_PHISHING = 8192;
        
        /// Mark -- For drafts only
        /// whether to request a read receipt for the message
        static let receiptRequest  = Flag(rawValue: 1 << 16) //const RECEIPT_REQUEST = 65536
        /// whether to attach the public key
        static let publicKey       = Flag(rawValue: 1 << 17) //const PUBLIC_KEY = 131072
        /// whether to sign the message
        static let sign            = Flag(rawValue: 1 << 18) //const SIGN = 262144
        
        var description : String {
            var out = "Raw: \(rawValue)\n"
            if self.contains(.received) {
                out += "FLAG_RECEIVED = 1\n"
            }
            if self.contains(.sent) {
                out += "FLAG_SENT = 2\n"
            }
            if self.contains(.internal) {
                out += "FLAG_INTERNAL = 4\n"
            }
            if self.contains(.e2e) {
                out += "FLAG_E2E = 8\n"
            }
            
            if self.contains(.auto) {
                out += "FLAG_AUTO = 16\n"
            }
            if self.contains(.replied) {
                out += "FLAG_REPLIED = 32\n"
            }
            if self.contains(.repliedAll) {
                out += "FLAG_REPLIEDALL = 64\n"
            }
            if self.contains(.forwarded) {
                out += "FLAG_FORWARDED = 128\n"
            }
            
            if self.contains(.autoReplied) {
                out += "FLAG_AUTOREPLIED = 256\n"
            }
            if self.contains(.imported) {
                out += "FLAG_IMPORTED = 512\n"
            }
            if self.contains(.opened) {
                out += "FLAG_OPENED = 1024\n"
            }
            if self.contains(.receiptSent) {
                out += "FLAG_RECEIPT_SENT = 2048\n"
            }
//            if self.contains(.spam) {
//                out += "FLAG_SPAM = 4096\n"
//            }
//            if self.contains(.phishing) {
//                out += "FLAG_PHISHING = 8192\n"
//            }
            if self.contains(.receiptRequest) {
                out += "FLAG_RECEIPT_REQUEST = 65536\n"
            }
            if self.contains(.publicKey) {
                out += "FLAG_PUBLIC_KEY = 131072\n"
            }
            if self.contains(.sign) {
                out += "FLAG_SIGN = 262144\n"
            }
            return out
        }
    }
    var flag : Flag {
        get {
            return Flag(rawValue: self.flags.intValue)
        }
        set {
            self.flags = NSNumber(value: newValue.rawValue)
        }
    }
}
