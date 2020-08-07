
#ifndef LIBMOBILEAGENT_IGUIDGENERATOR_HPP
#define LIBMOBILEAGENT_IGUIDGENERATOR_HPP
#include <random>
namespace NewRelic {
namespace Connectivity {
template<typename T>
class IGuidGenerator {
public:
    static T generateGuid() {
        unsigned seed = static_cast<unsigned int>(std::chrono::system_clock::now().time_since_epoch().count());
        std::default_random_engine generator{seed};
        std::uniform_int_distribution<T> distribution{}; //default constructor does 0 - type_max
        return distribution(generator);
    }
};
}
}
#endif //LIBMOBILEAGENT_IGUIDGENERATOR_HPP
