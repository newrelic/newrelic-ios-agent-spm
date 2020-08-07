//
// Created by Bryce Buchanan on 5/19/17.
//

#ifndef LIBMOBILEAGENT_NETWORKEVENT_HPP
#define LIBMOBILEAGENT_NETWORKEVENT_HPP

#include "IntrinsicEvent.hpp"

namespace NewRelic {
    class RequestEvent : public IntrinsicEvent {
        friend class EventManager;
        friend class EventDeserializer;
    protected:
        RequestEvent(unsigned long long timestamp_epoch_millis,
                     double session_elapsed_time_sec,
                     std::unique_ptr<const Connectivity::Payload> payload,
                     AttributeValidator& attributeValidator);
    public:
        static const std::string __eventType;
        virtual void put(std::ostream& os) const;
    };
}
#endif //LIBMOBILEAGENT_NETWORKEVENT_HPP
