//
// Created by Bryce Buchanan on 7/7/17.
// Copyright (c) 2017 New Relic. All rights reserved.
//

#include "HexUploadPublisher.hpp"
#import <Foundation/Foundation.h>
#import "NRMAHexUploader.h"
#import "NRLogger.h"


namespace NewRelic {
    namespace Hex {

        struct UploaderImpl {
            NRMAHexUploader* wrapper;
        };

        HexUploadPublisher::HexUploadPublisher(const char* storePath, const char* appToken, const char* appVersion, const char* collectorAddress)
                : HexPublisher::HexPublisher(storePath),
                  uploader(new UploaderImpl) {
            //handle collector address param!
            uploader->wrapper = [[NRMAHexUploader alloc] initWithHost:[NSString stringWithUTF8String:collectorAddress]];
            uploader->wrapper.applicationToken = [NSString stringWithUTF8String:appToken];
            uploader->wrapper.applicationVersion = [NSString stringWithUTF8String:appVersion];
        }

        void HexUploadPublisher::publish(std::shared_ptr<NewRelic::Hex::HexContext>const& context) {

            auto buf = context->getBuilder()->GetBufferPointer();
            auto size = context->getBuilder()->GetSize();

            @autoreleasepool {
                NSData* report = [NSData dataWithBytes:buf
                                                length:size];

                [uploader->wrapper sendData:report];
            }
        }

        void HexUploadPublisher::retry(){
            [uploader->wrapper retryFailedTasks];
        }

        HexUploadPublisher::~HexUploadPublisher() {
            [uploader->wrapper invalidate];
            [uploader->wrapper release];
            delete uploader;
        }

        UploaderImpl* HexUploadPublisher::uploaderImpl() {
                return uploader;
        }
    }
}
