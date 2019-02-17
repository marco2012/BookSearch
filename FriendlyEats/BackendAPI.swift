//
//  API.swift
//  FriendlyEats
//
//  Created by Marco on 05/02/2019.
//  Copyright © 2019 Firebase. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class BackendAPI {
    
    let IP = "http://192.168.43.192:5000"
    let user = "bookshare"
    let password = "martagermano"
    
    func purchase(book:Book, seller:String){
        
//        let credentialData = "\(user):\(password)".data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
//        let base64Credentials = credentialData.base64EncodedString()
//        let headers = [
//            "Authorization": "Basic \(base64Credentials)",
//            "Accept": "application/json",
//            "Content-Type": "application/json"
//        ]
        
        let parameters: Parameters = [
            "email": seller,
            "title": book.title
        ]
        
        Alamofire.request(IP+"/purchase", method: .post, parameters: parameters, encoding: JSONEncoding.default)
    }

    func mybooks(user:String, completionHandler: @escaping (([String]) -> Void) ){
        
        let parameters: Parameters = [
            "email": user
        ]
        
        Alamofire.request(IP+"/mybooks", method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                if (response.result.error == nil) {
                    
                    let JSONarray = JSON(response.result.value!)
                    var purchases = [String]()
                    for (_, title) in JSONarray {
                        purchases.append(title.stringValue)
                    }
                    completionHandler(purchases) //return
                }
                else {
                    debugPrint("HTTP Request failed: \(String(describing: response.result.error))")
                }
            }
    }
    
    func sendImage(isbn: String, image:UIImage){
        
//        let imageData:Data = UIImagePNGRepresentation(image)!
        let imageData:Data = UIImageJPEGRepresentation(image, 0.2)!
        let strBase64 = imageData.base64EncodedString(options: .endLineWithLineFeed)
        print(strBase64.prefix(20))

        let parameters: Parameters = [
            "isbn"    : isbn,
            "img": strBase64
        ]
        
        Alamofire.request(IP+"/sendimg", method: .post, parameters: parameters, encoding: JSONEncoding.default)
    }
    
    func getImage(isbn:String, completionHandler: @escaping ((UIImage) -> Void) ){
        
        let parameters: Parameters = [
            "isbn"    : isbn
        ]
        
        // Fetch Request
        Alamofire.request(IP+"/getimg", method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                if (response.result.error == nil) {
                    
                    var decodedimage=UIImage.init()

                    let JSONarray = JSON(response.result.value!)
                    for (_, img) in JSONarray {
                        let strBase64 = img.string!
                        if let data = Data(base64Encoded: strBase64, options: .ignoreUnknownCharacters){
                            decodedimage = UIImage(data: data)!
                        }
                    }

                    completionHandler(decodedimage)
                }
                else {
                    debugPrint("HTTP Request failed: \(String(describing: response.result.error))")
                }
            }
    }
    

}
