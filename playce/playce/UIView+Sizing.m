//
//  UIView+Sizing.m
//  Re-focus
//
//  Created by Tyson Bradford on 10/04/2014.
//  Copyright (c) 2014 WLS. All rights reserved.
//

#import "UIView+Sizing.h"

@implementation UIView (Sizing)

#pragma mark - Retrieving
-(CGFloat)bottomViewYPoint{
    return self.frame.origin.y + self.frame.size.height;
}

-(CGFloat)rightViewXPoint{
    return self.frame.origin.x + self.frame.size.width;
}


#pragma mark - Wrapping
-(void)wrapSubviewHeight{
    [self wrapSubviewHeightWithBottomPadding:0.0];
}

-(void)wrapSubviewHeightWithBottomPadding:(CGFloat)padding{
    
    //Find lowest point of subviews
    CGFloat lowPoint = 0.0;
    
    for (UIView *subview in [self subviews]){
        
        CGFloat bottomPoint = subview.frame.origin.y + subview.frame.size.height;
        if (bottomPoint > lowPoint) lowPoint = bottomPoint;
    }
    
    if (lowPoint > 0.0) [self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, lowPoint+padding)];
}

-(void)wrapSubviewWidth{
    [self wrapSubviewWidthWithPadding:0.0];

}
-(void)wrapSubviewWidthWithPadding:(CGFloat)padding{
    
    //Find rightest point of subviews
    CGFloat rightest = 0.0;
    for (UIView *subview in [self subviews]){
        
        CGFloat rightPoint = subview.frame.origin.x + subview.frame.size.width;
        if (rightPoint > rightest) rightest = rightPoint;
    }
    
    if (rightest > 0.0) [self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, rightest+padding, self.frame.size.height)];
}

#pragma mark - Setting
-(void)setOriginY:(CGFloat)originY{
    self.frame = CGRectMake(self.frame.origin.x, originY, self.frame.size.width, self.frame.size.height);
}

-(void)setOriginX:(CGFloat)originX{
    self.frame = CGRectMake(originX, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
}

-(void)setWidth:(CGFloat)width{
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, self.frame.size.height);
}

-(void)setHeight:(CGFloat)height{
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
}

#pragma mark - Alignment
-(void)alginToLeft:(UIView*)view{
    [self setOriginX:view.frame.origin.x];
}
-(void)alignToRight:(UIView*)view{
    CGFloat originX = view.frame.origin.x + view.frame.size.width - self.frame.size.width;
    [self setOriginX:originX];
}
-(void)alignToTop:(UIView*)view{
    [self setOriginY:view.frame.origin.y];
}
-(void)alignToBottom:(UIView*)view{
    CGFloat originY = view.frame.origin.y + view.frame.size.height - self.frame.size.height;
    [self setOriginY:originY];
}
-(void)alignCenterHorizontal:(UIView*)view{
    self.center = CGPointMake(view.center.x, self.center.y);
}
-(void)alignCenterVertical:(UIView*)view{
    self.center = CGPointMake(self.center.x, view.center.y);
}



@end
