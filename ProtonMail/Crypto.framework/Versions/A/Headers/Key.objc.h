// Objective-C API for talking to gitlab.com/ProtonMail/go-pm-crypto/key Go package.
//   gobind -lang=objc gitlab.com/ProtonMail/go-pm-crypto/key
//
// File is generated by gobind. Do not edit.

#ifndef __Key_H__
#define __Key_H__

@import Foundation;
#include "Universe.objc.h"


FOUNDATION_EXPORT BOOL KeyCheckPassphrase(NSString* privateKey, NSString* passphrase);

FOUNDATION_EXPORT NSString* KeyGetFingerprint(NSString* publicKey, NSError** error);

FOUNDATION_EXPORT NSString* KeyGetFingerprintBinKey(NSData* publicKey, NSError** error);

FOUNDATION_EXPORT NSString* KeyPublicKey(NSString* privateKey, NSError** error);

FOUNDATION_EXPORT NSData* KeyPublicKeyBinOut(NSString* privateKey, NSError** error);

#endif
