#ifndef LIBMOBILEAGENT_FACADESINGLETON_HPP
#define LIBMOBILEAGENT_FACADESINGLETON_HPP

#include <memory>
#include <shared_mutex>
#include <atomic>

#include "IFacade.hpp"

namespace NewRelic {
namespace Connectivity {
class Facade : public IFacade {
    /*
     * spec doc:
     * https://source.datanerd.us/earnold/agent-specs/blob/new-connectivity/Distributed-Tracing.md
     */
private:
    std::string _currentTraceId;
    std::string _currentParentId;
    mutable std::recursive_mutex _writeMutex;

    static IFacade* __instance;

    Facade() = default;
public:
    static IFacade& getInstance();
    std::unique_ptr<Payload> newPayload() override;
    std::unique_ptr<Payload> startTrip() override;
};

} //namespace Connectivity
} //namespace NewRelic
#endif //LIBMOBILEAGENT_FACADESINGLETON_HPP
