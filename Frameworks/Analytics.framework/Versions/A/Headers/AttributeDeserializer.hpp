//
// Created by Bryce Buchanan on 2/5/16.
//

#ifndef LIBMOBILEAGENT_ATTRIBUTEDESERIALIZER_HPP
#define LIBMOBILEAGENT_ATTRIBUTEDESERIALIZER_HPP
#include "AttributeBase.hpp"
#include "Deserializer.hpp"
#include <sstream>
namespace NewRelic {
    class AttributeDeserializer : public Deserializer {
    public:
        static std::shared_ptr<AttributeBase> deserializeAttributes(std::istream& is);
    };
}
#endif //LIBMOBILEAGENT_ATTRIBUTEDESERIALIZER_HPP
