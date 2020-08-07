//
// Created by Bryce Buchanan on 2/3/16.
//

#ifndef LIBMOBILEAGENT_MOBILEEVENT_HPP
#define LIBMOBILEAGENT_MOBILEEVENT_HPP

#include "Analytics/EventDeserializer.hpp"
#include "Analytics/Events/AnalyticEvent.hpp"


namespace NewRelic {
    class MobileEvent : public AnalyticEvent {
        friend class EventDeserializer;
    private:
    protected:
        MobileEvent(unsigned long long timestamp_epoch_millis,
                    double session_elapsed_time_sec,
                    AttributeValidator &attributeValidator);
    public:
        static const std::string __eventType;
        virtual void put(std::ostream& os) const;
        virtual const std::string&  getCategory() const = 0;
        virtual bool equal(const AnalyticEvent& event) const;
        virtual std::shared_ptr<NRJSON::JsonObject> generateJSONObject()const;
    };

}

#endif //LIBMOBILEAGENT_MOBILEEVENT_HPP
