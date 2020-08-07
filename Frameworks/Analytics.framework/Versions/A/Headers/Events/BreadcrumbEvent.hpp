#ifndef LIBMOBILEAGENT_BREADCRUMBEVENT_HPP
#define LIBMOBILEAGENT_BREADCRUMBEVENT_HPP

#include "CustomEvent.hpp"
#include "Analytics/Events/AnalyticEvent.hpp"

namespace NewRelic {
    class BreadcrumbEvent : public CustomEvent {
       friend class EventManager;
    protected:
        BreadcrumbEvent(unsigned long long timestamp_epoch_millis,
                        double session_elapsed_time_sec,
                        AttributeValidator &attributeValidator);
    };
}
#endif //LIBMOBILEAGENT_BREADCRUMBEVENT_HPP
