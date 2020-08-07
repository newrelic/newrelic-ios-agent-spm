//
// Created by Bryce Buchanan on 6/13/17.
//

#ifndef LIBMOBILEAGENT_LIBRARY_HPP
#define LIBMOBILEAGENT_LIBRARY_HPP

#include "Hex/generated/ios_generated.h"

using namespace com::newrelic::mobile;
using namespace flatbuffers;
namespace NewRelic {
    namespace Hex {
        namespace Report {
            class Library {
            public:
                Library(std::string name,
                        uint64_t uuid_lo,
                        uint64_t uuid_hi,
                        uint64_t address,
                        bool userLibrary,
                        fbs::ios::Arch arch,
                        uint64_t size
                );

                Offset<fbs::ios::Library> serialize(flatbuffers::FlatBufferBuilder& builder) const;

                std::string getName() const { return _name; }

                uint64_t uuidLow() const { return _uuid_lo; }

                uint64_t uuidHigh() const { return _uuid_hi; }

                uint64_t getSize() const { return _size; }

            private:
                std::string _name;
                uint64_t _uuid_lo;
                uint64_t _uuid_hi;
                uint64_t _address;
                bool _userLibrary;
                fbs::ios::Arch _arch;
                uint64_t _size;
            };
        }
    }
}


#endif //LIBMOBILEAGENT_LIBRARY_HPP
