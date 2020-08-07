//
// Created by Bryce Buchanan on 2/5/16.
//

#ifndef LIBMOBILEAGENT_DESERIALIZER_HPP
#define LIBMOBILEAGENT_DESERIALIZER_HPP
#include <sstream>
namespace NewRelic {
    class Deserializer {
    protected:
        static std::stringstream readStreamToDelimiter(std::istream& is, char delimiter);
    };
}
#endif //LIBMOBILEAGENT_DESERIALIZER_HPP
