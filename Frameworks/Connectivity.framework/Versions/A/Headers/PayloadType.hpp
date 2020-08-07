#ifndef LIBMOBILEAGENT_PAYLOADTYPE_H
#define LIBMOBILEAGENT_PAYLOADTYPE_H

#include <string>

namespace NewRelic {
namespace Connectivity {

class PayloadType {
public:
    enum Enum {
        mobile,
        invalid_type
    };

    explicit PayloadType(Enum _e);

    //accessors
    inline std::string getString() const {
        return _s;
    };
    inline Enum        getEnum() const {
        return _e;
    };
private:
    static std::string toString(Enum e);

    //member variables
    Enum _e;
    std::string _s;
};
}
}

#endif //LIBMOBILEAGENT_PAYLOADTYPE_H
