//
// Created by Bryce Buchanan on 6/13/17.
//

#ifndef LIBMOBILEAGENT_FRAME_HPP
#define LIBMOBILEAGENT_FRAME_HPP

#include <Hex/generated/ios_generated.h>
#include <Hex/generated/hex_generated.h>

using namespace com::newrelic::mobile;
using namespace flatbuffers;
namespace NewRelic {
    namespace Hex {
        namespace Report {
            class Frame {
            public:
                Frame(const char* value,
                      uint64_t address);

                Offset<fbs::hex::Frame> serialize(flatbuffers::FlatBufferBuilder& builder) const;

                static uint64_t frameStringToAddress(const char* frame);

            private:
                std::string _value;
                uint64_t _address;
            };
        }
    }
}


#endif //LIBMOBILEAGENT_FRAME_HPP
