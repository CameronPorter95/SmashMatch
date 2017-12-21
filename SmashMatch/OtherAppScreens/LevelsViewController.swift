//
//  LevelsViewController.swift
//  SmashMatch
//
//  Created by Yaoyu Cui on 20/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import UIKit

class LevelsViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
//        backgroundImage.frame = scrollView.bounds
//        scrollView.contentSize = backgroundImage.frame.size
//        scrollView.minimumZoomScale = 0.4
//        scrollView.maximumZoomScale = 4.0
//        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
        print("this page is alive...")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
