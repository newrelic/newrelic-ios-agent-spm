//
// Created by Bryce Buchanan on 1/4/16.
//

#ifndef LIBMOBILEAGENT_LOGGERBRIDGE_HPP
#define LIBMOBILEAGENT_LOGGERBRIDGE_HPP

#include <stdarg.h>

namespace NewRelic {
    class LoggerBridge {
    public:
        virtual void log(unsigned int level,
                        const char* file,
                        unsigned int line,
                        const char* method,
                        const char* format,
                        va_list args) = 0;
    };

    class DefaultLogger : public LoggerBridge {
    public:
        void log(unsigned int level,
                 const char* file,
                 unsigned int line,
                 const char* method,
                 const char* format,
                 va_list args) override;

        virtual ~DefaultLogger() ;
    };
}


#endif //LIBMOBILEAGENT_LOGGERBRIDGE_HPP
