//
//

#ifndef LIBMOBILEAGENT_IJSONABLE_HPP
#define LIBMOBILEAGENT_IJSONABLE_HPP
#include <JSON/json.hh>
namespace NRJSON {
    class IJsonable {
    public:
        virtual JsonObject toJSON() = 0;
    };
}
#endif //LIBMOBILEAGENT_IJSONABLE_HPP
