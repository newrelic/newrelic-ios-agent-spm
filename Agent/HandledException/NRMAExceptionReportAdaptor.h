//
// Created by Bryce Buchanan on 7/6/17.
// Copyright (c) 2017 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <Hex/Report/HexReport.hpp>

@interface NRMAExceptionReportAdaptor : NSObject
{
    std::shared_ptr<NewRelic::Hex::Report::HexReport> _report;
}

- (instancetype) initWithReport:(std::shared_ptr<NewRelic::Hex::Report::HexReport>) report;

- (void) addAttributes:(NSDictionary*)attributes;
- (std::shared_ptr<NewRelic::Hex::Report::HexReport>) report;

@end
