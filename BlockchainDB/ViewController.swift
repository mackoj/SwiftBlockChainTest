//
//  ViewController.swift
//  BlockchainDB
//
//  Created by Jeffrey Macko on 28/01/2018.
//  Copyright © 2018 Jeffrey Macko. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  let blockChain = Blockchain(port: 8989)
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

