//
// Created by Bryce Buchanan on 6/12/17.
//

#ifndef LIBMOBILEAGENT_STRINGATTRIBUTES_HPP
#define LIBMOBILEAGENT_STRINGATTRIBUTES_HPP


#include "Hex/generated/session-attributes_generated.h"
#import "Hex/report/attributes/Attributes.hpp"

using namespace com::newrelic::mobile::fbs;
using namespace flatbuffers;
namespace NewRelic {
    namespace Hex {
        namespace Report {
            class StringAttributes : public Attributes<std::string> {

            public:
                StringAttributes();

                flatbuffers::Offset<Vector<Offset<StringSessionAttribute>>>
                serialize(flatbuffers::FlatBufferBuilder& builder) const;
            };
        }
    }
}


#endif //LIBMOBILEAGENT_STRINGATTRIBUTES_HPP
