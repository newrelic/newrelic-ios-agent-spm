#ifndef __CONSTANTS_H_
#define __CONSTANTS_H_
//reserved attributes
extern const char* __kNRMA_RA_eventType;
extern const char* __kNRMA_RA_type;
extern const char* __kNRMA_RA_timestamp;
extern const char* __kNRMA_RA_category;
extern const char* __kNRMA_RA_accountId;
extern const char* __kNRMA_RA_appId;
extern const char* __kNRMA_RA_appName;
extern const char* __kNRMA_RA_uuid;
extern const char* __kNRMA_RA_sessionDuration;
extern const char* __kNRMA_RA_osName;
extern const char* __kNRMA_RA_osVersion;
extern const char* __kNRMA_RA_osMajorVersion;
extern const char* __kNRMA_RA_deviceManufacturer;
extern const char* __kNRMA_RA_deviceModel;
extern const char* __kNRMA_RA_carrier;
extern const char* __kNRMA_RA_newRelicVersion;
extern const char* __kNRMA_RA_memUsageMb;
extern const char* __kNRMA_RA_sessionId;
extern const char* __kNRMA_RA_install;
extern const char* __kNRMA_RA_upgradeFrom;
extern const char* __kNRMA_RA_platform;
extern const char* __kNRMA_RA_platformVersion;
extern const char* __kNRMA_RA_lastInteraction;
extern const char* __kNRMA_RA_appDataHeader;
extern const char* __kNRMA_RA_responseBody;

//reserved mobile eventTypes
extern const char* __kNRMA_RET_mobile;
extern const char* __kNRMA_RET_mobileSession;
extern const char* __kNRMA_RET_mobileRequest;
extern const char* __kNRMA_RET_mobileRequestError;
extern const char* __kNRMA_RET_mobileCrash;
extern const char* __kNRMA_RET_mobileBreadcrumb;
extern const char* __kNRMA_RET_mobileUserAction;

// Gesture attributes (not reserved)
extern const char* __kNRMA_RA_methodExecuted;
extern const char* __kNRMA_RA_targetObject;
extern const char* __kNRMA_RA_label;
extern const char* __kNRMA_RA_accessibility;
extern const char* __kNRMA_RA_touchCoordinates;
extern const char* __kNMRA_RA_actionType;
extern const char* __kNRMA_RA_frame;
extern const char* __kNRMA_RA_orientation;
//reserved prefix
extern const char* __kNRMA_RP_newRelic;
extern const char* __kNRMA_RP_nr;


//Intrinsic Event Attributes (not reserved)
extern const char*  __kNRMA_Attrib_guid;
extern const char*  __kNRMA_Attrib_traceId;
extern const char*  __kNRMA_Attrib_parentId;


//Request Event Attributes (not reserved)
extern const char* __kNRMA_Attrib_connectionType;
extern const char* __kNRMA_Attrib_requestUrl;
extern const char* __kNRMA_Attrib_requestDomain;
extern const char* __kNRMA_Attrib_requestPath;
extern const char* __kNRMA_Attrib_requestMethod;
extern const char* __kNRMA_Attrib_bytesReceived;
extern const char* __kNRMA_Attrib_bytesSent;
extern const char* __kNRMA_Attrib_responseTime;
extern const char* __kNRMA_Attrib_statusCode;
extern const char* __kNRMA_Attrib_networkErrorCode;
extern const char* __kNRMA_Attrib_networkError;
extern const char* __kNRMA_Attrib_errorType;
extern const char* __kNRMA_Attrib_contentType;

extern const char* __kNRMA_Val_errorType_HTTP;
extern const char* __kNRMA_Val_errorType_Network;

#endif
