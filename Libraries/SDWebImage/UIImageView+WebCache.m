/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImageView+WebCache.h"
#import <ImageIO/ImageIO.h>
#import "UIImage+GIF.h"


#define TAG_ACTIVITY_INDICATOR 149462

@implementation UIImageView (WebCache)

- (void)setImageWithURL:(NSURL *)url
{
    [self setImageWithURL:url placeholderImage:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder
{
    [self setImageWithURL:url placeholderImage:placeholder options:0];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options
{
    SDWebImageManager *manager = [SDWebImageManager sharedManager];

    // Remove in progress downloader from queue
    [manager cancelForDelegate:self];

    self.image = placeholder;

    if (url)
    {
        [manager downloadWithURL:url delegate:self options:options];
    }
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options usingActivityIndicatorStyle:(UIActivityIndicatorViewStyle)activityStyle
{
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    
    // Remove in progress downloader from queue
    [manager cancelForDelegate:self];
    
    self.image = placeholder;
    
    if (url)
    {
        UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[self viewWithTag:TAG_ACTIVITY_INDICATOR];
        
        if (activityIndicator == nil)
        {
            activityIndicator = SDWIReturnAutoreleased([[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:activityStyle]);
            
            //calculate the correct position
            float width = activityIndicator.frame.size.width;
            float height = activityIndicator.frame.size.height;
            float x = (self.frame.size.width / 2.0) - width/2;
            float y = (self.frame.size.height / 2.0) - height/2;
            activityIndicator.frame = CGRectMake(x, y, width, height);
            
            activityIndicator.userInteractionEnabled = NO;
            activityIndicator.hidesWhenStopped = YES;
            activityIndicator.tag = TAG_ACTIVITY_INDICATOR;
            [self addSubview:activityIndicator];
        }
        
        [activityIndicator startAnimating];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:activityIndicator forKey:@"activityKey"];
        [manager downloadWithURL:url delegate:self options:options userInfo:userInfo];
    }
}

#if NS_BLOCKS_AVAILABLE
- (void)setImageWithURL:(NSURL *)url success:(SDWebImageSuccessBlock)success failure:(SDWebImageFailureBlock)failure;
{
    [self setImageWithURL:url placeholderImage:nil success:success failure:failure];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder success:(SDWebImageSuccessBlock)success failure:(SDWebImageFailureBlock)failure;
{
    [self setImageWithURL:url placeholderImage:placeholder options:0 success:success failure:failure];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options success:(SDWebImageSuccessBlock)success failure:(SDWebImageFailureBlock)failure;
{
    [self setImageWithURL:url placeholderImage:placeholder options:options progress:nil success:success failure:failure];
}

// add by DJ
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageProgressBlock)progress success:(SDWebImageSuccessBlock)success failure:(SDWebImageFailureBlock)failure;
{
    SDWebImageManager *manager = [SDWebImageManager sharedManager];

    // Remove in progress downloader from queue
    [manager cancelForDelegate:self];

    self.image = placeholder;

    if (url)
    {
        [manager downloadWithURL:url delegate:self options:options progress:progress success:success failure:failure];
    }
}
#endif

- (void)cancelCurrentImageLoad
{
    @synchronized(self)
    {
        [[SDWebImageManager sharedManager] cancelForDelegate:self];
    }
}

- (void)webImageManager:(SDWebImageManager *)imageManager didProgressWithPartialImage:(UIImage *)image forURL:(NSURL *)url
{
    self.image = image;
    [self setNeedsLayout];
}

//- (void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image
//{
//    self.image = image;
//    [self setNeedsLayout];
//}


- (void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image forURL:(NSURL *)url userInfo:(NSDictionary *)info
{
    self.image = image;

    [self removeAvtivityViewWithUserInfo:info];
    
    [self setNeedsLayout];
}

- (void)webImageManager:(SDWebImageManager *)imageManager didFailWithError:(NSError *)error forURL:(NSURL *)url userInfo:(NSDictionary *)info;
{
    [self removeAvtivityViewWithUserInfo:info];
}

- (void)removeAvtivityViewWithUserInfo:(NSDictionary *)info
{
    if ([info isNotEmpty])
    {
        UIView *activityIndicatorView = [info objectForKey:@"activityKey"];
        
        if (activityIndicatorView != nil)
        {
            if ([activityIndicatorView isKindOfClass:[UIActivityIndicatorView class]])
            {
                UIActivityIndicatorView *activity = (UIActivityIndicatorView *)activityIndicatorView;
                [activity stopAnimating];
            }
            [activityIndicatorView removeFromSuperview];
        }
        else
        {
            NSArray *array = [self subviews];
            for (UIView *view in array)
            {
                if ([view isKindOfClass:[UIActivityIndicatorView class]])
                {
                    UIActivityIndicatorView *activity = (UIActivityIndicatorView *)view;
                    [activity stopAnimating];
                    
                    [view removeFromSuperview];
                }
            }
        }
    }
}

@end
