//
// Created by Bryce Buchanan on 2/4/16.
//

#ifndef LIBMOBILEAGENT_EVENTDESERIALIZER_HPP
#define LIBMOBILEAGENT_EVENTDESERIALIZER_HPP

#include "Analytics/Events/AnalyticEvent.hpp"
#include "Analytics/Deserializer.hpp"
#include <sstream>
namespace NewRelic {
    class EventDeserializer : public Deserializer {
    private:
        static std::shared_ptr<AnalyticEvent> deserializeInteractionEvent(std::istream& is,
                                                                          AttributeValidator& validator);
        static std::shared_ptr<AnalyticEvent> deserializeSessionEvent(std::istream& is,
                                                               AttributeValidator& validator);
        static std::shared_ptr<AnalyticEvent> deserializeCustomMobileEvent(std::istream& is,
                                                                           AttributeValidator& validator);
        static std::shared_ptr<AnalyticEvent> deserializeMobileEvent(std::istream& is);
        static std::shared_ptr<AnalyticEvent> deserializeUserActionEvent(std::istream &is);
        static std::shared_ptr<AnalyticEvent> deserializeCustomEvent(std::string& eventType, std::istream& is);
    public:
        static std::shared_ptr<AnalyticEvent> deserialize(std::istream& is);
    };
}
#endif //LIBMOBILEAGENT_EVENTDESERIALIZER_HPP

