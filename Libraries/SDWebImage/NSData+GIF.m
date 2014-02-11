//
//  NSData+GIF.m
//  SDWebImage
//
//  Created by Andy LaVoy on 4/28/13.
//  Copyright (c) 2013 Dailymotion. All rights reserved.
//

#import "NSData+GIF.h"

@implementation NSData (GIF)

- (BOOL)sd_isGIF
{
    BOOL isGIF = NO;
    
    uint8_t c;
    [self getBytes:&c length:1];
    
    switch (c)
    {
        case 0x47:  // probably a GIF
            isGIF = YES;
            break;
        default:
            break;
    }
    
    return isGIF;
}

@end



@implementation NSObject (Category)

- (BOOL)isValided
{
    return !(self == nil || [self isKindOfClass:[NSNull class]]);
}

- (BOOL)isNotNSNull
{
	return ![self isKindOfClass:[NSNull class]];
}

- (BOOL)isEmpty
{
    return (self == nil
            || [self isKindOfClass:[NSNull class]]
            || ([self respondsToSelector:@selector(length)]
                && [(NSData *)self length] == 0)
            || ([self respondsToSelector:@selector(count)]
                && [(NSArray *)self count] == 0));
}

- (BOOL)isNotEmpty
{
    return !(self == nil
             || [self isKindOfClass:[NSNull class]]
             || ([self respondsToSelector:@selector(length)]
                 && [(NSData *)self length] == 0)
             || ([self respondsToSelector:@selector(count)]
                 && [(NSArray *)self count] == 0));
}


- (BOOL)isNotEmptyDictionary
{
    if ([self isNotEmpty])
    {
        return [self isKindOfClass:[NSDictionary class]];
    }

    return NO;
}

@end
