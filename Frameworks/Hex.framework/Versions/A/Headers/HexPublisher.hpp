//
// Created by Bryce Buchanan on 6/15/17.
//

#ifndef LIBMOBILEAGENT_HEXPUBLISHER_HPP
#define LIBMOBILEAGENT_HEXPUBLISHER_HPP

#include "Hex/HexContext.hpp"

namespace NewRelic {
    namespace Hex {
        class HexPublisher {

        public:
            virtual void publish(std::shared_ptr<HexContext> const& context);

            std::string lastPublishedFile();

            explicit HexPublisher(const char* storePath);

            virtual ~HexPublisher() = default;

        protected:
            std::vector<HexContext> reports;

            std::string generateFilename();

            std::string writeBytesToStore(uint8_t* bytes,
                                          size_t length);

            std::string storePath = ".";
            std::string filename = "";
        private:
            static const char* FILE_BASE;
            static const char* FILE_EXTENSION;
        };
    }
}

#endif //LIBMOBILEAGENT_HEXPUBLISHER_HPP
