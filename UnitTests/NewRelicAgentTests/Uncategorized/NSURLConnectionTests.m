//
//  NSURLConnectionTests.m
//  NewRelicAgent
//
//  Created by Saxon D'Aubin on 9/11/12.
//
//

#import "NSURLConnectionTests.h"

@implementation NSURLConnectionTests


- (void)testSendSynchronousRequest__noSideEffect
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com"]];
    NSURLResponse* response = nil;
    NSError* error = (NSError*)@"NoSideEffect";
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    NSString* errorStr = (NSString*) error;
    XCTAssertTrue([errorStr isEqualToString:@"NoSideEffect"], @"%@",error.description);
    XCTAssertNotNil(data, @"");
}

- (void)testSendSynchronousRequest__nilError
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://wwwgooglecom.bad.hostname"]];
    NSURLResponse* response = nil;
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    XCTAssertNil(data, @""); 
}

-(void)testConnectionHandlesCancel
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://news.ycombinator.com/"]];
    NSURLConnection *conn = [NSURLConnection connectionWithRequest:request delegate:self];
    [conn start];

    XCTAssertNoThrow([conn cancel], @"cancel should not blow up");
}

@end
