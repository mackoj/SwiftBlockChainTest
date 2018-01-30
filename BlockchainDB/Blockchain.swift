//
//  Blockchain.swift
//  BlockchainDB
//
//  Created by Jeffrey Macko on 28/01/2018.
//  Copyright © 2018 Jeffrey Macko. All rights reserved.
//

import Foundation
import Swifter

extension Data {
  static func sha256(_ data: Data) -> String {
    var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
    data.withUnsafeBytes {
      _ = CC_SHA256($0, CC_LONG(data.count), &hash)
    }
    return Data(bytes: hash).base64EncodedString(options: [])
  }
}

struct Hash : Codable, Equatable{
  let value : String
  
  static func == (lhs: Hash, rhs: Hash) -> Bool {
    return lhs.value == rhs.value
  }
}

struct Block : Codable {
  let index : Int
  let timestamp : Date
  let transaction : [Transaction]
  let proof : Int
  let previousHash : Hash?
}

struct Transaction : Codable {
  let sender : String
  let recipient : String
  let amount : Int
}

struct NodesAddressList : Codable {
  let nodes : [String]
}

class Blockchain {
  var chain : [Block] = []
  var currentTransaction : [Transaction] = []
  let uuid = UUID()
  var nodes : [Blockchain] = []
  let server : HttpServer

  init?(port : in_port_t) {
    server = HttpServer()
    server.listenAddressIPv4 = "127.0.0.1"
    
    server["/mine"] = { (request : HttpRequest) -> HttpResponse in
      if request.method == "GET" {
        do {
          let block = self.mine()
          let data = try JSONEncoder().encode(block)
          return .ok(.json(data))
        } catch {
          print(error)
        }
      }
      return .internalServerError
    }
    server["/transactions/new"] = { (request : HttpRequest) -> HttpResponse in
      if request.method == "POST" {
        do {
          let transaction = try JSONDecoder().decode(Transaction.self, from: Data(bytes: request.body))
          let ret = self.newTransaction(sender: transaction.sender, recipient: transaction.recipient, ammount: transaction.amount)
          return .ok(.html("You asked for \(ret)"))
        } catch {
          print(error)
        }
      }
      return .badRequest(.html("You asked for \(request)"))
    }
    server["/chain"] = { (request : HttpRequest) -> HttpResponse in
      if request.method == "GET" {
        do {
//          let newChain : [Block] = try JSONDecoder().decode(self.chain, from: Data(bytes: request.body))
//          if newChain.count > self.chain.count {
//            self.chain = newChain
//            return .ok(.html("Mise a jour de la chaine OK"))
//          }
        } catch {
          print(error)
        }
      }
      return .ok(.html("ECHEC de Mise a jour de la chaine"))
    }
    
    server["/nodes/register"] = { (request : HttpRequest) -> HttpResponse in
      if request.method == "POST" {
        do {
          let nodeList = try JSONDecoder().decode(NodesAddressList.self, from: Data(bytes: request.body))
          var response : [AnyHashable:Any] = [:]
          response["message"] = "New nodes have been added"
          response["total_nodes"] = self.nodes
          self.registerNode(nodeList: nodeList)
          return .ok(.html("New nodes have been added"))
        } catch {
          print(error)
        }
      }
      return .internalServerError
    }

    server["/nodes/resolve"] = { (request : HttpRequest) -> HttpResponse in
      if request.method == "GET" {
        do {
          let data = try JSONEncoder().encode(self.chain)
          return .ok(.json(data))
        } catch {
          print(error)
        }
      }
      return .internalServerError
    }

    do {
      try server.start(port, forceIPv4: true)
    } catch {
      print(error)
      return nil
    }
    
    let blockZero = Block(index: 0, timestamp: Date(), transaction: [], proof: 100, previousHash: nil)
    chain.append(blockZero)
  }
  
  func mine() -> Block? {
    guard
      let lb = self.lastBlock(),
      let lastHash = self.hash(block: lb)
      else { return nil }
    
    let lastProof = lb.proof
    let newProof = self.proofOfWork(lastProof: lastProof)
    
    _ = self.newTransaction(sender: "0", recipient: uuid.uuidString, ammount: 1)
    let block = self.newBlock(proof: newProof, previousHash: lastHash)
    return block
  }

  func newBlock(proof : Int, previousHash : Hash) -> Block {
    let block = Block(
      index: lastBlockIndex() + 1,
          timestamp: Date(),
          transaction: self.currentTransaction,
          proof: proof,
          previousHash: self.hash(block: chain.last))
    self.chain.append(block)
    return block
  }
  
  
  func registerNode(nodeList : NodesAddressList) {
//    self.nodes.append(node)
  }
  
  func validChain(inputChain : [Block]) -> Bool {
    return true
    
    guard var lb = inputChain.first else { return false }
    
    var current_index = 0
    
    while current_index < inputChain.count {
      let block = inputChain[current_index]
      print(lb)
      print(block)
      print("\n-----------\n")

      // Check that the hash of the block is correct
      if block.previousHash != self.hash(block: lb) {
        return false
      }
      
      if self.validProof(lastProof: lb.proof, proof: block.proof) == false {
        return false
      }
      
      lb =  block
      current_index = current_index + 1
    }
    return true
  }
  
  func resolveConflits() {
//    let neighbours = self.nodes
//    let new_chain : [Block] = []
//
////    # We're only looking for chains longer than ours
//    let max_length = self.chain.count
//
////    # Grab and verify the chains from all the nodes in our network
//    for node in neighbours
//    response = requests.get(f'http://{node}/chain')
//
//    if response.status_code == 200:
//    length = response.json()['length']
//    chain = response.json()['chain']
//
//    # Check if the length is longer and the chain is valid
//    if length > max_length and self.valid_chain(chain):
//    max_length = length
//    new_chain = chain
//
//    # Replace our chain if we discovered a new, valid chain longer than ours
//    if new_chain:
//    self.chain = new_chain
//    return True
//
//    return False
  }
  
  func proofOfWork(lastProof : Int) -> Int {
    var proof = 0
    while validProof(lastProof: lastProof, proof: proof) {
      proof = proof + 1
    }
    return proof
  }
  
  // calcule une preuve poru la blockchain
  func validProof(lastProof: Int, proof: Int) -> Bool {
    guard let guess = String("\(lastProof)\(proof)").data(using: .utf8) else {
      fatalError()
    }
    let guess_hash = Data.sha256(guess)
    return guess_hash.prefix(4) == "0000"
  }

  
  // retourne l'index dans la blockchain
  func newTransaction(sender : String, recipient : String, ammount : Int) -> Int {
    self.currentTransaction.append(Transaction(sender: sender, recipient: recipient, amount: ammount))
    return lastBlockIndex()
  }
  
  // dernier index de la blockchain
  func lastBlockIndex() -> Int { return chain.count - 1 }
  
  // dernier bloclk de la blockchain
  func lastBlock() -> Block? { return chain.last }

  // calcule de hash d'un block
  func hash(block : Block?) -> Hash? {
    if block == nil {
      return nil
    }
    
    if let data = try? JSONEncoder().encode(block) {
      return Hash(value : Data.sha256(data))
    }
    return nil
  }
}

