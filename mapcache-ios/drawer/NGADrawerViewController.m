//
//  MCBottomDrawerViewController.m
//  MapDrawer
//
//  Created by Tyler Burgett on 8/20/18.
//  Copyright © 2018 GeoPackage. All rights reserved.
//

#import "NGADrawerViewController.h"

@interface NGADrawerViewController ()
@property (nonatomic) BOOL startedAsFullView;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic) CGFloat previousContentOffset; // Only used for rolled up gestures
@end


@implementation NGADrawerViewController

- (instancetype) initAsFullView: (BOOL) isFullView {
    self = [super init];
    _startedAsFullView = isFullView;
    _isFullView = YES;
    _swipeEnabled = YES;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _openView = 160;
    _collapsedView = [UIScreen mainScreen].bounds.size.height - 160; //120
    NSLog(@"Screen height: %f", [UIScreen mainScreen].bounds.size.height);
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    _panGestureRecognizer.delegate = self;
    _previousContentOffset = 0;
    [self.view addGestureRecognizer:_panGestureRecognizer];
    [self roundViews];
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self prepareBackgroundView];
}


- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_startedAsFullView) {
        self.view.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, self.view.frame.size.width, self.view.frame.size.height);
        self.view.alpha = 1;
        
        [UIView animateWithDuration:0.3 animations:^{
            self.view.frame = CGRectMake(0, self.openView, self.view.frame.size.width, self.view.frame.size.height);
            self.view.alpha = 1;
        } completion:^(BOOL finished) {
            [self.drawerViewDelegate drawerAddAnimationComplete:self];
        }];
    } else {
        [UIView animateWithDuration:0.6 animations:^{
            self.view.frame = CGRectMake(0, self.collapsedView, self.view.frame.size.width, self.view.frame.size.height);
        }];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) panGesture:(UIPanGestureRecognizer *) recognizer {
    if (![self gestureIsInConflict:recognizer] && _swipeEnabled) {
        CGPoint translation = [recognizer translationInView:self.view];
        CGPoint velocity = [recognizer velocityInView:self.view];
        CGFloat y = CGRectGetMinY(self.view.frame);
        
        if (y + translation.y > _openView && y + translation.y <= _collapsedView) {
            self.view.frame = CGRectMake(0, y + translation.y, self.view.frame.size.width, self.view.frame.size.height);
            [recognizer setTranslation:CGPointZero inView:self.view];
        }
        
        if (recognizer.state == UIGestureRecognizerStateEnded) {
            double duration = velocity.y < 0 ? ((y - _openView) / -velocity.y) : ((_collapsedView - y) / velocity.y);
            duration = duration > 1.3 ? 1 : duration;
            
            [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                if (velocity.y >= 0) {
                    self.view.frame = CGRectMake(0, self.collapsedView, self.view.frame.size.width, self.view.frame.size.height);
                    self.isFullView = NO;
                } else {
                    self.view.frame = CGRectMake(0, self.openView, self.view.frame.size.width, self.view.frame.size.height);
                    self.isFullView = YES;
                }
            } completion:nil];
        }
    }
}


- (void) rollUpPanGesture:(UIPanGestureRecognizer *) recognizer withScrollView:(UIScrollView *) scrollView {
    CGPoint velocity = [scrollView.panGestureRecognizer velocityInView:self.view];
    CGFloat y = CGRectGetMinY(self.view.frame);
    double duration = velocity.y < 0? ((y - self.openView) / -velocity.y) : ((self.collapsedView - y) / velocity.y);
    duration = duration > 1.3 ? 0.65 : duration;
    
    if (scrollView.contentOffset.y < 0  && self.previousContentOffset == 0) {
        scrollView.scrollEnabled = NO;
        [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            if (velocity.y >= 0) {
                self.view.frame = CGRectMake(0, self.collapsedView, self.view.frame.size.width, self.view.frame.size.height);
            }
        } completion:^(BOOL finished) {
            self.isFullView = NO;
            scrollView.scrollEnabled = YES;
        }];
        
        
    } else if (scrollView.contentOffset.y > 0 && !self.isFullView) {
        [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            if (velocity.y >= 0) {
                self.view.frame = CGRectMake(0, self.openView, self.view.frame.size.width, self.view.frame.size.height);
            }
        } completion:^(BOOL finished) {
            scrollView.scrollEnabled = YES;
            self.isFullView = YES;
        }];
    }
    
    self.previousContentOffset = scrollView.contentOffset.y;
}


- (BOOL)gestureIsInConflict:(UIPanGestureRecognizer *) recognizer {
    return false;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    if ([otherGestureRecognizer.view isKindOfClass:UITableView.class]) {
        return true;
    }
    
    NSLog(@"Checking those recognizers");
    
    return false;
}


- (void) makeFullView {
    self.view.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, self.view.frame.size.width, self.view.frame.size.height);
    self.view.alpha = 0;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.view.frame = CGRectMake(0, self.openView, self.view.frame.size.width, self.view.frame.size.height);
        self.view.alpha = 1;
    } completion:^(BOOL finished) {
        [self.drawerViewDelegate drawerAddAnimationComplete:self];
    }];
    
    self.isFullView = YES;
    [_drawerViewDelegate drawerAddAnimationComplete:self];
}


- (void) slideDown {
    [UIView animateWithDuration:0.3 animations:^{
        self.view.frame = CGRectMake(0, self.collapsedView, self.view.frame.size.width, self.view.frame.size.height);
        self.isFullView = NO;
    }];
}


- (void) removeDrawerFromSuperview {
    [UIView animateWithDuration:0.37 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.view.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, self.view.frame.size.width, self.view.frame.size.height);
        self.view.alpha = 0.0;
    } completion:^(BOOL finished){
        [self removeFromParentViewController];
        [self.view removeFromSuperview];
    }];
}


- (void) addDragHandle {
    // Taking the width of the drag handle into account when adding it.
    UIImageView *dragHandle = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 36)/2, 8, 36, 4)];
    dragHandle.image = [UIImage imageNamed:@"dragHandle"];
    UIView *handleHolder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 16)];
    [handleHolder addSubview:dragHandle];
    [self.view addSubview:handleHolder];
}


- (void) addCloseButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self
               action:@selector(closeDrawer)
     forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[UIImage imageNamed:@"closeButton"] forState:UIControlStateNormal];
    button.frame = CGRectMake(self.view.frame.size.width - 36, 8, 32, 32);
    [self.view addSubview:button];
}


- (void) closeDrawer {
    NSLog(@"Close button tapped.");
}


- (void) roundViews {
    self.view.layer.cornerRadius = 5;
    self.view.clipsToBounds = YES;
    
    [self.view.layer setBorderColor:[UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:0.25].CGColor];
    [self.view.layer setBorderWidth:1.0];
}


- (void) prepareBackgroundView {
    // iOS 13 dark mode support
    if ([UIColor respondsToSelector:@selector(systemBackgroundColor)]) {
        self.view.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }
}

@end
