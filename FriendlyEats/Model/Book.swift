//
//  Book.swift
//  FriendlyEats
//
//  Created by Marco on 01/11/2018.
//  Copyright © 2018 Firebase. All rights reserved.
//

import Foundation

class Book: NSObject, NSCoding {
    
    var isbn:String
    var title:String
    var author:String
    var book_description:String
    var pages:Int
    var rating:Double
    var image_link:String
    var publisher: String;
    var publishedDate: String;
    var categories: String;
    var sale: String;
    var address: String?;
    var latitude: Double?;
    var longitude: Double?;
    var seller: String?;
    
    init(isbn: String, title: String, author: String, book_description: String, pages: Int, rating: Double, image_link: String, publisher: String, publishedDate: String, categories: String, sale: String, address: String?, latitude: Double?, longitude: Double?, seller:String?) {
        self.isbn = isbn
        self.title = title
        self.author = author
        self.book_description = book_description
        self.pages = pages
        self.rating = rating
        self.image_link = image_link
        self.publisher = publisher
        self.publishedDate = publishedDate
        self.categories = categories
        self.sale = sale
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.seller = seller
    }
    
    var dictionary: [String: Any] {
        return [
            "isbn": isbn,
            "title": title,
            "author": author,
            "book_description": book_description,
            "pages": pages,
            "rating": rating,
            "image_link": image_link,
            "publisher": publisher,
            "publishedDate": publishedDate,
            "categories": categories,
            "sale": sale,
            "address": address ?? "",
            "latitude" : latitude ?? 0.0,
            "longitude": longitude ?? 0.0,
            "seller" : seller!
        ]
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        let isbn = aDecoder.decodeObject(forKey: "isbn") as? String
        let title = aDecoder.decodeObject(forKey: "title") as? String
        let author = aDecoder.decodeObject(forKey: "author") as? String
        let book_description = aDecoder.decodeObject(forKey: "book_description") as? String
        let pages = aDecoder.decodeInteger(forKey: "pages")
        let rating = aDecoder.decodeObject(forKey: "rating") as? Double ?? Double.random(in: 0.0 ..< 5.0)
        let image_link = aDecoder.decodeObject(forKey: "image_link") as? String
        let publisher = aDecoder.decodeObject(forKey: "publisher") as? String
        let publishedDate = aDecoder.decodeObject(forKey: "publishedDate") as? String
        let categories = aDecoder.decodeObject(forKey: "categories") as? String
        let sale = aDecoder.decodeObject(forKey: "sale") as? String
        let address = aDecoder.decodeObject(forKey: "address") as? String
        let latitude = aDecoder.decodeObject(forKey: "latitude") as? Double
        let longitude = aDecoder.decodeObject(forKey: "longitude") as? Double
        let seller = aDecoder.decodeObject(forKey: "seller") as? String
        self.init(isbn: isbn!,
                  title: title!,
                  author: author!,
                  book_description: book_description!,
                  pages: pages,
                  rating: rating,
                  image_link: image_link!,
                  publisher: publisher!,
                  publishedDate: publishedDate!,
                  categories: categories!,
                  sale: sale!,
                  address: address,
                  latitude : latitude,
                  longitude: longitude,
                  seller: seller
        )
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(isbn, forKey: "isbn")
        aCoder.encode(title, forKey: "title")
        aCoder.encode(author, forKey: "author")
        aCoder.encode(book_description, forKey: "book_description")
        aCoder.encode(pages, forKey: "pages")
        aCoder.encode(rating, forKey: "rating")
        aCoder.encode(image_link, forKey: "image_link")
        aCoder.encode(publisher, forKey: "publisher")
        aCoder.encode(publishedDate, forKey: "publishedDate")
        aCoder.encode(categories, forKey: "categories")
        aCoder.encode(sale, forKey: "sale")
        aCoder.encode(address, forKey: "address")
        aCoder.encode(latitude, forKey: "latitude")
        aCoder.encode(longitude, forKey: "longitude")
        aCoder.encode(seller, forKey: "seller")
    }
    
    convenience init?(dictionary: [String : Any]) {
        guard let isbn = dictionary["isbn"] as? String,
            let title = dictionary["title"] as? String,
            let author = dictionary["author"] as? String,
            let book_description = dictionary["book_description"] as? String,
            let pages = dictionary["pages"] as? Int,
            let rating = dictionary["rating"] as? Double,
            let image_link = dictionary["image_link"] as? String,
            let publisher = dictionary["publisher"] as? String,
            let publishedDate = dictionary["publishedDate"] as? String,
            let categories = dictionary["categories"] as? String,
            let sale = dictionary["sale"] as? String,
            let address = dictionary["address"] as? String,
            let latitude = dictionary["latitude"] as? Double,
            let longitude = dictionary["longitude"] as? Double,
            let seller = dictionary["seller"] as? String
            else { return nil }
        
        
        self.init(isbn: isbn,
                  title: title,
                  author: author,
                  book_description: book_description,
                  pages: pages,
                  rating: rating,
                  image_link: image_link,
                  publisher: publisher,
                  publishedDate: publishedDate,
                  categories: categories,
                  sale: sale,
                  address: address,
                  latitude : latitude,
                  longitude: longitude,
                  seller: seller
        )
    }
    
}


