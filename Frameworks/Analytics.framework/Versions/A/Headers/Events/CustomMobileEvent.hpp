#include <string>
#include "NamedAnalyticEvent.hpp"

#ifndef __CustomMobileEvent_H_
#define __CustomMobileEvent_H_

namespace NewRelic {
    class CustomMobileEvent : public NamedAnalyticEvent {
    friend class EventManager;
    private:


    protected:

        CustomMobileEvent(const char *name,
                            unsigned long long timestamp_epoch_millis,
                            double session_elapsed_time_sec,
                            AttributeValidator &attributeValidator);
    public:
        static const std::string& __category;
        virtual const std::string& getCategory() const;
        CustomMobileEvent(const CustomMobileEvent& event);
        virtual std::shared_ptr<NRJSON::JsonObject> generateJSONObject()const;
    };
}
#endif
