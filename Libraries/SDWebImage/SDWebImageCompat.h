/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Jamie Pinkham
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TargetConditionals.h>
// add by DJ
#import "UIImage+MultiFormat.h"

#if !TARGET_OS_IPHONE
#import <AppKit/AppKit.h>
#ifndef UIImage
#define UIImage NSImage
#endif
#ifndef UIImageView
#define UIImageView NSImageView
#endif
#else
#import <UIKit/UIKit.h>
#endif

#if ! __has_feature(objc_arc)
#define SDWIAutorelease(__v) ([__v autorelease]);
#define SDWIReturnAutoreleased SDWIAutorelease

#define SDWIRetain(__v) ([__v retain]);
#define SDWIReturnRetained SDWIRetain

#define SDWIRelease(__v) ([__v release]);
#define SDWISafeRelease(__v) ([__v release], __v = nil);
#define SDWISuperDealoc [super dealloc];

#define SDWIWeak
#else
// -fobjc-arc
#define SDWIAutorelease(__v)
#define SDWIReturnAutoreleased(__v) (__v)

#define SDWIRetain(__v)
#define SDWIReturnRetained(__v) (__v)

#define SDWIRelease(__v)
#define SDWISafeRelease(__v) (__v = nil);
#define SDWISuperDealoc

#define SDWIWeak __unsafe_unretained
#endif

// add by DJ
enum SDImageType
{
    SDImageType_NONE = -1,
    SDImageType_BMP = 0,
    SDImageType_JPEG,
    SDImageType_GIF,
    SDImageType_PCX,
    SDImageType_PNG,
    SDImageType_PSD,
    SDImageType_RAS,
    SDImageType_SGI,
    SDImageType_TIFF
};

NS_INLINE NSInteger SDgetImageType(NSData *image)
{
    NSInteger Result;
    NSInteger head;
    
    if ([image length] <= 2)
    {
        return SDImageType_NONE;
    }
    
    [image getBytes:&head range:NSMakeRange(0, 2)];
    
    head = head & 0x0000FFFF;
    //NSLog(@"%d, %x", head, head);
    switch (head)
    {
        case 0x4D42:
            Result = SDImageType_BMP;
            break;
            
        case 0xD8FF:
            Result = SDImageType_JPEG;
            break;
            
        case 0x4947:
            Result = SDImageType_GIF;
            break;
            
        case 0x050A:
            Result = SDImageType_PCX;
            break;
            
        case 0x5089:
            Result = SDImageType_PNG;
            break;
            
        case 0x4238:
            Result = SDImageType_PSD;
            break;
            
        case 0xA659:
            Result = SDImageType_RAS;
            break;
            
        case 0xDA01:
            Result = SDImageType_SGI;
            break;
            
        case 0x4949:
            Result = SDImageType_TIFF;
            break;
            
        default:
            Result = SDImageType_NONE;
            break;
    }
    
    return Result;
}
// end by DJ

NS_INLINE UIImage *SDScaledImageForPath(NSString *path, NSObject *imageOrData)
{
    if (!imageOrData)
    {
        return nil;
    }

    UIImage *image = nil;
    if ([imageOrData isKindOfClass:[NSData class]])
    {
// add by DJ
        if (SDImageType_NONE == SDgetImageType((NSData *)imageOrData))
        {
            return nil;
        }
        image = [UIImage sd_imageWithData:(NSData *)imageOrData];
// end by DJ
        //image = [[UIImage alloc] initWithData:(NSData *)imageOrData];
    }
    else if ([imageOrData isKindOfClass:[UIImage class]])
    {
        image = SDWIReturnRetained((UIImage *)imageOrData);
    }
    else
    {
        return nil;
    }

    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
    {
        CGFloat scale = 1.0;
        if (path.length >= 8)
        {
            // Search @2x. at the end of the string, before a 3 to 4 extension length (only if key len is 8 or more @2x. + 4 len ext)
            NSRange range = [path rangeOfString:@"@2x." options:0 range:NSMakeRange(path.length - 8, 5)];
            if (range.location != NSNotFound)
            {
                scale = 2.0;
            }
        }

        UIImage *scaledImage = [[UIImage alloc] initWithCGImage:image.CGImage scale:scale orientation:image.imageOrientation];
        SDWISafeRelease(image)
        image = scaledImage;
    }

    return SDWIReturnAutoreleased(image);
}
