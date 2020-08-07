//
//  NRMALoggerBridge.hpp
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/6/16.
//  Copyright © 2016 New Relic. All rights reserved.
//

#ifndef NRMALoggerBridge_hpp
#define NRMALoggerBridge_hpp

#include <Utilities/LoggerBridge.hpp>
namespace NewRelic {
    class NRMALoggerBridge : public LoggerBridge {
        
        virtual void log(unsigned int level,
                         const char* file,
                         unsigned int line,
                         const char* method,
                         const char* format,
                         va_list args) override;
    };
}

#endif /* NRMALoggerBridge_hpp */
