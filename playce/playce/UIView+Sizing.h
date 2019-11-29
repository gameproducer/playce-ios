//
//  UIView+Sizing.h
//  Re-focus
//
//  Created by Tyson Bradford on 10/04/2014.
//  Copyright (c) 2014 WLS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Sizing)

-(CGFloat)bottomViewYPoint;
-(CGFloat)rightViewXPoint;

-(void)wrapSubviewHeight;
-(void)wrapSubviewHeightWithBottomPadding:(CGFloat)padding;

-(void)wrapSubviewWidth;
-(void)wrapSubviewWidthWithPadding:(CGFloat)padding;

-(void)setOriginY:(CGFloat)originY;
-(void)setOriginX:(CGFloat)originX;
-(void)setWidth:(CGFloat)width;
-(void)setHeight:(CGFloat)height;

//Alignment
-(void)alginToLeft:(UIView*)view;
-(void)alignToRight:(UIView*)view;
-(void)alignToTop:(UIView*)view;
-(void)alignToBottom:(UIView*)view;
-(void)alignCenterHorizontal:(UIView*)view;
-(void)alignCenterVertical:(UIView*)view;



@end
