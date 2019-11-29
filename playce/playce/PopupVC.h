//
//  PopupVC.h
//  BlueTropical
//
//  Created by Tys Bradford on 17/05/2016.
//  Copyright © 2016 BlueTropical. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, BTPopupAnimation){
    
    BTPopupAnimationNone,
    BTPopupAnimationFade,
    BTPopupAnimationSlideUp
};

@interface PopupVC : UIViewController

@property (nonatomic)BOOL shouldHideStatusBar;


-(void)customiseView;
-(void)showInParentVC:(UIViewController*)vc animated:(BTPopupAnimation)animation;
-(void)showAboveAll:(BTPopupAnimation)animation;
-(void)hide:(BTPopupAnimation)animation;


-(BOOL)isShowing;

@end
