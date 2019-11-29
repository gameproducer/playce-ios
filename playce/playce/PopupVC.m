//
//  PopupVC.m
//  BlueTropical
//
//  Created by Tys Bradford on 17/05/2016.
//  Copyright © 2016 BlueTropical. All rights reserved.
//

#import "PopupVC.h"

@interface PopupVC ()

@end

@implementation PopupVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)initViewWithParentView:(UIView*)view{
    
    self.view = [[UIView alloc] initWithFrame:view.bounds];
    [self customiseView];
}

//Primed for overriding by subclasses
-(void)customiseView{
    
    self.view.backgroundColor = [UIColor clearColor];
}


#pragma mark - Animation
static float const kBTAnimationDuration = 0.5;

-(void)showInParentVC:(UIViewController*)vc animated:(BTPopupAnimation)animation{
    
    [self showInView:vc.view animation:animation];
}

-(void)showAboveAll:(BTPopupAnimation)animation{
    
    UIView *parentView = [[UIApplication sharedApplication] delegate].window;
    [self showInView:parentView animation:animation];
}

-(void)showInView:(UIView*)view animation:(BTPopupAnimation)animation{
    
    if ([self isShowing]) return;
    if (!self.view.subviews.count) [self initViewWithParentView:view];
    if (_shouldHideStatusBar) [self hideStatusBar:animation];
    
    if (animation == BTPopupAnimationFade){
        self.view.alpha = 0.0;
        [view addSubview:self.view];
        [UIView animateWithDuration:kBTAnimationDuration animations:^{
            self.view.alpha = 1.0;
        } completion:nil];
    } else if (animation == BTPopupAnimationSlideUp) {
        CGRect finalFrame = self.view.frame;
        finalFrame.origin.y = 0.0;
        
        CGRect newFrame = self.view.frame;
        newFrame.origin.y = view.frame.origin.y + view.frame.size.height;
        self.view.frame = newFrame;
        [view addSubview:self.view];
        self.view.alpha = 1.0;
        self.view.hidden = NO;
        
        [UIView animateWithDuration:kBTAnimationDuration animations:^{
            self.view.frame = finalFrame;
        } completion:nil];
        
    } else {
        self.view.alpha = 1.0;
        [view addSubview:self.view];
    }
}

-(void)hide:(BTPopupAnimation)animation{
    
    if (_shouldHideStatusBar) [self showStatusBar:animation];
    if (animation == BTPopupAnimationFade){
        [UIView animateWithDuration:kBTAnimationDuration animations:^{
            self.view.alpha = 0.0;
        } completion:^(BOOL finished) {
            if (finished) [self.view removeFromSuperview];
        }];
    } else if (animation == BTPopupAnimationSlideUp){
        CGRect finalFrame = self.view.frame;
        finalFrame.origin.y = self.view.superview.frame.origin.y + self.view.superview.frame.size.height;
        [UIView animateWithDuration:kBTAnimationDuration animations:^{
            self.view.frame = finalFrame;
        } completion:^(BOOL finished) {
            if (finished) [self.view removeFromSuperview];
        }];
    } else {
        [self.view removeFromSuperview];
    }
}


#pragma mark - Status Bar
-(void)showStatusBar:(BOOL)animated{
    
    if ([NSThread isMainThread]) {
        UIStatusBarAnimation barAnimation = animated ? UIStatusBarAnimationFade : UIStatusBarAnimationNone;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:barAnimation];
    }
}

-(void)hideStatusBar:(BOOL)animated{
    
    if ([NSThread isMainThread]) {
        UIStatusBarAnimation barAnimation = animated ? UIStatusBarAnimationFade : UIStatusBarAnimationNone;
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:barAnimation];
    }
}

#pragma mark - Convenience
-(BOOL)isShowing{
    return (self.view.superview && !self.view.hidden);
}


@end
