#include "Analytics/Events/MobileEvent.hpp"
#include "Analytics/AttributeValidator.hpp"
#include "NamedAnalyticEvent.hpp"

#ifndef __SessionAnalyticEvent_H_
#define __SessionAnalyticEvent_H_
namespace NewRelic{
    class SessionAnalyticEvent : public MobileEvent {
        friend class EventManager;
    private:
    protected:
        SessionAnalyticEvent(unsigned long long timestamp_epoch_millis,
                             double session_elapsed_time_sec,
                             AttributeValidator& validator);
    public:

        SessionAnalyticEvent(const SessionAnalyticEvent& event);

        virtual ~SessionAnalyticEvent();

        virtual const std::string& getCategory() const;
        static const std::string& __category;
        virtual std::shared_ptr<NRJSON::JsonObject> generateJSONObject()const;

    };
}
#endif
