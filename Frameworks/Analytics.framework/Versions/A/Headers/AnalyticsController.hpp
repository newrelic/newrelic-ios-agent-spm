#include "EventManager.hpp"
#include "AttributeBase.hpp"
#include "AttributeValidator.hpp"
#include "SessionAttributeManager.hpp"
#include "Stores/PersistentStore.hpp"
#include "Analytics/Constants.hpp"
#include "NetworkRequestData.hpp"
#include "NetworkResponseData.hpp"
#include  <JSON/json.hh>
#include <vector>
#include <memory>
#include <Analytics/Events/BreadcrumbEvent.hpp>
#include <Analytics/Events/RequestEvent.hpp>


#ifndef __AnalyticsController_H_
#define __AnalyticsController_H_


namespace NewRelic {
    /*
        I am the primary interface
        I know about the constraints on events and attributes
        I inform the event manager and session manager of data constraints
        I delegate management of events to the EventManager
        I delegate management of session attributes to the sessionManager

     */
    class AnalyticsController {
    private:
        static const char *ATTRIBUTE_STORE_DB_FILENAME;
        static const char *ATTRIBUTE_DUP_STORE_DB_FILENAME;
        static const char *EVENT_DUP_STORE_DB_FILENAME;
        const std::vector <std::string> _reserved_eventTypes{
                __kNRMA_RET_mobile,
                __kNRMA_RET_mobileCrash,
                __kNRMA_RET_mobileRequest,
                __kNRMA_RET_mobileRequestError,
                __kNRMA_RET_mobileSession,
                __kNRMA_RET_mobileBreadcrumb,
        };

        const std::vector <std::string> _reserved_keys{
                __kNRMA_RA_eventType,
                __kNRMA_RA_type,
                __kNRMA_RA_timestamp,
                __kNRMA_RA_category,
                __kNRMA_RA_accountId,
                __kNRMA_RA_appId,
                __kNRMA_RA_appName,
                __kNRMA_RA_uuid,
                __kNRMA_RA_sessionDuration,
                __kNRMA_RA_osName,
                __kNRMA_RA_osVersion,
                __kNRMA_RA_osMajorVersion,
                __kNRMA_RA_deviceManufacturer,
                __kNRMA_RA_deviceModel,
                __kNRMA_RA_carrier,
                __kNRMA_RA_newRelicVersion,
                __kNRMA_RA_memUsageMb,
                __kNRMA_RA_sessionId,
                __kNRMA_RA_install,
                __kNRMA_RA_upgradeFrom,
                __kNRMA_RA_platform,
                __kNRMA_RA_lastInteraction,
        };

        const std::vector <std::string> _reserved_key_prefix{
                __kNRMA_RP_newRelic,
                __kNRMA_RP_nr,
        };

        unsigned long long _session_start_time_ms;
        AttributeValidator _attributeValidator;
        PersistentStore<std::string, BaseValue> &_attributeDuplicationStore;
        PersistentStore<std::string, BaseValue> _attributeStore;
        PersistentStore<std::string, AnalyticEvent> &_eventsDuplicationStore;
        EventManager _eventManager;
        SessionAttributeManager _sessionAttributeManager;


        std::shared_ptr<NetworkErrorEvent> createRequestErrorEvent(const NewRelic::NetworkRequestData& requestData,
                                                                   const NewRelic::NetworkResponseData& responseData,
                                                                   std::unique_ptr<const Connectivity::Payload> payload);

        static unsigned long long int getCurrentTime_ms(); //throws std::logic_error

    public:

        virtual ~AnalyticsController() = default;

        static const char *getPersistentAttributeStoreName();

        static const char *getAttributeDupStoreName();

        static const char *getEventDupStoreName();

        const AttributeValidator &getAttributeValidator() const;

        bool addSessionEndAttribute();

        AnalyticsController(unsigned long long sessionStartTime_ms, const char *sharedPath,
                            PersistentStore<std::string, AnalyticEvent> &eventDupStore,
                            PersistentStore<std::string, BaseValue> &attributeDupStore);

        double getCurrentSessionDuration_sec(unsigned long long current_time_ms) const; //throws std::logic_error

        PersistentStore<std::string, BaseValue> &attributeStore();


        /*
         *  Events interface
         */
        //deprecated
        std::shared_ptr <AnalyticEvent> newEvent(const char *name);

        std::shared_ptr <CustomEvent> newCustomEvent(const char *name);

        std::shared_ptr <BreadcrumbEvent> newBreadcrumbEvent();

        bool addSessionEvent();

        bool addEvent(std::shared_ptr <AnalyticEvent> event);

        bool addRequestEvent(const NewRelic::NetworkRequestData& requestData,
                             const NewRelic::NetworkResponseData& responseData,
                             std::unique_ptr<const Connectivity::Payload> payload);

        bool addHTTPErrorEvent(const NewRelic::NetworkRequestData& requestData,
                               const NewRelic::NetworkResponseData& responseData,
                               std::unique_ptr<const Connectivity::Payload> payload);

        bool addNetworkErrorEvent(const NewRelic::NetworkRequestData& requestData,
                                  const NewRelic::NetworkResponseData& responseData,
                                  std::unique_ptr<const Connectivity::Payload> payload);

        bool addUserActionEvent(const char *functionName,
                                const char *targetObject,
                                const char *label,
                                const char *accessibility,
                                const char *tapCoordinates,
                                const char *actionType,
                                const char *controlFrame,
                                const char *orientation);

        bool addInteractionEvent(const char *name, double duration_sec);

        std::shared_ptr <NRJSON::JsonArray> getEventsJSON(bool clearEvents);

        std::shared_ptr <NRJSON::JsonObject> getSessionAttributeJSON() const;

        const std::map <std::string, std::shared_ptr<AttributeBase>> getSessionAttributes() const;

        void setMaxEventBufferTime(unsigned int seconds);

        bool didReachMaxEventBufferTime();

        void setMaxEventBufferSize(unsigned int size);

        /*
         *  Session Attribute interface
         */
        bool addSessionAttribute(const char *name, const char *value);

        bool addSessionAttribute(const char *name, double value);

        bool addSessionAttribute(const char *name, long long value);

        bool addSessionAttribute(const char *name, unsigned long long value);

        bool addSessionAttribute(const char *name, bool value);

        bool addSessionAttribute(const char *name, const char *value, bool persistent);

        bool addSessionAttribute(const char *name, double value, bool persistent);

        bool addSessionAttribute(const char *name, long long value, bool persistent);

        bool addSessionAttribute(const char *name, unsigned long long value, bool persistent);

        bool addSessionAttribute(const char *name, bool value, bool persistent);

        bool incrementSessionAttribute(const char *name, double value);

        bool incrementSessionAttribute(const char *name, double value, bool persistent);

        bool incrementSessionAttribute(const char *name, unsigned long long value);

        bool incrementSessionAttribute(const char *name, unsigned long long value, bool persistent);

        bool removeSessionAttribute(const char *name);

        bool clearSessionAttributes();

        /*
         * NR only session attribute interface
         */
        bool addNRAttribute(std::shared_ptr <AttributeBase> attribute);


        /*
         *  these methods used to retrieve duplicated data used for appending to crash reports.
         */

        void clearEventsDuplicationStore();

        void clearAttributesDuplicationStore();

        static std::shared_ptr <NRJSON::JsonArray> fetchDuplicatedEvents(
                PersistentStore<std::string, AnalyticEvent> &eventStore,
                bool shouldClearStore);

        static std::shared_ptr <NRJSON::JsonObject> fetchDuplicatedAttributes(
                PersistentStore<std::string, BaseValue> &attributeStore,
                bool shouldClearStore);

        unsigned long long int getSessionId() const {
            return _session_start_time_ms;
        }

    };
}
#endif
