//
//  Utils.h
//  Ladder-mac
//
//  Created by TsanFeng Lam on 2019/2/19.
//  Copyright © 2019 Aofei Sheng. All rights reserved.
//

#ifndef QRCodeUtils_h
#define QRCodeUtils_h

#import <AppKit/AppKit.h>

OBJC_EXTERN NSArray <NSURL *>* ScanQRCodeOnScreen(void);

OBJC_EXTERN NSImage* createQRImage(NSString *string, NSSize size);

#endif /* QRCodeUtils_h */
