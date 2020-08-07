
#ifndef __SessionAttributeManager_H_
#define __SessionAttributeManager_H_

#include "Analytics/AttributeValidator.hpp"
#include "Analytics/SessionAttributeManager.hpp"
#include "Analytics/AttributeBase.hpp"
#include "Analytics/Stores/PersistentStore.hpp"
#include <memory>
#include <map>
#include <JSON/json.hh>

namespace NewRelic {
    class SessionAttributeManager {
        friend class AnalyticsController;
    private:
        mutable std::recursive_mutex _attributesLock;
        std::map<std::string, std::shared_ptr<AttributeBase>> _sessionAttributes;

        mutable std::mutex _privateAttributesLock;
        std::map<std::string, std::shared_ptr<AttributeBase>> _privateSessionAttributes;
        PersistentStore<std::string, BaseValue>& _sessionAttributeStore;
        PersistentStore<std::string,BaseValue>& _attributeDuplicationStore;
        AttributeValidator& _attributeValidator;

        bool restorePersistentAttributes();



        /*
         * @function: addAttribute
         * @param: std::shared_ptr<AttributeBase> attribute
         *        an attribute generated using Attribute factory class
         *
         * @return: bool true if attribute successfully added/updated in stores
         *         false if otherwise.
         *
         * @throw: none
         *
         * @detail: if a key-value already exists this function will update them
         *          including persistent key-values.
         *          New inserts are added as non-persistent.
         */
        bool addAttribute(std::shared_ptr<AttributeBase> attribute);

        /*
         * @function: addAttribute
         * @param: std::shared_ptr<AttributeBase> attribute
         *      an attribute generated using Attribute factory class.
         * @param: bool persistent
         *      a boolean flag that represents persistence of the attribute
         *
         * @return bool true if attribute successfully added/updated to the stores
         *         false if there is a failure.
         *
         * @throw none
         *
         * @details: the persistent flag is explicit. If persistent is false
         *           a pre-existing persistent  key-match attribute will be removed from the store.
         *           As such, this method is only used with the other explicit "persistent" addSessionAttribute
         *           methods.
         *
         */
        bool addAttribute(std::shared_ptr<AttributeBase> attribute, bool persistent);



    public:

        bool addNRAttribute(std::shared_ptr<AttributeBase> attribute);

        static const unsigned int kAttributeLimit{128};

        SessionAttributeManager(PersistentStore<std::string, BaseValue>& attributeStore,
                                                     PersistentStore<std::string,BaseValue>& attributeDuplicationStore,
                                AttributeValidator& validator);
        /*
         * @function: addAttribute
         * @param: const char* name
         *        the attribute name
         * @param: value
         *        the attribute value
         *
         * @return: bool true if attribute successfully added/updated in stores
         *         false if otherwise.
         *
         * @throw: none
         *
         * @detail: if a key-value already exists this function will update them
         *          including persistent key-values.
         *          New inserts are added as non-persistent.
         */
        bool addSessionAttribute(const char* name, const char* value);
        bool addSessionAttribute(const char *name, double value);
        bool addSessionAttribute(const char* name, long long value);
        bool addSessionAttribute(const char* name, unsigned long long value);
        bool addSessionAttribute(const char* name, bool value);
        /*
         * @function: addAttribute
         * @param: const char* name
         *          the attribute name
         *
         * @param: value
         *          the attribute value
         *
         * @param: bool persistent
         *      a boolean flag that represents persistence of the attribute
         *
         * @return bool true if attribute successfully added/updated to the stores
         *         false if there is a failure.
         *
         * @throw none
         *
         * @details: the persistent flag is explicit. If persistent is false
         *           a pre-existing persistent  key-match attribute will be removed from the store.
         *           As such, this method is only used with the other explicit "persistent" addSessionAttribute
         *           methods.
         *
         */
        bool addSessionAttribute(const char* name, const char* value, bool persistent);
        bool addSessionAttribute(const char *name, double value, bool persistent);
        bool addSessionAttribute(const char* name, long long value, bool persistent);
        bool addSessionAttribute(const char* name, unsigned long long value, bool persistent);
        bool addSessionAttribute(const char* name, bool value, bool persistent);
        /*
         * @function removeSessionAttribute
         * @param const char* name
         *
         * @return bool true if attribute is removed, false if attribute doesn't exist, or failure.
         *
         * @throw none
         *
         * @details removes attribute from persistent store, too.
         */
        bool removeSessionAttribute(const char* name);
        
        bool clearSessionAttributes();

        /*
         * @function incrementAttribute
         * @param const char* name
         * @param float value
         *
         * @return bool true if attribute is removed, false if attribute doesn't exist, or failure.
         *
         * @throw none
         *
         * @details increments attribute by value.
         *
         */
        bool incrementAttribute(const char *name, double value);

        bool incrementAttribute(const char *name, double value, bool persistent);

        bool incrementAttribute(const char *name, unsigned long long value);

        bool incrementAttribute(const char *name, unsigned long long value, bool persistent);

        /*
         * @function generateJSONObject
         *
         * @return std::shared_ptr<NRJSON::JsonObject>
         *     returns a json dictionary of attributes.
         */
        std::shared_ptr<NRJSON::JsonObject> generateJSONObject() const;

        static std::shared_ptr<NRJSON::JsonObject> generateJSONObject(std::map<std::string,std::shared_ptr<AttributeBase>>& attributes);

        const std::map<std::string, std::shared_ptr<AttributeBase>> getSessionAttributes() const;

    };
}


#endif //__SessionAttributeManager_H_
