//
//  ATPagingView.h
//  project
//
//  Created by blueman on 13-4-19.
//  Copyright (c) 2013年 runes. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Foundation/Foundation.h>

//this enum added by Lee, for UIScrollView Direction
typedef enum {
    ATPagingViewVertical,
    ATPagingViewHorizontal
} ATPagingViewDirection;

@protocol ATPagingViewDelegate;

// a wrapper around UIScrollView in (horizontal) paging mode, with an API similar to UITableView
@interface ATPagingView : UIView {
    // subviews
    UIScrollView *_scrollView;
    
    // properties
    id<ATPagingViewDelegate> _delegate;
    CGFloat _gapBetweenPages;
    NSInteger _pagesToPreload;
    
    // state
    NSInteger _pageCount;
    NSInteger _currentPageIndex;
    NSInteger _firstLoadedPageIndex;
    NSInteger _lastLoadedPageIndex;
    NSMutableSet *_recycledPages;
    NSMutableSet *_visiblePages;
    
    NSInteger _previousPageIndex;
    
    BOOL _rotationInProgress;
    BOOL _scrollViewIsMoving;
    BOOL _recyclingEnabled;
}

@property(nonatomic, assign) ATPagingViewDirection direction; //default is ATPagingViewHorizontal;

@property(nonatomic, assign) IBOutlet id<ATPagingViewDelegate> delegate;

@property(nonatomic, assign) CGFloat gapBetweenPages;  // default is 20

@property(nonatomic, assign) NSInteger pagesToPreload;  // number of invisible pages to keep loaded to each side of the visible pages, default is 1

@property(nonatomic, readonly) NSInteger pageCount;

@property(nonatomic, assign) NSInteger currentPageIndex;
@property(nonatomic, assign, readonly) NSInteger previousPageIndex; // only for reading inside currentPageDidChangeInPagingView

@property(nonatomic, assign, readonly) NSInteger firstVisiblePageIndex;
@property(nonatomic, assign, readonly) NSInteger lastVisiblePageIndex;

@property(nonatomic, assign, readonly) NSInteger firstLoadedPageIndex;
@property(nonatomic, assign, readonly) NSInteger lastLoadedPageIndex;
@property(nonatomic, assign)  UIScrollView *scrollView;

@property(nonatomic, assign) BOOL moving;
@property(nonatomic, assign) BOOL recyclingEnabled;

- (void)reloadData;  // must be called at least once to display something

- (UIView *)viewForPageAtIndex:(NSUInteger)index;  // nil if not loaded

- (UIView *)dequeueReusablePage;  // nil if none

- (void)willAnimateRotation;  // call this from willAnimateRotationToInterfaceOrientation:duration:

- (void)didRotate;  // call this from didRotateFromInterfaceOrientation:

- (id)initVerticalWithFrame:(CGRect)frame;
@end


@protocol ATPagingViewDelegate <NSObject>

@required

- (NSInteger)numberOfPagesInPagingView:(ATPagingView *)pagingView;

- (UIView *)viewForPageInPagingView:(ATPagingView *)pagingView atIndex:(NSInteger)index;
- (void)currentPageDidChangeInPagingIndex:(NSInteger)index;

@optional

- (void)currentPageDidChangeInPagingView:(ATPagingView *)pagingView;

- (void)pagesDidChangeInPagingView:(ATPagingView *)pagingView;

// a good place to start and stop background processing
- (void)pagingViewWillBeginMoving:(ATPagingView *)pagingView;
- (void)pagingViewDidEndMoving:(ATPagingView *)pagingView;

@end


@interface ATPagingViewController : UIViewController <ATPagingViewDelegate> {
    ATPagingView *_pagingView;
}

@property(nonatomic, retain) IBOutlet ATPagingView *pagingView;

@end
