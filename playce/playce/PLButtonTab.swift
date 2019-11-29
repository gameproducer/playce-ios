//
//  PLButtonTab.swift
//  playce
//
//  Created by Tys Bradford on 26/07/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit

class PLButtonTab: UIScrollView {

    var contentView : UIView!
    var selIndicator : UIView!
    
    let buttonFont : UIFont = UIFont(name: ".SFUIText-Semibold", size: 10.0)!
    let buttonColor : UIColor = UIColor(red: 127.0/255.0, green: 127.0/255.0, blue: 127.0/255.0, alpha: 1.0)
    let buttonColorSel : UIColor = UIColor(red: 33.0/255.0, green: 33.0/255.0, blue: 33.0/255.0, alpha: 1.0)
    
    var buttonPadding : CGFloat = 20.0
    let indicatorHeight : CGFloat = 2.0
    let divHeight : CGFloat = 1.0
    
    let selIndicatorColor : UIColor = UIColor(red: 61.0/255.0, green: 183.0/255.0, blue: 170.0/255.0, alpha: 1.0)
    
    
    // MARK: Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init() {
        self.init(frame:CGRect.zero)
    }
    
    func customInit() {
        
        //Init scrollview properties
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.canCancelContentTouches = true
        self.backgroundColor = UIColor.white
        
        //Add contentView
        contentView = UIView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 1.0, height: self.frame.height)))
        self.addSubview(contentView)
                
        //Add selection indicator
        selIndicator = UIView(frame: CGRect(x: 0.0, y: self.frame.height-indicatorHeight-divHeight+1.0, width: 0.0, height: indicatorHeight))
        selIndicator.backgroundColor = selIndicatorColor
        contentView.addSubview(selIndicator)
                
    }
    
    func resizeView() {
        
        if contentView != nil {
            contentView.frame = CGRect(origin: contentView.frame.origin, size: CGSize(width: getNextButtonOriginX(), height: contentView.frame.height))
            self.contentSize = contentView.frame.size
        }
    }
    
    func setFinalHeight(height:CGFloat) {
        self.contentView.setHeight(height)
    }
    
    
    func addDivider(){
        
        
        let divider = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 200.0, height: divHeight))
        divider.backgroundColor = PLStyle.colorWithHex("#D8D8D8")
        divider.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(divider)
        
        
        self.addConstraint(NSLayoutConstraint(item: divider, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0))
        self.addConstraint(NSLayoutConstraint(item: divider, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0))
        self.addConstraint(NSLayoutConstraint(item: divider, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0))
        self.addConstraint(NSLayoutConstraint(item: divider, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: divHeight))
    }
    
    
    func addButton(_ title:String)->UIButton {
        
        let button = UIButton(frame: CGRect(x: getNextButtonOriginX(), y: 0.0, width: 100.0, height: self.frame.size.height))
        button.setTitle(title, for: UIControl.State())
        button.titleLabel?.font = buttonFont
        button.sizeToFit()
        resizeButtonWithPadding(button,padding: buttonPadding)
        
        button.setTitleColor(buttonColor, for: UIControl.State())
        button.setTitleColor(buttonColorSel, for: UIControl.State.selected)
        
        button.addTarget(self, action: #selector(PLButtonTab.buttonPressed(_:)), for: UIControl.Event.touchUpInside)
        
        contentView.addSubview(button)
        resizeView()
        return button
    }
    
    func resizeButtonWithPadding(_ button:UIButton, padding: CGFloat) {
        
        button.sizeToFit()
        button.frame = CGRect(origin: button.frame.origin, size: CGSize(width: button.frame.size.width+2*buttonPadding, height: self.frame.size.height))
    }
    
    func getNextButtonOriginX() -> CGFloat {
        
        var maxX : CGFloat = 0.0
        for subview in self.contentView.subviews{
            
            if !subview.isKind(of: UIButton.self) {continue}
            else {
                let subMaxX : CGFloat = subview.frame.origin.x + subview.frame.size.width
                if subMaxX > maxX {
                    maxX = subMaxX
                }
            }
        }
        
        return maxX
    }
    
    
    // MARK: - Button Handler
    @objc func buttonPressed(_ sender: UIButton?){
        
        guard let button = sender else {return}
        
        unselectAllButtons()
        button.isSelected = true
        moveInidicatorToButton(button,animated: true)
        autoScrollIfNeeded(sender!)
    }
    
    func unselectAllButtons(){
        
        for button in contentView.subviews {
            
            if (button.isKind(of: UIButton.self)){
                let button = button as! UIButton
                button.isSelected = false
            }
        }
    }
    
    func moveInidicatorToButton(_ button: UIButton, animated: Bool){
        
        let newFrame = CGRect(origin: selIndicator.frame.origin, size: CGSize(width: button.frame.width-2*buttonPadding, height: selIndicator.frame.height))
        let newCenter = CGPoint(x: button.center.x, y: selIndicator.center.y)
        
        if animated {
            
            UIView.animate(withDuration: 0.5, animations: { 
                self.selIndicator.frame = newFrame
                self.selIndicator.center = newCenter
            })
            
        } else {
            
            selIndicator.frame = newFrame
            selIndicator.center = newCenter
        }
        
    }
    
    func autoScrollIfNeeded(_ selectedButton: UIButton){
        self.scrollRectToVisible(selectedButton.frame, animated: true)
    }
    
    //MARK: - Scrolling
    override func touchesShouldCancel(in view: UIView) -> Bool {
        if view is UIButton {
            return true
        }
        return super.touchesShouldCancel(in: view)
    }
    
    
    //MARK: - Selecting
    func selectFirst() {
        
    }
    
    
    //MARK: - Refreshing
    func clearAll() {
        if self.contentView == nil {return}
        self.contentView.removeFromSuperview()
        self.customInit()
        self.contentSize = CGSize.zero
    }
    
}
