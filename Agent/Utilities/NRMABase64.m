//
//  NRMABase64.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 4/29/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMABase64.h"
#import "NRLogger.h"
static const char* base64Key = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
@implementation NRMABase64

#define kNRTOP_2_BIT_MASK 0x30
#define kNRTOP_4_BIT_MASK 0x3D
#define kNRBTM_2_BIT_MASK 0x03
#define kNRBTM_4_BIT_MASK 0x0F
#define kNRBTM_6_BIT_MASK 0x3F

+ (NSString*) encodeFromData:(NSData*)data
{
    NSMutableString* encodedString = [[NSMutableString alloc] init];

    NSInputStream* dataStream =[NSInputStream inputStreamWithData:data];
    [dataStream open];
    /*
     *  Loop over the bytes in dataStream and base 64-ecode them
     *  6 bits per base64 character, 3 bytes of data to 4 bytes of base64,
     *  requires shifting bits around.
     */
    while (dataStream.hasBytesAvailable) {
        uint8_t byteArray[3] = {0,0,0};
        NSInteger bytesRead = [dataStream read:byteArray maxLength:3];
        if (bytesRead < 0) {
            NRLOG_VERBOSE(@"Base64 encoding failed.");
            return nil;
        } else if (bytesRead > 0) {
            // calculate the 1 base64 character
            unsigned int charIndex = [self generateIndexForFirstBase64Char:byteArray[0]];
            [encodedString appendFormat:@"%c",base64Key[charIndex]]; //first base64 char

            if (bytesRead > 1) {
                // get the last 4 bits of the second cahracter
                //and or them with the first 2 bits
                charIndex = [self generateIndexForSecondBase64Char:byteArray[0] secondByte:byteArray[1]];
                [encodedString appendFormat:@"%c",base64Key[charIndex]]; //second base 64 char

                if (bytesRead > 2) { 
                    //fetch the bottom 2 bits for the 3rd character and add them to
                    //the top 4 bits (in charIndex)
                    charIndex = [self generateIndexForThirdBase64Char:byteArray[1] thirdByte:byteArray[2]];
                    [encodedString appendFormat:@"%c",base64Key[charIndex]]; //3rd base64 character

                    //mask out the final base64 character (4th base63 character)
                    charIndex = [self generateindexForFourthBase64Char:byteArray[2]];
                    [encodedString appendFormat:@"%c",base64Key[charIndex]];// 4th base64 character;
                } else {
                    charIndex = [self generateIndexForThirdBase64Char:byteArray[1] thirdByte:0];
                    [encodedString appendFormat:@"%c=",base64Key[charIndex]]; //write the 3rd character and fill the empty data from the missing final byte with an =
                }
            } else {
                //we've reached this end replace the data from the empty 2 bytes with "=="
                charIndex = [self generateIndexForSecondBase64Char:byteArray[0] secondByte:0];
                [encodedString appendFormat:@"%c==",base64Key[charIndex]];
            }

        }
    }

    [dataStream close];
    dataStream = nil;
    
    return encodedString;
}

+ (unsigned int) generateIndexForFirstBase64Char:(uint8_t)firstByte
{
    //return between 0000 0000 and 0011 1111
    //this should never return anything over 0x0011 1111
    return firstByte >> 2 & kNRBTM_6_BIT_MASK;
}

+ (unsigned int) generateIndexForSecondBase64Char:(uint8_t)firstByte secondByte:(uint8_t)secondbyte
{
    // firstbyte produces  0x00 - 0x30
    //secondbyte produces 0x00 - 0x0F;
    // combined max of 0x00 - 0x3F
    unsigned int index = firstByte << 4 & kNRTOP_2_BIT_MASK;
    return index | ((secondbyte >> 4) & kNRBTM_4_BIT_MASK);
}

+ (unsigned int) generateIndexForThirdBase64Char:(uint8_t)secondByte thirdByte:(uint8_t)thirdByte
{
    unsigned int index = secondByte << 2 & kNRTOP_4_BIT_MASK;

    return index | ((thirdByte >> 6) & kNRBTM_2_BIT_MASK);
}

+ (unsigned int) generateindexForFourthBase64Char:(uint8_t)thirdByte
{
    return thirdByte & kNRBTM_6_BIT_MASK;
}

//for test
+ (const char*) base64LookupTable
{
    return base64Key;
}
@end
