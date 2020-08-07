/*
 
 File: Reachability.m
 Abstract: Basic demonstration of how to use the SystemConfiguration Reachablity APIs.
 
 Version: 2.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple Software"), to
 use, reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions
 of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may be used
 to endorse or promote products derived from the Apple Software without specific
 prior written permission from Apple.  Except as expressly stated in this notice,
 no other rights or licenses, express or implied, are granted by Apple herein,
 including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be
 incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
 DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
 CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
 APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

#import <CoreFoundation/CoreFoundation.h>

#import "NRMAExceptionDataCollectionWrapper.h"
#import "NRMAReachability.h"
#import "NRLogger.h"
#import "NRConstants.h"

@interface NRMAReachability ()
#if !TARGET_OS_TV
@property(strong, atomic) CTTelephonyNetworkInfo *networkInfo;
#endif
@end

@implementation NRMAReachability


- (instancetype)init {
    self = [super init];
    if (self) {
#if !TARGET_OS_TV
        self.networkInfo = [CTTelephonyNetworkInfo new];
        if ([self.networkInfo respondsToSelector:@selector(currentRadioAccessTechnology)]) {
            [self setCurrentWanNetworkType:self.networkInfo.currentRadioAccessTechnology];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(radioAccessDidChange:)
                                                         name:CTRadioAccessTechnologyDidChangeNotification
                                                       object:nil];
        }
#endif
    }
    return self;
}

- (void)radioAccessDidChange:(NSNotification *)notif {
#if !TARGET_OS_TV
    if ([self.networkInfo respondsToSelector:@selector(currentRadioAccessTechnology)]) {
        _wanNetworkType = self.networkInfo.currentRadioAccessTechnology;
    }
#endif
}

#if !TARGET_OS_TV
- (CTCarrier*) getCarrierInfo {
    return self.networkInfo.subscriberCellularProvider;
}
#endif
- (void)setCurrentWanNetworkType:(NSString *)radioAccessTech {
    @synchronized (_wanNetworkType) {
        _wanNetworkType = radioAccessTech;
    }
}

- (NSString *)getCurrentWanNetworkType:(NRMANetworkStatus)networkStatus
{
#if !TARGET_OS_TV
    @synchronized (_wanNetworkType) {
        if (networkStatus != ReachableViaWWAN) {
            return nil;
        }
        
        if ([self.networkInfo respondsToSelector:@selector(currentRadioAccessTechnology)]) {
            if ([_wanNetworkType isEqualToString:CTRadioAccessTechnologyGPRS]) {return @"GPRS";}
            
            if ([_wanNetworkType isEqualToString:CTRadioAccessTechnologyEdge]) {return @"EDGE";}
            
            if ([_wanNetworkType isEqualToString:CTRadioAccessTechnologyWCDMA]) {return @"WCDMA";}
            
            if ([_wanNetworkType isEqualToString:CTRadioAccessTechnologyHSDPA]) {return @"HSDPA";}
            
            if ([_wanNetworkType isEqualToString:CTRadioAccessTechnologyHSUPA]) {return @"HSUPA";}
            
            if ([_wanNetworkType isEqualToString:CTRadioAccessTechnologyCDMA1x]) {return @"CDMA";}
            
            if ([_wanNetworkType isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]) {return @"EVDO rev 0";}
            
            if ([_wanNetworkType isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]) {return @"EVDO rev A";}
            
            if ([_wanNetworkType isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]) {return @"EVDO rev B";}
            
            if ([_wanNetworkType isEqualToString:CTRadioAccessTechnologyeHRPD]) {return @"HRPD";}
            
            if ([_wanNetworkType isEqualToString:CTRadioAccessTechnologyLTE]) {return @"LTE";}
        }
    }
#endif
    return @"unknown"; //_wanNetworkType didn't equal any of the expected Technologies,
    //or currentRadioAccessTechnology  isn't available.
}


- (void)dealloc {
    if (reachabilityRef != NULL) {
        CFRelease(reachabilityRef);
    }
}


+ (NRMAReachability*)reachability
{
    NRMAReachability* retVal = NULL;
    
    struct addrinfo hints;
    struct addrinfo* result;
    int error = 0;
    
    memset(&hints, 0, sizeof(struct addrinfo));
    hints.ai_family = AF_UNSPEC; //using this should result in either a family of AF_INET or AF_INET6.
    hints.ai_socktype = SOCK_DGRAM;
    hints.ai_flags = AI_PASSIVE;
    hints.ai_protocol = 0;
    hints.ai_canonname = NULL;
    hints.ai_addr = NULL;
    hints.ai_next = NULL;
    
    //passing NULL as the node to getaddrinfo() results in using the link local address.
    error = getaddrinfo(NULL, "80", &hints, &result);
    if ( error != 0 ) {
        //error
        NRLOG_VERBOSE(@"Reachability failed with error: \"%s\". New Relic may be unable to get details regarding network connectivity and carrier information.",gai_strerror(error));
        return retVal;
    }
    
    SCNetworkReachabilityRef reachability = NULL;
    
    //detect if we are using IPv4 or IPv6
    if (result->ai_family != AF_INET && result->ai_family != AF_INET6 ) {
        freeaddrinfo(result);
        NRLOG_VERBOSE(@"Reachability recieved an unexpected ai family. New Relic may be unable to get details regarding network connectivity and carrier information.");
        return retVal;
    }
    // the Apple recommended method, SCNetworkReqchabilityCreateWithName(),
    // makes a DNS request which will block while the request occurs.
    // SCNetworkReqchabilityCreateWithAddress gets us all the information we need
    // and won't block when there is a poor network qaulity.
    reachability = SCNetworkReachabilityCreateWithAddress(NULL, (const struct sockaddr*)result->ai_addr);
    
    if (reachability != NULL) {
        retVal = [[self alloc] init];
        if (retVal != NULL) {
            retVal->reachabilityRef = reachability;
        }
    }
    
    freeaddrinfo(result);
    return retVal;
}

- (BOOL) connectionRequired
{
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
    {
        return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
    }
    return NO;
}

#pragma mark Wan Data


#pragma mark Network Flag Handling

- (NRMANetworkStatus)networkStatusForFlags:(SCNetworkReachabilityFlags)flags {
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
        // if target host is not reachable
        return NotReachable;
    }
    
    NRMANetworkStatus retVal = NotReachable;
    
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
        // if target host is reachable and no connection is required
        //  then we'll assume (for now) that your on Wi-Fi
        retVal = ReachableViaWiFi;
    }
    
    
    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
        // ... and the connection is on-demand (or on-traffic) if the
        //     calling application is using the CFSocketStream or higher APIs
        
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
            // ... and no [user] intervention is needed
            retVal = ReachableViaWiFi;
        }
    }
    
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
        // ... but WWAN connections are OK if the calling application
        //     is using the CFNetwork (CFSocketStream?) APIs.
        retVal = ReachableViaWWAN;
    }
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNRNetworkStatusDidChangeNotification object:[NSNumber numberWithInt:retVal]];
    
    return retVal;
}


- (NRMANetworkStatus)currentReachabilityStatus {
    //	NSAssert(reachabilityRef != NULL, @"currentNetworkStatus called with NULL reachabilityRef");
    NRMANetworkStatus retVal = NotReachable;
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
        retVal = [self networkStatusForFlags:flags];
    }
    return retVal;
}


@end
