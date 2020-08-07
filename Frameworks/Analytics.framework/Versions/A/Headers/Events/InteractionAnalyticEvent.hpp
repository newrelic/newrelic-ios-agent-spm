#include "NamedAnalyticEvent.hpp"
#ifndef __InteractionEvent_H_
#define __InteractionEvent_H_


namespace NewRelic {
    class InteractionAnalyticEvent : public NamedAnalyticEvent {
    friend class EventManager;
    private:
    protected:
        InteractionAnalyticEvent(const char *name,
                                 unsigned long long timestamp_epoch_millis,
                                 double session_elapsed_time_sec,
                                 AttributeValidator &attributeValidator);
    public:
        static const std::string& __category;
        virtual const std::string& getCategory() const;
        InteractionAnalyticEvent(const InteractionAnalyticEvent& event);



        static const char* kInteractionTraceDurationKey;
        virtual std::shared_ptr<NRJSON::JsonObject> generateJSONObject() const;
    };
}


#endif //__InteractionEvent_H_
