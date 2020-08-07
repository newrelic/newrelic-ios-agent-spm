//
// Created by Bryce Buchanan on 6/12/17.
//

#ifndef LIBMOBILEAGENT_ATTRIBUTES_HPP
#define LIBMOBILEAGENT_ATTRIBUTES_HPP

#include "flatbuffers/flatbuffers.h"
#include "map"

namespace NewRelic {
    namespace Hex {
        namespace Report {
            template<class T>
            class Attributes {
            private:
                std::map<std::string, T> _attributes;
            public:
                const std::map<std::string, T>& get_attributes() const {
                    return _attributes;
                }

                void add(std::string key,
                         T value) {
                    this->_attributes[key] = value;
                }

                Attributes() {}
            };

        }
    }
}

#endif //LIBMOBILEAGENT_ATTRIBUTES_HPP
