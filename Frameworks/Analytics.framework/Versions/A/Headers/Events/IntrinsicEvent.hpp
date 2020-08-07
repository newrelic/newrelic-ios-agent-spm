
#ifndef LIBMOBILEAGENT_INTRINSICEVENT_HPP
#define LIBMOBILEAGENT_INTRINSICEVENT_HPP
#include <Analytics/Events/AnalyticEvent.hpp>
#include <Connectivity/Payload.hpp>
namespace NewRelic {
    class IntrinsicEvent : public AnalyticEvent {
    private:
        void addIntrinsicAttribute(const char* key, const char* value);
        void addIntrinsicAttribute(const char* key, int value);
    public:
        IntrinsicEvent(std::shared_ptr<std::string> eventType,
                       std::unique_ptr<const Connectivity::Payload> payload,
                       unsigned long long int timestamp_epoch_millis,
                       double session_elapsed_time_sec,
                       AttributeValidator& attributeValidator);

    };
} // namespace NewRelic
#endif //LIBMOBILEAGENT_INTRINSICEVENT_HPP
