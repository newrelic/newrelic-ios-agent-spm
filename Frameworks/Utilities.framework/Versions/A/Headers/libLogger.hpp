//
// Created by Bryce Buchanan on 1/4/16.
//

#ifndef LIBMOBILEAGENT_LIBLOGGER_HPP
#define LIBMOBILEAGENT_LIBLOGGER_HPP
#include "Utilities/LoggerBridge.hpp"
#include <memory>


#define __FILENAME__ (strrchr(__FILE__, '/') != NULL ? strrchr(__FILE__, '/') + 1 : __FILE__)


namespace NewRelic {
    class LibLogger {
    public:
        //this enum mimics the enum defined in the iOS agent for logging.
        enum LLogLevel {
            LLogLevelNone    = 0,
            LLogLevelError   = 1 << 0,
            LLogLevelWarning = 1 << 1,
            LLogLevelInfo    = 1 << 2,
            LLogLevelVerbose = 1 << 3,
            LLogLevelAudit = 1 << 4,
            LLogLevelAll     = 0xffff
        };

        static void log(enum LLogLevel level,
                        const char* file,
                        unsigned line,
                        const char* method,
                        const char* format,
                        ...);

        static void setLogger(std::shared_ptr<LoggerBridge> bridge);
    };

#define LLOG(level, format, ...) \
    LibLogger::log(level,__FILENAME__ ,__LINE__,__FUNCTION__,format, ##__VA_ARGS__)

#define LLOG_ERROR(format,...) LLOG(LibLogger::LLogLevel::LLogLevelError,format, ##__VA_ARGS__)
#define LLOG_WARNING(format,...) LLOG(LibLogger::LLogLevel::LLogLevelWarning, format, ##__VA_ARGS__)
#define LLOG_INFO(format,...) LLOG(LibLogger::LLogLevel::LLogLevelInfo, format, ##__VA_ARGS__)
#define LLOG_VERBOSE(format,...) LLOG(LibLogger::LLogLevel::LLogLevelVerbose, format, ##__VA_ARGS__)
#define LLOG_AUDIT(format,...) LLOG(LibLogger::LLogLevel::LLogLevelAudit, format, ##__VA_ARGS__)
}


#endif //LIBMOBILEAGENT_LIBLOGGER_HPP
