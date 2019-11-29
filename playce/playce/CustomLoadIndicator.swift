//
//  CustomLoadIndicator.swift
//  Blue Tropical
//
//  Created by Tys Bradford on 15/08/2016.
//  Copyright © 2016 Blue Tropical. All rights reserved.
//



class CustomLoadIndicator : UIView {
    
    var bgView : UIView!
    var nodeView : UIView!
    var titleLabel : UILabel!
    var spinner : UIActivityIndicatorView!
    var customSpinner : UIView!
    var nodeShadowView : UIView!
    
    //MARK: - Customisation
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initView()
    }
    
    init(parentView:UIView) {
        super.init(frame: parentView.bounds)
        parentView.addSubview(self)
        initView()
    }
    
    func initView() {
        
        //Background
        self.bgView = UIView(frame: self.frame)
        self.bgView.backgroundColor = UIColor.lightGray
        self.bgView.alpha = 0.35
        self.addSubview(self.bgView)
        
        //Node
        self.nodeView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 80.0, height: 80.0))
        self.nodeView.center = CGPoint(x: self.frame.size.width*0.5, y: self.frame.size.height*0.4)
        self.nodeView.layer.cornerRadius = 5.0
        self.nodeView.layer.masksToBounds = true
        self.nodeView.backgroundColor = PLStyle.greenColor()
        self.addSubview(self.nodeView)
        
        let shadowSize = CGSize(width: 0.0, height: 2.0)
        self.nodeShadowView = UIView(frame: self.nodeView.frame)
        self.nodeShadowView.layer.cornerRadius = self.nodeView.layer.cornerRadius
        self.nodeShadowView.layer.masksToBounds = true
        self.nodeShadowView.backgroundColor = UIColor.black
        self.nodeShadowView.alpha = 0.1
        self.nodeShadowView.center = CGPoint(x: self.nodeShadowView.center.x+shadowSize.width, y: self.nodeShadowView.center.y+shadowSize.height)
        self.insertSubview(self.nodeShadowView, belowSubview: self.nodeView)
        
        
        //Indicator
        self.spinner = UIActivityIndicatorView(frame: self.nodeView.bounds)
        self.spinner.style = .white
        self.spinner.hidesWhenStopped = true
        self.nodeView.addSubview(self.spinner)
        
        //Title
        let labelHeight : CGFloat = 20.0
        let labelPosY = self.nodeView.frame.size.height - labelHeight
        self.titleLabel = UILabel(frame: CGRect(x: 0.0, y: labelPosY, width: self.nodeView.frame.size.width, height: labelHeight))
        self.titleLabel.font = UIFont.systemFont(ofSize: 10.0)
        self.titleLabel.textColor = UIColor.white
        self.titleLabel.textAlignment = .center
        self.titleLabel.adjustsFontSizeToFitWidth = true
        self.titleLabel.minimumScaleFactor = 0.3
        self.addSubview(self.titleLabel)
        
        
        self.isHidden = true
    }
    
    
    //MARK: - Customise View
    func setTitle(_ string:String){
        self.titleLabel.text = string
    }
    
    func setTitleColor(_ color:UIColor){
        self.titleLabel.textColor = color
    }
    
    func setTitleFont(_ font:UIFont){
        self.titleLabel.font = font
    }
    
    
    //MARK: - Animation
    func startAnimating() {
        
        self.isHidden = false
        self.superview?.bringSubviewToFront(self)
        if self.spinner != nil {
            self.nodeView.alpha = 0.0
            UIView.animate(withDuration: 0.3, animations: { 
                self.nodeView.alpha = 1.0
            })
            self.spinner.startAnimating()
        }
    }
    
    func stopAnimating() {
        if self.spinner != nil {
            self.spinner.stopAnimating()
            UIView.animate(withDuration: 0.3, animations: { 
                self.nodeView.alpha = 0.0
                }, completion: { (finished) in
                    if finished {
                        self.isHidden = true
                        self.nodeView.alpha = 1.0
                    }
            })
        }
    }
    
    func isShowing() -> Bool {
        return !self.isHidden
    }
    
}
