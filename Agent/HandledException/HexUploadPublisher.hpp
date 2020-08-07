//
// Created by Bryce Buchanan on 7/7/17.
// Copyright (c) 2017 New Relic. All rights reserved.
//

#ifndef NEWRELICAGENT_HEXUPLOADPUBLISHER_H
#define NEWRELICAGENT_HEXUPLOADPUBLISHER_H

#include <Hex/HexPublisher.hpp>
/*
 * Follows the HexPublisher interface for dependency injection into the NewRelic::Hex::HexController
 * This class uses a PIMPL to allow for Obj-c code to be called from C++ allowing access to the high-level networking
 * libraries, e.g. NSURLSession.
 */
namespace NewRelic {
    namespace Hex {

        struct UploaderImpl;

        class HexUploadPublisher : public HexPublisher {
        public:
            HexUploadPublisher(const char* storePath, const char* appToken, const char* appVersion, const char* collectorAddress);
            HexUploadPublisher(const HexUploadPublisher&) = delete;
            virtual void publish(std::shared_ptr<HexContext>const& context);
            virtual ~HexUploadPublisher();
//            void auditFlatBuffer(uint8_t* buf);
            void retry();
        protected:
            UploaderImpl* uploaderImpl(); //testing
        private:
            UploaderImpl* uploader;
        };

    }
}

#endif //NEWRELICAGENT_HEXUPLOADPUBLISHER_H
