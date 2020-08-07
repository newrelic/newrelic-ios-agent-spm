//
// Created by Bryce Buchanan on 6/12/17.
//

#ifndef LIBMOBILEAGENT_BOOL_HPP
#define LIBMOBILEAGENT_BOOL_HPP

#include "Hex/generated/session-attributes_generated.h"
#include "Attributes.hpp"

using namespace com::newrelic::mobile;
using namespace flatbuffers;
namespace NewRelic {
    namespace Hex {
        namespace Report {
            class BooleanAttributes : public Attributes<bool> {
            public:
                BooleanAttributes();

                Offset<Vector<Offset<fbs::BoolSessionAttribute>>>
                serialize(flatbuffers::FlatBufferBuilder& builder) const;
            };
        }
    }
}


#endif //LIBMOBILEAGENT_BOOL_HPP
