#ifndef LIBMOBILEAGENT_NETWORKERROREVENT_HPP
#define LIBMOBILEAGENT_NETWORKERROREVENT_HPP

#include "IntrinsicEvent.hpp"

namespace NewRelic {
    class NetworkErrorEvent : public IntrinsicEvent {
        friend class EventManager;
        friend class EventDeserializer;
    protected:
        NetworkErrorEvent(unsigned long long timestamp_epoch_millis,
                          double session_elapsed_time_sec,
                          const char* encodedResponseBody,
                          const char* appDataHeader,
                          std::unique_ptr<const Connectivity::Payload> payload,
                          AttributeValidator& attributeValidator);
    public:
        static const std::string __eventType;
        virtual void put(std::ostream& os) const;
//        virtual bool equal(const AnalyticEvent& event) const;
    };
}
#endif //LIBMOBILEAGENT_NETWORKERROREVENT_HPP
