//
//  NRMAHexUploader.h
//  NewRelic
//
//  Created by Bryce Buchanan on 7/25/17.
//  Copyright (c) 2017 New Relic. All rights reserved.
//



#import "NRMAConnection.h"

/*
 * This class manages the upload and retry of binary data to the specified endpoint
 * It is currently used in tandem with the HexUploadPublisher, which is a C++ class passed to the libMobileAgent to
 * manage Hex Report publication.
 *
 * This is the simpler version of the hex uploader (contrasting the NRMAHexBackgroundUploader) and only manages upload
 * data in memory. This means if the app catastrophically fails the last minute worth of Hex reports will be lost.
 * It is intended to replace this uploader variant with one that saves reports to disk to protect against that loss.
 *
 * To replace this object in use look to the HExUploadPublisher where this NRMAHexUploader is injected as a PIMPL
 * object.
 */

@interface NRMAHexUploader : NRMAConnection<NSURLSessionDelegate, NSURLSessionDataDelegate>

- (instancetype) initWithHost:(NSString*)host;

- (void) sendData:(NSData*)data;

- (void) retryFailedTasks;

- (void) invalidate;

@end
