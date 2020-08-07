//
// Created by Bryce Buchanan on 6/13/17.
//

#ifndef LIBMOBILEAGENT_THREAD_HPP
#define LIBMOBILEAGENT_THREAD_HPP

#include "Hex/report/exception/Frame.hpp"
#include "Hex/generated/hex_generated.h"

using namespace com::newrelic::mobile;
using namespace flatbuffers;
namespace NewRelic {
    namespace Hex {
        namespace Report {
            class Thread {
            public:

                explicit Thread(std::vector<Frame> frames);

                Offset<fbs::hex::Thread> serialize(flatbuffers::FlatBufferBuilder& builder) const;

            private:
                std::vector<Frame> _frames;


            };
        }
    }
}

#endif //LIBMOBILEAGENT_THREAD_HPP
