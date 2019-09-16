//
//  AuthAPITests.swift
//  ProtonMail - Created on 09/12/19.
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


import UIKit
import XCTest
import Crypto
@testable import ProtonMail

class CryptoTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func TestAttachmentGetKey() {
        
        let privateKey =
"""
-----BEGIN PGP PRIVATE KEY BLOCK-----
Version: OpenPGP.js v0.7.1
Comment: http://openpgpjs.org

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
qqGRQm3MxoTdgQUShAwbNwNNQR9cInfMnA==
=2wIY
-----END PGP PRIVATE KEY BLOCK-----

"""
        var keyPacket = "wcBMA0fcZ7XLgmf2AQgAiRsOlnm1kSB4/lr7tYe6pBsRGn10GqwUhrwU5PMKOHdCgnO12jO3y3CzP0Yl/jGhAYja9wLDqH8X0sk3tY32u4Sb1Qe5IuzggAiCa4dwOJj5gEFMTHMzjIMPHR7A70XqUxMhmILye8V4KRm/j4c1sxbzA1rM3lYBumQuB5l/ck0Kgt4ZqxHVXHK5Q1l65FHhSXRj8qnunasHa30TYNzP8nmBA8BinnJxpiQ7FGc2umnUhgkFtjm5ixu9vyjr9ukwDTbwAXXfmY+o7tK7kqIXJcmTL6k2UeC6Mz1AagQtRCRtU+bv/3zGojq/trZo9lom3naIeQYa36Ketmcpj2Qwjg=="
         
        let pgp = CryptoGetGopenPGP()!
        let keyPacketData: Data = keyPacket.decodeBase64()
        
        
        
        
//
//        symmetricKey, err := testPrivateKeyRing.DecryptSessionKey(testKeyPacketsDecoded)
//        if err != nil {
//            t.Fatal("Expected no error while decrypting KeyPacket, got:", err)
//        }
//
//        assert.Exactly(t, testSymmetricKey, symmetricKey)
    }

    
//    ///Mark -- attachment part
//    func TestAttachmentDecrypt(t *testing.T) {
//        var testAttachmentCleartext = "cc,\ndille."
//        var message = NewPlainMessage([]byte(testAttachmentCleartext))
//
//        encrypted, err := testPrivateKeyRing.Encrypt(message, nil)
//        if err != nil {
//            t.Fatal("Expected no error while encrypting attachment, got:", err)
//        }
//
//        armored, err := encrypted.GetArmored()
//        if err != nil {
//            t.Fatal("Expected no error while armoring, got:", err)
//        }
//
//        pgpSplitMessage, err := NewPGPSplitMessageFromArmored(armored)
//        if err != nil {
//            t.Fatal("Expected no error while unarmoring, got:", err)
//        }
//
//        redecData, err := testPrivateKeyRing.DecryptAttachment(pgpSplitMessage)
//        if err != nil {
//            t.Fatal("Expected no error while decrypting attachment, got:", err)
//        }
//
//        assert.Exactly(t, message, redecData)
//    }
    
//    func TestAttachmentGetKey() {
//        testKeyPacketsDecoded, err := base64.StdEncoding.DecodeString(readTestFile("attachment_keypacket", false))
//        if err != nil {
//            t.Fatal("Expected no error while decoding base64 KeyPacket, got:", err)
//        }
//
//        symmetricKey, err := testPrivateKeyRing.DecryptSessionKey(testKeyPacketsDecoded)
//        if err != nil {
//            t.Fatal("Expected no error while decrypting KeyPacket, got:", err)
//        }
//
//        assert.Exactly(t, testSymmetricKey, symmetricKey)
//    }

//    func TestAttachmentSetKey(t *testing.T) {
//        keyPackets, err := testPublicKeyRing.EncryptSessionKey(testSymmetricKey)
//        if err != nil {
//            t.Fatal("Expected no error while encrypting attachment key, got:", err)
//        }
//
//        symmetricKey, err := testPrivateKeyRing.DecryptSessionKey(keyPackets)
//        if err != nil {
//            t.Fatal("Expected no error while decrypting attachment key, got:", err)
//        }
//
//        assert.Exactly(t, testSymmetricKey, symmetricKey)
//    }
//
//    func TestAttachmentEncryptDecrypt(t *testing.T) {
//        var testAttachmentCleartext = "cc,\ndille."
//        var message = NewPlainMessage([]byte(testAttachmentCleartext))
//
//        encSplit, err := testPrivateKeyRing.EncryptAttachment(message, "s.txt")
//        if err != nil {
//            t.Fatal("Expected no error while encrypting attachment, got:", err)
//        }
//
//        redecData, err := testPrivateKeyRing.DecryptAttachment(encSplit)
//        if err != nil {
//            t.Fatal("Expected no error while decrypting attachment, got:", err)
//        }
//
//        assert.Exactly(t, message, redecData)
//    }
//
//    func TestAttachmentEncrypt(t *testing.T) {
//        var testAttachmentCleartext = "cc,\ndille."
//        var message = NewPlainMessage([]byte(testAttachmentCleartext))
//
//        encSplit, err := testPrivateKeyRing.EncryptAttachment(message, "s.txt")
//        if err != nil {
//            t.Fatal("Expected no error while encrypting attachment, got:", err)
//        }
//
//        pgpMessage := NewPGPMessage(encSplit.GetBinary())
//
//        redecData, err := testPrivateKeyRing.Decrypt(pgpMessage, nil, 0)
//        if err != nil {
//            t.Fatal("Expected no error while decrypting attachment, got:", err)
//        }
//
//        assert.Exactly(t, message, redecData)
//    }
//
//    func TestAttachmentDecrypt(t *testing.T) {
//        var testAttachmentCleartext = "cc,\ndille."
//        var message = NewPlainMessage([]byte(testAttachmentCleartext))
//
//        encrypted, err := testPrivateKeyRing.Encrypt(message, nil)
//        if err != nil {
//            t.Fatal("Expected no error while encrypting attachment, got:", err)
//        }
//
//        armored, err := encrypted.GetArmored()
//        if err != nil {
//            t.Fatal("Expected no error while armoring, got:", err)
//        }
//
//        pgpSplitMessage, err := NewPGPSplitMessageFromArmored(armored)
//        if err != nil {
//            t.Fatal("Expected no error while unarmoring, got:", err)
//        }
//
//        redecData, err := testPrivateKeyRing.DecryptAttachment(pgpSplitMessage)
//        if err != nil {
//            t.Fatal("Expected no error while decrypting attachment, got:", err)
//        }
//
//        assert.Exactly(t, message, redecData)
//    }


    func testExample() {
//        sharedAPIService.authAuth(username: "feng", password: "123") { auth, error in
//            if error == nil {
//                self.isSignedIn = true
//                self.username = username
//                self.password = password
//                
//                if isRemembered {
//                    self.isRememberUser = isRemembered
//                }
//                
//                let completionWrapper: UserInfoBlock = { auth, error in
//                    if error == nil {
//                        NSNotificationCenter.defaultCenter().postNotificationName(Notification.didSignIn, object: self)
//                    }
//                    
//                    completion(auth, error)
//                }
//                
//                self.fetchUserInfo(completion: completionWrapper)
//            } else {
//                self.signOut(true)
//                completion(nil, error)
//            }
//        }
        XCTAssert(true, "Pass")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testAuth() {
//        apiService.authAuth(username: "zhj4478", password: "31Feng31"){ auth, error in
//            if error == nil {
//                XCTAssert(true, "Pass")
//            } else {
//                
//                XCTAssertTrue(false, "failed")
//            }
//        }

    }

}
