
#import "NRMAAnalytics.h"
#import "NRMAAnalytics+cppInterface.h"
#import "NRMALoggerBridge.hpp"

#import "NRLogger.h"
#import "NRMAHarvestableAnalytics.h"
#import <iomanip>
#import <exception>
#import <libkern/OSAtomic.h>
#import "NRMAHarvestController.h"
#import "NRMABool.h"
#import <Utilities/LibLogger.hpp>
#import "NRConstants.h"
#import "NewRelicInternalUtils.h"
#import "NRMAFlags.h"
#import "NRMANetworkRequestData+CppInterface.h"
#import "NRMANetworkResponseData+CppInterface.h"
#import "NRMAUserActionBuilder.h"
#import <Connectivity/Payload.hpp>
#import "NewRelicAgentInternal.h"

using namespace NewRelic;
@implementation NRMAAnalytics
{
    std::shared_ptr<AnalyticsController> _analyticsController;
    BOOL _sessionWillEnd;
}

static PersistentStore<std::string,BaseValue>* __attributeStore;
+ (PersistentStore<std::string, BaseValue> &) attributeDupStore
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
    __attributeStore = new PersistentStore<std::string,BaseValue>{AnalyticsController::getAttributeDupStoreName(), [NewRelicInternalUtils getStorePath].UTF8String, &NewRelic::Value::createValue};
    });

    return (*__attributeStore);
}

static PersistentStore<std::string,AnalyticEvent>* __eventStore;
+ (PersistentStore<std::string, AnalyticEvent> &) eventDupStore
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __eventStore = new PersistentStore<std::string,AnalyticEvent>{AnalyticsController::getEventDupStoreName(),
                                                                     [NewRelicInternalUtils getStorePath].UTF8String,
                                                                     &NewRelic::EventManager::newEvent,
                                                                     [](std::string const& key, std::shared_ptr<AnalyticEvent> event){
                                                                        return key == EventManager::createKey(event) ;
                                                                     }};
    });
    return (*__eventStore);
}   

- (std::shared_ptr<NewRelic::AnalyticsController>&) analyticsController {
    return _analyticsController;
}

- (void) setMaxEventBufferSize:(unsigned int) size {
    _analyticsController->setMaxEventBufferSize(size);
}
- (void) setMaxEventBufferTime:(unsigned int)seconds
{
    _analyticsController->setMaxEventBufferTime(seconds);
}

- (id) initWithSessionStartTimeMS:(long long) sessionStartTime {
    self = [super init];
    if(self){
        if(!__has_feature(cxx_exceptions)) {
            NRLOG_ERROR(@"C++ exception handling is disabled. This will cause incorrect behavior in the New Relic Agent.");
            @throw [NSException exceptionWithName:@"Invalid Configuration" reason:@"c++ exception handling is disabled" userInfo:nil];
        }

        NSString* documentDirURL = [NewRelicInternalUtils getStorePath];
        LibLogger::setLogger(std::make_shared<NewRelic::NRMALoggerBridge>(NewRelic::NRMALoggerBridge()));
        _analyticsController = std::make_shared<NewRelic::AnalyticsController>(sessionStartTime,documentDirURL.UTF8String, [NRMAAnalytics eventDupStore], [NRMAAnalytics attributeDupStore]);
        //__kNRMA_RA_upgradeFrom and __kNRMA_RA_install are only valid for one session
        //and will be set shortly after the initialization of NRMAAnalytics.
        //They can be removed now and it shouldn't interfere with the generation
        //of these attributes if it should occur.
        _analyticsController->removeSessionAttribute(__kNRMA_RA_upgradeFrom);
        _analyticsController->removeSessionAttribute(kNRMASecureUDIDIsNilNotification.UTF8String);
        _analyticsController->removeSessionAttribute(kNRMADeviceChangedAttribute.UTF8String);
        _analyticsController->removeSessionAttribute(__kNRMA_RA_install);

        //session duration is only valid for one session. This metric should be removed
        //after the persistent attributes are loaded.   
        _analyticsController->removeSessionAttribute(__kNRMA_RA_sessionDuration);
    }
    return self;
}

- (void) dealloc {

    [super dealloc];
}

- (BOOL) addInteractionEvent:(NSString*)name
         interactionDuration:(double)duration_secs {
    return _analyticsController->addInteractionEvent([name UTF8String], duration_secs);
}

- (BOOL)addNetworkRequestEvent:(NRMANetworkRequestData *)requestData
                  withResponse:(NRMANetworkResponseData *)responseData
                   withPayload:(std::unique_ptr<const Connectivity::Payload>)payload {

    if ([NRMAFlags shouldEnableNetworkRequestEvents]) {
        NewRelic::NetworkRequestData* networkRequestData = [requestData getNetworkRequestData];
        NewRelic::NetworkResponseData* networkResponseData = [responseData getNetworkResponseData];
        return _analyticsController->addRequestEvent(*networkRequestData, *networkResponseData, std::move(payload));
    }
    return NO;
}

- (BOOL)addNetworkErrorEvent:(NRMANetworkRequestData *)requestData
                withResponse:(NRMANetworkResponseData *)responseData
                 withPayload:(std::unique_ptr<const NewRelic::Connectivity::Payload>)payload {

    if ([NRMAFlags shouldEnableRequestErrorEvents]) {
        NewRelic::NetworkRequestData* networkRequestData = [requestData getNetworkRequestData];
        NewRelic::NetworkResponseData* networkResponseData = [responseData getNetworkResponseData];

        return _analyticsController->addNetworkErrorEvent(*networkRequestData, *networkResponseData,std::move(payload));
    }

    return NO;
}


- (BOOL)addHTTPErrorEvent:(NRMANetworkRequestData *)requestData
             withResponse:(NRMANetworkResponseData *)responseData
              withPayload:(std::unique_ptr<const NewRelic::Connectivity::Payload>)payload {
    if ([NRMAFlags shouldEnableRequestErrorEvents]) {
        NewRelic::NetworkRequestData* networkRequestData = [requestData getNetworkRequestData];
        NewRelic::NetworkResponseData* networkResponseData = [responseData getNetworkResponseData];

        return _analyticsController->addHTTPErrorEvent(*networkRequestData, *networkResponseData, std::move(payload));
    }
    return NO;
}

- (BOOL) setLastInteraction:(NSString*)name {
    return [self setNRSessionAttribute:@(__kNRMA_RA_lastInteraction)
                                 value:name];
}

- (BOOL) setNRSessionAttribute:(NSString*)name value:(id)value {
    try {
        if ([value isKindOfClass:[NSNumber class]]) {
            NSNumber* number = (NSNumber*)value;
            if ([NewRelicInternalUtils isFloat:number]) {
                auto attribute = NewRelic::Attribute<float>::createAttribute([name UTF8String],
                                                                             [](const char* name_str) {
                                                                                 return strlen(name_str) > 0;
                                                                             },
                                                                             [number floatValue],
                                                                             [](float num) {
                                                                                 return true;
                                                                             });

                return _analyticsController->addNRAttribute(attribute);
            }
            if ([NewRelicInternalUtils isInteger:number]) {
                auto attribute = NewRelic::Attribute<long long>::createAttribute([name UTF8String],
                                                                             [](const char* name_str) {
                                                                                 return strlen(name_str) > 0;
                                                                             },
                                                                             [number longLongValue],
                                                                             [](long long num) {
                                                                                 return true;
                                                                             });
                return _analyticsController->addNRAttribute(attribute);
            }
            return NO;
        } else if ([value isKindOfClass:[NSString class]]) {
            NSString* string = (NSString*)value;
            auto attribute = NewRelic::Attribute<const char*>::createAttribute([name UTF8String], [](const char* name_str) {
                return strlen(name_str) > 0;
            }, [string UTF8String], [](const char* value_str) {
                return strlen(value_str) > 0;
            });
            return _analyticsController->addNRAttribute(attribute);
        } else if([value isKindOfClass:[NRMABool class]]) {
                auto attribute = NewRelic::Attribute<bool>::createAttribute([name UTF8String],
                                                                            [](const char* name_str) {return strlen(name_str) > 0;},
                                                                            ((NRMABool*)value).value,
                                                                            [](bool) { return true;});
                return _analyticsController->addNRAttribute(attribute);
        } else {
            NRLOG_VERBOSE(@"Session attribute \'value\' must be either an NSString* or NSNumber*");
            return NO;
        }
    } catch (std::exception& error) {
        NRLOG_VERBOSE(@"failed to add NR session attribute, \'%@\' : %s",name, error.what());
        return NO;
    } catch (...) {
        NRLOG_VERBOSE(@"failed to add NR session attribute.");
        return NO;

    }
}

- (BOOL) setSessionAttribute:(NSString*)name value:(id)value persistent:(BOOL)isPersistent {
    try {
        if ([value isKindOfClass:[NSNumber class]]) {
            NSNumber* number = (NSNumber*)value;
            //objcType returns a char*, but all primitives are denoted by a single character
            if([NewRelicInternalUtils isInteger:number]) {
                return _analyticsController->addSessionAttribute([name UTF8String], [number longLongValue], (bool)isPersistent);
            }
            if([NewRelicInternalUtils isFloat:number]) {
                return _analyticsController->addSessionAttribute([name UTF8String], [number doubleValue], (bool)isPersistent);
            }
            if ([NewRelicInternalUtils isBool:number]) {
                return _analyticsController->addSessionAttribute([name UTF8String], (bool)[number boolValue], (bool)isPersistent);
            }
            return NO;
        } else if ([value isKindOfClass:[NSString class]]) {
            NSString* string = (NSString*)value;
            return _analyticsController->addSessionAttribute([name UTF8String], [string UTF8String],(bool)isPersistent);
        } else if([value isKindOfClass:[NRMABool class]]) {
                auto attribute = NewRelic::Attribute<bool>::createAttribute([name UTF8String],
                                                                            [](const char* name_str) {return strlen(name_str) > 0;},
                                                                            ((NRMABool*)value).value,
                                                                            [](bool) { return true;});
                return _analyticsController->addNRAttribute(attribute);
        } else {
            NRLOG_ERROR(@"Session attribute \'value\' must be either an NSString* or NSNumber*");
            return NO;
        }
    } catch (std::exception& error) {
        NRLOG_ERROR(@"failed to add session attribute: \'%@\': %s",name ,error.what());
        return NO;
    } catch (...) {
        NRLOG_ERROR(@"failed to add session attribute.");
        return NO;

    }
}

- (BOOL) setSessionAttribute:(NSString*)name value:(id)value {
    try {
        if ([value isKindOfClass:[NSNumber class]]) {
            NSNumber* number = (NSNumber*)value;
            if([NewRelicInternalUtils isInteger:number]) {
                return _analyticsController->addSessionAttribute([name UTF8String], [number longLongValue]);
            }
            if([NewRelicInternalUtils isFloat:number]) {
                return _analyticsController->addSessionAttribute([name UTF8String], [number doubleValue]);
            }
            return NO;
        } else if ([value isKindOfClass:[NSString class]]) {
            NSString* string = (NSString*)value;
            return _analyticsController->addSessionAttribute([name UTF8String], [string UTF8String]);
        } else if([value isKindOfClass:[NRMABool class]]) {
                auto attribute = NewRelic::Attribute<bool>::createAttribute([name UTF8String],
                                                                            [](const char* name_str) {return strlen(name_str) > 0;},
                                                                            ((NRMABool*)value).value,
                                                                            [](bool) { return true;});
                return _analyticsController->addNRAttribute(attribute);
        } else {
            NRLOG_ERROR(@"Session attribute \'value\' must be either an NSString* or NSNumber*");
            return NO;
        }
    } catch (std::exception& error) {
        NRLOG_ERROR(@"failed to add session attribute: \'%@\': %s",name ,error.what());
        return NO;
    } catch (...) {
        NRLOG_ERROR(@"failed to add session attribute.");
        return NO;

    }
}

- (BOOL) setUserId:(NSString *)userId {
    return [self setSessionAttribute:@"userId"
                               value:userId
                          persistent:YES];
}

- (BOOL) removeSessionAttributeNamed:(NSString*)name {
    try {
        return _analyticsController->removeSessionAttribute(name.UTF8String);
    } catch (std::exception& e) {
        NRLOG_ERROR(@"Failed to remove attribute: %s",e.what());
        return NO;
    } catch (...) {
        NRLOG_ERROR(@"Failed to remove attribute.");
        return NO;
    }
}
- (BOOL) removeAllSessionAttributes {
    try {
        return _analyticsController->clearSessionAttributes();
    } catch (std::exception& e) {
        NRLOG_ERROR(@"Failed to remove all attributes: %s",e.what());
        return NO;
    } catch (...) {
        NRLOG_ERROR(@"Failed to remove all attributes.");
        return NO;

    }
}

- (BOOL) addEventNamed:(NSString*)name withAttributes:(NSDictionary*)attributes {
    
    try {
        auto event = _analyticsController->newEvent(name.UTF8String);
        if (event == nullptr) {
            NRLOG_ERROR(@"Unable to create event with name: \"%@\"",name);
            return NO;
        }

        if ([self event:event withAttributes:attributes]) {
            return _analyticsController->addEvent(event);
        }
    } catch (std::exception& e){
        NRLOG_ERROR(@"Failed to add event: %s",e.what());
        return NO;
    } catch (...) {
        NRLOG_ERROR(@"Failed to add event named: %@.\nPossible due to reserved word conflict.",name);
        return NO;
    }
    return NO;
}

- (BOOL) addBreadcrumb:(NSString*)name
        withAttributes:(NSDictionary*)attributes {
    try {

        if(!name.length) {
            NRLOG_ERROR(@"Breadcrumb must be named.");
            return NO;
        }

        auto event = _analyticsController->newBreadcrumbEvent();
        if (event == nullptr) {
            NRLOG_ERROR(@"Unable to create breadcrumb event");
            return NO;
        }

        if ([self event:event withAttributes:attributes]) {
                event->addAttribute("name",name.UTF8String);
            return _analyticsController->addEvent(event);
        }
    } catch (std::exception& e){
        NRLOG_ERROR(@"Failed to add event: %s",e.what());
        return NO;
    } catch (...) {
        NRLOG_ERROR(@"Failed to add event named: %@.\nPossible due to reserved word conflict.",name);
        return NO;
    }
    return NO;
}


- (BOOL) addCustomEvent:(NSString*)eventType
         withAttributes:(NSDictionary*)attributes {

    try {

        NSError* error;
        NSRegularExpression* eventTypeRegex = [NSRegularExpression regularExpressionWithPattern:@"^[\\p{L}\\p{Nd} _:.]+$"
                                                                                        options:NSRegularExpressionUseUnicodeWordBoundaries
                                                                                          error:&error];

        NSArray* textCheckingResults = [eventTypeRegex matchesInString:eventType
                                                               options:NSMatchingReportCompletion
                                                                 range:NSMakeRange(0, eventType.length)];

        if (!(textCheckingResults.count > 0 && ((NSTextCheckingResult*)textCheckingResults[0]).range.length == eventType.length)) {
            NRLOG_ERROR(@"Failed to add event type: %@. EventType is may only contain word characters, numbers, spaces, colons, underscores, and periods.",eventType);
            return NO;
        }


        auto event = _analyticsController->newCustomEvent(eventType.UTF8String);

        if (event == nullptr) {
            NRLOG_ERROR(@"Unable to create event with name: \"%@\"",eventType);
            return NO;
        }

        if([self event:event withAttributes:attributes]) {
            return _analyticsController->addEvent(event);
        }
    } catch (std::exception& e){
        NRLOG_ERROR(@"Failed to add event: %s",e.what());
        return NO;
    } catch (...) {
        NRLOG_ERROR(@"Failed to add event named: %@.\nPossible due to reserved word conflict.",eventType);
        return NO;
    }
    return NO;
}

- (BOOL) event:(std::shared_ptr<AnalyticEvent>)event withAttributes:(NSDictionary*)attributes {
    for (NSString* key in attributes.allKeys) {
        id value = attributes[key];
        if ([value isKindOfClass:[NSString class]]) {
            event->addAttribute(key.UTF8String,((NSString*)value).UTF8String);
        } else if ([value isKindOfClass:[NSNumber class]]) {
            NSNumber* number = (NSNumber*)value;
            if ([NewRelicInternalUtils isInteger:number]) {
                event->addAttribute(key.UTF8String, number.longLongValue);
            } else if ([NewRelicInternalUtils isFloat:number]) {
                event->addAttribute(key.UTF8String, number.doubleValue);
            } else if ([NewRelicInternalUtils isBool:number]) {
                event->addAttribute(key.UTF8String,number.boolValue);
            } else {
                NRLOG_ERROR(@"Failed to add event: attribute \"%@\" value is invalid NSNumber with objCType: %s",key,[number objCType]);
                return NO;
            }
        } else if([value isKindOfClass:[NRMABool class]]) {
            event->addAttribute(key.UTF8String, (bool)((NRMABool*)value).value);
        } else {
            NRLOG_ERROR(@"Failed to add event: attribute values must be type NSNumber* or NSString*.");
            return NO;
        }
    }
    return YES;
}

- (BOOL) incrementSessionAttribute:(NSString*)name value:(NSNumber*)number
{
    if ([NewRelicInternalUtils isInteger:number]) {
    return _analyticsController->incrementSessionAttribute([name UTF8String], (unsigned long long)[number longLongValue]); //has internal exception handling
    } else if ([NewRelicInternalUtils isFloat:number]) {
        return _analyticsController->incrementSessionAttribute([name UTF8String], [number doubleValue]); //has internal exception handling
    } else {
        return NO;
    }
}

- (BOOL) incrementSessionAttribute:(NSString*)name value:(NSNumber*)number persistent:(BOOL)persistent {
    if ([NewRelicInternalUtils isInteger:number]) {
        return _analyticsController->incrementSessionAttribute([name UTF8String], (unsigned long long)[number integerValue],(bool)persistent); //has internal exception handling.
    } else if ([NewRelicInternalUtils isFloat:number]) {
    return _analyticsController->incrementSessionAttribute([name UTF8String], [number floatValue],(bool)persistent); //has internal exception handling.
    } else {
        return NO;
    }
}



- (NSString*) analyticsJSONString {
    try {
        auto events = _analyticsController->getEventsJSON(true);
        std::stringstream stream;
        stream <<std::setprecision(13)<< *events;
        return [NSString stringWithUTF8String:stream.str().c_str()];
    } catch (std::exception& e) {
        NRLOG_VERBOSE(@"Failed to generate event json: %s",e.what());
    } catch (...) {
        NRLOG_VERBOSE(@"Failed to generate event json");
    }
    return nil;
}

- (NSString*) sessionAttributeJSONString {
    try {
    auto attributes = _analyticsController->getSessionAttributeJSON();
    std::stringstream stream;
    stream <<std::setprecision(13)<<*attributes;
    return [NSString stringWithUTF8String:stream.str().c_str()];
    } catch (std::exception& e) {
        NRLOG_VERBOSE(@"Failed to generate attributes json: %s",e.what());
    } catch (...) {
        NRLOG_VERBOSE(@ "Failed to generate attributes json.");
    }
    return nil;
}
+ (NSString*) getLastSessionsAttributes {
    try {
    auto attributes = AnalyticsController::fetchDuplicatedAttributes([self attributeDupStore], YES);
    std::stringstream stream;
    stream << std::setprecision(13)<< *attributes;
    NSError* error;
    
    NSString* jsonString = [NSString stringWithUTF8String:stream.str().c_str()];
    if (!jsonString.length) {
        return nil;
    }
        return jsonString;
    } catch (std::exception& e) {
        NRLOG_VERBOSE(@"failed to generate session attribute json: %s", e.what());
    } catch (...) {
        NRLOG_VERBOSE(@"failed to generate session attribute json.");
    }
    return nil;
}
+ (NSString*) getLastSessionsEvents{
    try {
        auto events = AnalyticsController::fetchDuplicatedEvents([self eventDupStore], true);
        std::stringstream stream;
        stream << std::setprecision(13) << *events;
        NSError* error;
        
        NSString* jsonString = [NSString stringWithUTF8String:stream.str().c_str()];
        
        if (!jsonString.length) {
            return nil;
        }
        
        return jsonString;
    } catch (std::exception& e) {
        NRLOG_VERBOSE(@"Failed to fetch event dup store: %s",e.what());
        
    } catch (...) {
        NRLOG_VERBOSE(@"Failed to fetch event dup store.");
    }

    return nil;
    
}

+ (void) clearDuplicationStores
{
    try {
        [self attributeDupStore].clear();
        [self eventDupStore].clear();
    } catch (std::exception& e) {
        NRLOG_VERBOSE(@"Failed to clear dup stores: %s",e.what());
    } catch(...) {
        NRLOG_VERBOSE(@"Failed to clear dup stores.");
    }
}


- (void) clearLastSessionsAnalytics {
    try {
        _analyticsController->clearAttributesDuplicationStore();
        _analyticsController->clearEventsDuplicationStore();
    } catch (std::exception& e) {
        NRLOG_VERBOSE(@"Failed to clear last sessions' analytcs, %s",e.what());
    } catch (...) {
        NRLOG_VERBOSE(@"Failed to clear last sessions' analytcs.");
    }
}

//Harvest Aware methods

- (void) sessionWillEnd {
    _sessionWillEnd = YES;
    
    if([NRMAFlags shouldEnableGestureInstrumentation])
    {
        NRMAUserAction* backgroundGesture = [NRMAUserActionBuilder buildWithBlock:^(NRMAUserActionBuilder *builder) {
            [builder withActionType:kNRMAUserActionAppBackground];
        }];
        [[NewRelicAgentInternal sharedInstance].gestureFacade recordUserAction:backgroundGesture];
    }
    
    if(!_analyticsController->addSessionEndAttribute()) { //has exception handling within
        NRLOG_ERROR(@"failed to add session end attribute.");
    }

    if(!_analyticsController->addSessionEvent()) { //has exception handling within
        NRLOG_ERROR(@"failed to add a session event");
    }
    
}

- (void) onHarvestBefore {
    if (_sessionWillEnd || _analyticsController->didReachMaxEventBufferTime()) {
        
        NRMAHarvestableAnalytics* harvestableAnalytics = [[[NRMAHarvestableAnalytics alloc] initWithAttributeJSON:[self sessionAttributeJSONString]
                                                                                                        EventJSON:[self analyticsJSONString]]autorelease];

        [NRMAHarvestController addHarvestableAnalytics:harvestableAnalytics];
    }
}
@end
