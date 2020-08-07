#ifndef LIBMOBILEAGENT_CUSTOMEVENT_HPP
#define LIBMOBILEAGENT_CUSTOMEVENT_HPP

#include "Analytics/Events/AnalyticEvent.hpp"

namespace NewRelic {
    class CustomEvent : public AnalyticEvent {
        friend class EventManager;
    protected:
        CustomEvent(std::shared_ptr<std::string> eventType,
                    unsigned long long timestamp_epoch_millis,
                    double session_elapsed_time_sec,
                    AttributeValidator &attributeValidator);
    public:
        CustomEvent(const CustomEvent& event);
        virtual void put(std::ostream& os) const;
        virtual std::shared_ptr<NRJSON::JsonObject> generateJSONObject()const;
    };

}
#endif //LIBMOBILEAGENT_CUSTOMEVENT_HPP
