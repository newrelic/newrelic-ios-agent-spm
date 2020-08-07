#include "MobileEvent.hpp"
#include <string>
#ifndef __NamedAnalyticEvent_H_
#define __NamedAnalyticEvent_H_


namespace NewRelic {
    class NamedAnalyticEvent : public MobileEvent {
    friend class EventManager;
    private:
        std::string _name;
    protected:
        NamedAnalyticEvent(const char *name,
                           unsigned long long timestamp_epoch_millis,
                           double session_elapsed_time_sec,
                           AttributeValidator &attributeValidator);
    public:
        virtual bool equal(const AnalyticEvent& event) const;
        NamedAnalyticEvent(const NamedAnalyticEvent& event);
        virtual std::shared_ptr<NRJSON::JsonObject> generateJSONObject()const;
        virtual void put(std::ostream& os) const;
    };
}


#endif //__NamedAnalyticEvent_H_
