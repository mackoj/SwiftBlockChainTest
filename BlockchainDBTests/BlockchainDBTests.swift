//
//  BlockchainDBTests.swift
//  BlockchainDBTests
//
//  Created by Jeffrey Macko on 28/01/2018.
//  Copyright © 2018 Jeffrey Macko. All rights reserved.
//

import XCTest
@testable import BlockchainDB

class BlockchainDBTests: XCTestCase {
  
    func testExample() {
      let bc = Blockchain()
      let node1 = Node(port: 8888)!
      let node2 = Node(port: 8989)!
      let node1NewBlock = node1.mine(blockChain: bc)
      XCTAssert(bc.hash(block: bc.lastBlock()) == bc.hash(block: node1NewBlock))
      let node2NewBlock = node2.mine(blockChain: bc)
      XCTAssert(bc.hash(block: bc.lastBlock()) == bc.hash(block: node2NewBlock))
      
//      let bc2 = Blockchain()
//      XCTAssert(bc2.validChain(inputChain : bc.chain))
    }
  
}
