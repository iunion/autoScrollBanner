//
//  ViewController.h
//  autoScrollBannerDemo
//
//  Created by mac on 14-2-11.
//  Copyright (c) 2014年 DJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HMBannerView.h"

@interface ViewController : UIViewController
<
    HMBannerViewDelegate
>

// Banner
@property (nonatomic, strong) HMBannerView *bannerView;

@end
