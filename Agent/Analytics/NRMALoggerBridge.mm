//
//  NRMALoggerBridge.cpp
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/6/16.
//  Copyright © 2016 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "NRMALoggerBridge.hpp"
#include <stdarg.h>
#include <stdio.h>
#import "NRLogger.h"
namespace  NewRelic {
    
    void NRMALoggerBridge::log(unsigned int level,
                               const char* file,
                               unsigned int line,
                               const char* method,
                               const char* format,
                               va_list args) {


        //check file non-null
        if (file == nullptr || strlen(file) == 0) {
            file = "?";
        }

        //check method non-null
        if (method == nullptr || strlen(method) == 0) {
            method = "?";
        }

        //check format not null
        if (format == nullptr || strlen(format) == 0) {
            //can't write anything :P
            return;
        }

        va_list v2;

        va_copy(v2, args);

        int size = vsnprintf(NULL, 0, format, args);

        if (size < 0) return; //vsnprintf returns -1 if an error occurs.

        char buf[size+1];



        vsnprintf(buf, sizeof(buf), format, v2);

        va_end(v2);



        [NRLogger log:level
               inFile:[NSString stringWithUTF8String:file]
               atLine:line
             inMethod:[NSString stringWithUTF8String:method]
          withMessage:[NSString stringWithUTF8String:buf]];
    }
}
