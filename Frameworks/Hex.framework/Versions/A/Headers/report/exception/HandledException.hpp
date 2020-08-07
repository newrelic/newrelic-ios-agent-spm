//
// Created by Bryce Buchanan on 6/12/17.
//

#ifndef LIBMOBILEAGENT_HANDLEDEXCEPTION_HPP
#define LIBMOBILEAGENT_HANDLEDEXCEPTION_HPP

#include "Hex/generated/ios_generated.h"
#include "Hex/generated/hex_generated.h"
#include "Hex/report/exception/Thread.hpp"

using namespace com::newrelic::mobile;
using namespace flatbuffers;
namespace NewRelic {
    namespace Hex {
        namespace Report {
            class HandledException {
            public:
                HandledException(const std::string& sessionId,
                                 uint64_t epochMs,
                                 const char* message,
                                 const char* name,
                                 std::vector<std::shared_ptr<Thread>> threads);

                Offset<Vector<Offset<fbs::hex::HandledException>>>
                serialize(flatbuffers::FlatBufferBuilder& builder) const;

                virtual ~HandledException();

            private:
                const std::string& _sessionId;
                uint64_t _epochMs;
                const std::string _message;
                const std::string _name;
                std::vector<std::shared_ptr<Thread>> _threads;
            };

        }
    }
}

#endif //LIBMOBILEAGENT_HANDLEDEXCEPTION_HPP
