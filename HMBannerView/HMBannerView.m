//
//  HMBannerView.m
//  HMBannerViewDemo
//
//  Created by Dennis on 13-12-31.
//  Copyright (c) 2013年 Babytree. All rights reserved.
//

#import "HMBannerView.h"

@interface HMBannerView ()
{
    // 下载统计
    NSInteger totalCount;
}

@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, assign) BOOL enableRolling;


- (void)refreshScrollView;

- (int)getPageIndex:(NSInteger)index;
- (NSArray *)getDisplayImagesWithPageIndex:(int)pageIndex;


@end

@implementation HMBannerView
@synthesize delegate;

@synthesize imagesArray;
@synthesize scrollDirection;

@synthesize pageControl;

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(rollingScrollAction) object:nil];
    [[SDWebImageManager sharedManager] cancelForDelegate:self];

    //[imagesArray release];
    //[pageControl release];

    //[super dealloc];
}

- (id)initWithFrame:(CGRect)frame scrollDirection:(BannerViewScrollDirection)direction images:(NSArray *)images
{
    self = [super initWithFrame:frame];

    if(self)
    {
        self.imagesArray = [[NSArray alloc] initWithArray:images];

        self.scrollDirection = direction;

        totalPage = imagesArray.count;
        totalCount = totalPage;
        // 显示的是图片数组里的第一张图片
        // 和数组是+1关系
        curPage = 1;

        scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        scrollView.backgroundColor = [UIColor clearColor];
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.pagingEnabled = YES;
        scrollView.delegate = self;
        [self addSubview:scrollView];
        
        // 在水平方向滚动
        if(scrollDirection == ScrollDirectionLandscape)
        {
            scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * 3,
                                                scrollView.frame.size.height);
        }
        // 在垂直方向滚动 
        else if(scrollDirection == ScrollDirectionPortait)
        {
            scrollView.contentSize = CGSizeMake(scrollView.frame.size.width,
                                                scrollView.frame.size.height * 3);
        }

        for (int i = 0; i < 3; i++)
        {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:scrollView.bounds];
            imageView.userInteractionEnabled = YES;
            imageView.tag = i+1;

            UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
            [imageView addGestureRecognizer:singleTap];

            // 水平滚动
            if(scrollDirection == ScrollDirectionLandscape)
            {
                imageView.frame = CGRectOffset(imageView.frame, scrollView.frame.size.width * i, 0);
            }
            // 垂直滚动
            else if(scrollDirection == ScrollDirectionPortait)
            {
                imageView.frame = CGRectOffset(imageView.frame, 0, scrollView.frame.size.height * i);
            }
            
            [scrollView addSubview:imageView];
        }

        self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(5, frame.size.height-15, 60, 15)];
        self.pageControl.numberOfPages = self.imagesArray.count;
        [self addSubview:self.pageControl];

        self.pageControl.currentPage = 0;
        //[self refreshScrollView];
    }
    
    return self;
}

- (void)reloadBannerWithData:(NSArray *)images
{
    self.imagesArray = [[NSArray alloc] initWithArray:images];

    totalPage = imagesArray.count;
    totalCount = totalPage;
    curPage = 1;

    [self startDownloadImage];
}

- (void)setSquare:(NSInteger)asquare
{
    if (scrollView)
    {
        scrollView.layer.cornerRadius = asquare;
        if (asquare == 0)
        {
            scrollView.layer.masksToBounds = NO;
        }
        else
        {
            scrollView.layer.masksToBounds = YES;
        }
    }
}

- (void)setPageControlStyle:(BannerViewPageStyle)pageStyle
{
    if (pageStyle == PageStyle_Left)
    {
        [self.pageControl setFrame:CGRectMake(5, self.bounds.size.height-15, 60, 15)];
    }
    else if (pageStyle == PageStyle_Right)
    {
        [self.pageControl setFrame:CGRectMake(self.bounds.size.width-5-60, self.bounds.size.height-15, 60, 15)];
    }
    else if (pageStyle == PageStyle_Middle)
    {
        [self.pageControl setFrame:CGRectMake((self.bounds.size.width-60)/2, self.bounds.size.height-15, 60, 15)];
    }
    else if (pageStyle == PageStyle_None)
    {
        [self.pageControl setHidden:YES];
    }
}

- (void)showClose:(BOOL)show
{
    if (show)
    {
        if (!BannerCloseButton)
        {
            BannerCloseButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [BannerCloseButton setFrame:CGRectMake(self.bounds.size.width-40, 0, 40, 40)];
            [BannerCloseButton setContentVerticalAlignment:UIControlContentVerticalAlignmentTop];
            [BannerCloseButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
            [BannerCloseButton addTarget:self action:@selector(closeBanner) forControlEvents:UIControlEventTouchUpInside];
            [BannerCloseButton setImage:[UIImage imageNamed:@"banner_close"] forState:UIControlStateNormal];
            [self addSubview:BannerCloseButton];
        }

        BannerCloseButton.hidden = NO;
    }
    else
    {
        if (BannerCloseButton)
        {
            BannerCloseButton.hidden = YES;
        }
    }
}

- (void)closeBanner
{
    if ([self.delegate respondsToSelector:@selector(bannerViewdidClosed:)])
    {
        [self.delegate bannerViewdidClosed:self];
    }
}

#pragma mark - Custom Method

- (void)startDownloadImage
{
    //取消已加入的延迟线程
    if (self.enableRolling)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(rollingScrollAction) object:nil];
    }

    [[SDWebImageManager sharedManager] cancelForDelegate:self];

    for (int i=0; i<self.imagesArray.count; ++i)
    {
        NSDictionary *dic = [self.imagesArray objectAtIndex:i];
        NSString *url = [dic objectForKey:@"img_url"];

        [[SDWebImageManager sharedManager] downloadWithURL:[NSURL URLWithString:url] delegate:self];
    }
}

- (void)refreshScrollView
{
    NSArray *curimageUrls = [self getDisplayImagesWithPageIndex:curPage];

    for (int i = 0; i < 3; i++)
    {
        UIImageView *imageView = (UIImageView *)[scrollView viewWithTag:i+1];
        NSDictionary *dic = [curimageUrls objectAtIndex:i];
        NSString *url = [dic objectForKey:@"img_url"];
        [imageView setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil];
    }

    // 水平滚动
    if (scrollDirection == ScrollDirectionLandscape)
    {
        [scrollView setContentOffset:CGPointMake(scrollView.frame.size.width, 0)];
    }
    // 垂直滚动
    else if (scrollDirection == ScrollDirectionPortait)
    {
        [scrollView setContentOffset:CGPointMake(0, scrollView.frame.size.height)];
    }

    self.pageControl.currentPage = curPage-1;
}

- (NSArray *)getDisplayImagesWithPageIndex:(int)page
{
    int pre = [self getPageIndex:curPage-1];
    int last = [self getPageIndex:curPage+1];
    
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:0];
    
    [images addObject:[imagesArray objectAtIndex:pre-1]];
    [images addObject:[imagesArray objectAtIndex:curPage-1]];
    [images addObject:[imagesArray objectAtIndex:last-1]];
    
    return images;
}

- (int)getPageIndex:(NSInteger)index
{
    // value＝1为第一张，value = 0为前面一张
    if (index == 0)
    {
        index = totalPage;
    }

    if (index == totalPage + 1)
    {
        index = 1;
    }
    
    return index;
}


#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
    int x = aScrollView.contentOffset.x;
    int y = aScrollView.contentOffset.y;
    //NSLog(@"did  x=%d  y=%d", x, y);

    //取消已加入的延迟线程
    if (self.enableRolling)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(rollingScrollAction) object:nil];
    }

    // 水平滚动
    if(scrollDirection == ScrollDirectionLandscape)
    {
        // 往下翻一张
        if (x >= 2 * scrollView.frame.size.width)
        {
            curPage = [self getPageIndex:curPage+1];
            [self refreshScrollView];
        }

        if (x <= 0)
        {
            curPage = [self getPageIndex:curPage-1];
            [self refreshScrollView];
        }
    }
    // 垂直滚动
    else if(scrollDirection == ScrollDirectionPortait)
    {
        // 往下翻一张
        if (y >= 2 * scrollView.frame.size.height)
        {
            curPage = [self getPageIndex:curPage+1];
            [self refreshScrollView];
        }

        if (y <= 0)
        {
            curPage = [self getPageIndex:curPage-1];
            [self refreshScrollView];
        }
    }

//    if ([delegate respondsToSelector:@selector(DJCycleScrollView:didScrollImageView:)])
//    {
//        [delegate DJCycleScrollView:self didScrollImageView:curPage];
//    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView
{
    //int x = aScrollView.contentOffset.x;
    //int y = aScrollView.contentOffset.y;
    
    //NSLog(@"--end  x=%d  y=%d", x, y);
    
    // 水平滚动
    if (scrollDirection == ScrollDirectionLandscape)
    {
        [scrollView setContentOffset:CGPointMake(scrollView.frame.size.width, 0) animated:YES];
    }
    // 垂直滚动
    else if (scrollDirection == ScrollDirectionPortait)
    {
        [scrollView setContentOffset:CGPointMake(0, scrollView.frame.size.height) animated:YES];
    }

    if (self.enableRolling)
    {
        [self performSelector:@selector(rollingScrollAction) withObject:nil afterDelay:self.rollingDelayTime];
    }
}


#pragma mark -
#pragma mark Rolling

- (void)startRolling
{
    if (![self.imagesArray isNotEmpty] || self.imagesArray.count == 1)
    {
        return;
    }

    [self stopRolling];

    self.enableRolling = YES;
    [self performSelector:@selector(rollingScrollAction) withObject:nil afterDelay:self.rollingDelayTime];
}

- (void)stopRolling
{
    self.enableRolling = NO;
    //取消已加入的延迟线程
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(rollingScrollAction) object:nil];
}

- (void)rollingScrollAction
{
    //NSLog(@"%@", NSStringFromCGPoint(scrollView.contentOffset));

    [UIView animateWithDuration:0.25 animations:^{
        // 水平滚动
        if(scrollDirection == ScrollDirectionLandscape)
        {
            scrollView.contentOffset = CGPointMake(1.99*scrollView.frame.size.width, 0);
        }
        // 垂直滚动
        else if(scrollDirection == ScrollDirectionPortait)
        {
            scrollView.contentOffset = CGPointMake(0, 1.99*scrollView.frame.size.height);
        }
        //NSLog(@"%@", NSStringFromCGPoint(scrollView.contentOffset));
    } completion:^(BOOL finished) {
        curPage = [self getPageIndex:curPage+1];
        [self refreshScrollView];

        if (self.enableRolling)
        {
            [self performSelector:@selector(rollingScrollAction) withObject:nil afterDelay:self.rollingDelayTime];
        }
    }];
}

#pragma mark - SDWebImageManager Delegate

- (void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image
{
    totalCount--;

    if (totalCount == 0)
    {
        curPage = 1;
        [self refreshScrollView];

        if ([self.delegate respondsToSelector:@selector(imageCachedDidFinish:)])
        {
            [self.delegate imageCachedDidFinish:self];
        }
    }
}


#pragma mark -
#pragma mark action

- (void)handleTap:(UITapGestureRecognizer *)tap
{
    if ([delegate respondsToSelector:@selector(bannerView:didSelectImageView:withData:)])
    {
        [delegate bannerView:self didSelectImageView:curPage-1 withData:[self.imagesArray objectAtIndex:curPage-1]];
    }
}

@end
