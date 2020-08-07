//
//  NRMAUserActionFacade.h
//  NewRelicAgent
//

#import "NRMAUserAction.h"
#import "NRMAAnalytics.h"

@interface NRMAUserActionFacade : NSObject

-(instancetype) initWithAnalyticsController:(NRMAAnalytics*)analytics;
-(void)recordUserAction:(NRMAUserAction*)userAction;

@end

