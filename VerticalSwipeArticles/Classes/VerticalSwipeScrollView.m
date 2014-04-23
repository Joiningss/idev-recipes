//
//  VerticalSwipeScrollView.m
//  VerticalSwipeArticles
//
//  Created by Peter Boctor on 12/26/10.
//
// Copyright (c) 2011 Peter Boctor
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE
//

// Refactor by Joiningss on 04/22/14.
//
// Copyright (c) 2014 Joiningss

#import "VerticalSwipeScrollView.h"
#import "FTAnimation.h"
@interface VerticalSwipeScrollView()

@property(nonatomic, assign) CGSize contentSize;
@property(nonatomic, assign) BOOL alwaysBounceVertical;
@property(nonatomic, assign) UIEdgeInsets contentInset;
@property(nonatomic, assign) BOOL headerLoaded;
@property(nonatomic, assign) BOOL footerLoaded;
@property (nonatomic, strong) UIWebView* latestPageView;
@end

@interface VerticalSwipeScrollView (PrivateMethods)
- (void) showCurrentPage;
@end

@implementation VerticalSwipeScrollView

//disable setup by interface file.Joiningss

//// Setup for when our view is setup in a NIB
//- (void)awakeFromNib
//{
//    self.contentSize = self.frame.size;
//    [self showCurrentPage];
//}
//
//// Setup for default init method
//- (id)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self)
//    {
//        [self showCurrentPage];
//        self.contentSize = self.frame.size;
//    }
//    return self;
//}

// Setup for init method with explicit values
- (id) initWithFrame:(CGRect)frame contentInset:(UIEdgeInsets)contentInset startingAt:(NSUInteger)pageIndex delegate:(id<VerticalSwipeScrollViewDelegate,UIScrollViewDelegate>)verticalSwipeDelegate
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.alwaysBounceVertical = YES;
        self.delegate = verticalSwipeDelegate;
        self.currentPageIndex = pageIndex;
        self.contentInset = contentInset;
        self.contentSize = CGSizeMake(CGRectGetWidth(self.frame)-contentInset.left-contentInset.right, CGRectGetHeight(self.frame)-contentInset.top-contentInset.bottom);
        [self showCurrentPage];
    }
    return self;
}

// We override setting the delegate and:
// 1. make ourselves the delegate instead
// 2. remember the actual delegate and properly forward messages to it
-(void) setDelegate:(id<VerticalSwipeScrollViewDelegate>)newDelegate
{
    if (newDelegate != (id<VerticalSwipeScrollViewDelegate>)self)
        self.externalDelegate = newDelegate;
    //[super setDelegate:self];
}

// Ask the delegate for the current page and show it
- (void) showCurrentPage
{
    [self.currentPageView removeFromSuperview];
    self.currentPageView = [self.externalDelegate viewForScrollView:self atPage:self.currentPageIndex];
    [self addHeaderAndFooterForPage:self.currentPageIndex scrollView:self.currentPageView.scrollView];
    [self addSubview:self.currentPageView];
    
}
- (void)addHeaderAndFooterForPage:(NSUInteger)pageIndex scrollView:(UIScrollView *)scrollView{
    AllAroundPullView * headerView = [self.externalDelegate headerViewForScrollView:scrollView atPage:pageIndex];
    if(headerView){
        [headerView setAllAroundPullViewActionHandler:^(AllAroundPullView *view){
            NSLog(@"show previous page");
            [self showOhterPage:YES];
        }];
        [scrollView addSubview:headerView];
    }
    AllAroundPullView * footer = [self.externalDelegate footerViewForScrollView:scrollView atPage:pageIndex];
    if(footer){
        [footer setAllAroundPullViewActionHandler:^(AllAroundPullView *view){
            NSLog(@"show next page");
            [self showOhterPage:NO];
        }];
        [scrollView addSubview:footer];
    }
}

- (void)showOhterPage:(BOOL)showPrevious{
    float animDuration = 0.6;
    if(showPrevious){
        UIWebView * previousPage = [self.externalDelegate viewForScrollView:self atPage:self.currentPageIndex-1];
        previousPage.frame = CGRectMake(0, 0, previousPage.frame.size.width, previousPage.frame.size.height);
        [self addHeaderAndFooterForPage:self.currentPageIndex-1 scrollView:previousPage.scrollView];
        [self addSubview:previousPage];
        self.latestPageView = previousPage;
        // Start the page down animation
        [self setUserInteractionEnabled:NO];
        [self.currentPageView.scrollView setScrollEnabled:NO];
        [self.currentPageView backOutTo:kFTAnimationBottom inView:self withFade:YES duration:animDuration*0.70 delegate:nil startSelector:nil stopSelector:nil];
        [previousPage backInFrom:kFTAnimationTop inView:self withFade:YES duration:animDuration delegate:nil startSelector:nil stopSelector:nil];
        [self performSelector:@selector(pageAnimationDidStop) withObject:nil afterDelay:animDuration];
        _currentPageIndex--;
    }else{
        // Ask the delegate for the next page
        UIWebView* nextPage = [self.externalDelegate viewForScrollView:self atPage:self.currentPageIndex+1];
        // We want to animate this new page coming up, so we first
        // Set its frame to the bottom of the scroll view
        nextPage.frame = CGRectMake(0, 0, nextPage.frame.size.width, nextPage.frame.size.height);
        [self addHeaderAndFooterForPage:self.currentPageIndex+1 scrollView:nextPage.scrollView];
        [self addSubview:nextPage];
        self.latestPageView = nextPage;
        [self setUserInteractionEnabled:NO];
        [self.currentPageView.scrollView setScrollEnabled:NO];
        [self.currentPageView backOutTo:kFTAnimationTop inView:self withFade:YES duration:animDuration*0.70 delegate:nil startSelector:nil stopSelector:nil];
        [nextPage backInFrom:kFTAnimationBottom inView:self withFade:YES duration:animDuration delegate:nil startSelector:nil stopSelector:nil];
        [self performSelector:@selector(pageAnimationDidStop) withObject:nil afterDelay:animDuration];
        _currentPageIndex++;
    }
}
- (void)pageAnimationDidStop
{
    // Remove the old page
    [self.currentPageView removeFromSuperview];
    // Set the previous/next page we just animated into view as the current page
    self.currentPageView = self.latestPageView;
    [self.currentPageView.scrollView setScrollEnabled:YES];
    [self setUserInteractionEnabled:YES];
}

@end
