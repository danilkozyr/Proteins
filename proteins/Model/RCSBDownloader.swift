//
//  RCSBDownloader.swift
//  proteins
//
//  Created by Daniil KOZYR on 8/5/19.
//  Copyright © 2019 Daniil KOZYR. All rights reserved.
//

import Foundation
import Alamofire

class RCSBDownloader {
    
    private let url = "https://files.rcsb.org/ligands/view/"
    private let urlExtension = "_ideal.pdb"

    enum ResponseCases {
        case error(String)
        case success([Atom], [Connections])
    }
    
    func downloadConnections(for ligandName: String, completion: @escaping (ResponseCases) -> Void) {
        let fullURL = url + ligandName + urlExtension
        let url = URL(string: fullURL)
    
        Alamofire.request(url!).response { (response) in
            guard response.error == nil else {
                completion(.error("Server Error Occured.\n Check Internet Connection and try again!"))
                return
            }
            
            guard let data = response.data else {
                completion(.error("Server Error Occured."))
                return
            }
            
            guard let encodedData = String(data: data, encoding: .utf8) else {
                completion(.error("Server Error Occured."))
                return
            }
            
            var atoms: [Atom] = []
            
            let dataWithOneSpace = encodedData.condensedWhitespace
            let array = dataWithOneSpace.split(separator: "\n")
            
            // MARK: Atom Parse
            
            let allAtoms = array.filter { $0.contains("ATOM") }
            let elementsOfAtom = allAtoms.map { $0.components(separatedBy: " ") }

            for element in elementsOfAtom {
                let id = Int(element[1])
                let name = element[2]
                let x = Float(element[6])!
                let y = Float(element[7])!
                let z = Float(element[8])!
                let type = element[11]
                                
                atoms.append(Atom(name: name,
                                  id: id!,
                                  x: x,
                                  y: y,
                                  z: z,
                                  type: type))
            }
            
            // MARK: Connect Parse

            var connections: [Connections] = []
            
            let allConnections = array.filter { $0.contains("CONECT") }
            let elementsOfConnections = allConnections.map { $0.components(separatedBy: " ") }
            
            for connection in elementsOfConnections {
                let mainId = Int(connection[1])
                var otherConnections: [Int] = []
                
                for i in 2..<connection.count {
                    otherConnections.append(Int(connection[i])!)
                }

                connections.append(Connections(mainId: mainId!, ids: otherConnections))
                
            }
            
            completion(.success(atoms, connections))
            
        }
    }

}

