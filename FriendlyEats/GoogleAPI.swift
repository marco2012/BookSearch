//
//  API.swift
//
//  Created by Marco on 03/09/2018.
//  Copyright © 2018 Vikings. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

func getBook(isbn: String, completionHandler: @escaping ((Book) -> Void)) {
    let url = "https://www.googleapis.com/books/v1/volumes?q=isbn:\(isbn)"
    // Fetch Request
    Alamofire.request(url, method: .get)
        .validate(statusCode: 200..<300)
        .responseJSON { response in
            if (response.result.error == nil) {
                let data = JSON(response.result.value!)
                let array   = data["items"][0]
                let volumeInfo = array["volumeInfo"]
                let title = volumeInfo["title"].stringValue
                let authors = volumeInfo["authors"][0].stringValue
                let publisher = volumeInfo["publisher"].stringValue
                let publishedDate = volumeInfo["publishedDate"].stringValue
                let book_description = volumeInfo["description"].stringValue
                let pageCount = volumeInfo["pageCount"].intValue
                let categories = volumeInfo["categories"][0].stringValue
                let averageRating = volumeInfo["averageRating"].doubleValue
                let image = volumeInfo["imageLinks"]["thumbnail"].stringValue
                let saleInfo = array["saleInfo"]["saleability"].stringValue
                //Book creation
                let book = Book(isbn: isbn, title: title, author: authors, book_description: book_description, pages: pageCount, rating: averageRating, image_link: image, publisher: publisher, publishedDate: publishedDate, categories: categories, sale: saleInfo, address: nil, latitude: nil, longitude: nil, seller:nil)
                
                completionHandler(book) 
            }
            else {
                debugPrint("HTTP Request failed: \(String(describing: response.result.error))")
            }
    }
    
    func getWikiInfo(query: String, completionHandler: @escaping ((String) -> Void)) {
        
        let url = "https://en.wikipedia.org/w/api.php?format=json&action=query&prop=extracts&exintro&explaintext&redirects=1&titles=\(query)"
        
        // Fetch Request
        Alamofire.request(url, method: .get)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                if (response.result.error == nil) {
                    print("\(url)")
                    
                    let data = JSON(response.result.value!)
                    let pages = data["query"]["pages"]
                    
                    //                    let saleInfo = array["saleInfo"]["saleability"].stringValue
                    //
                    print (pages)
                    
                    completionHandler("")
                    
                }
                else {
                    debugPrint("HTTP Request failed: \(String(describing: response.result.error))")
                    
                }
        }
        
        
    }
    
}
