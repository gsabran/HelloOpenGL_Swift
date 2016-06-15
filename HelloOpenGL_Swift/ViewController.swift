//
//  ViewController.swift
//  HelloOpenGL_Swift
//
//  Created by DR on 8/25/15.
//  Copyright © 2015 DR. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let frame = UIScreen.main().bounds
        let _glView = OpenGLView(frame: frame)
        
        self.view.addSubview(_glView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

