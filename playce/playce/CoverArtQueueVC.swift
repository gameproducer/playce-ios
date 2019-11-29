//
//  CoverArtQueueVC.swift
//  playce
//
//  Created by Tys Bradford on 24/10/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import Foundation

class CoverArtQueueVC: UIViewController {


    var scrollview : UIScrollView?
    

    override func viewDidLayoutSubviews() {
        if self.scrollview == nil {
            self.createSubviews()
        }
    }
    
    
    
    
    func createSubviews(){
        
        
    }
    
    func removeQueueItems() {
        
        guard let scroller = self.scrollview else {return}
        for view in scroller.subviews {
            view.removeFromSuperview()
        }
    }



    //MARK: - Update view
    func updateQueue(songQueue:[Song]?){
        
        /*
        self.removeQueueItems()
        guard let songs = songQueue else {return}
        for song in songs {
            
            
        }
 */
        
    }
    
    func goToIndex(animated:Bool){
        
        
    }

}


