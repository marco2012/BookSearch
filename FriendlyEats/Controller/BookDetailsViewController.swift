//
//  BookDetailsViewController.swift
//  FriendlyEats
//
//  Created by Marco on 10/11/2018.
//  Copyright © 2018 Firebase. All rights reserved.
//

import Eureka
import ViewRow

class BookDetailsViewController: FormViewController {
    
    var book : Book?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = book?.title
        
        
        
        makeForm()
    }
    
    private func makeForm(){
        //remove book! image
        self.view.viewWithTag(100)?.removeFromSuperview()
        
        //create form
        form
            
            +++ Section("Book details")
            
            <<< LabelRow () {
                $0.title = "Title"
                $0.value = book?.title
            }
            
            <<< LabelRow () {
                $0.title = "Author"
                $0.value = book!.author
            }

            <<< LabelRow () {
                $0.title = "Seller"
                $0.value = book!.seller
            }
            
            <<< ViewRow<UIImageView>()
                .cellSetup { (cell, row) in
                    //  Construct the view for the cell
                    cell.view = UIImageView()
                    cell.contentView.addSubview(cell.view!)
                    
                    //  Get something to display
                    let retrievedImage = UserDefaults.standard.object(forKey: self.book!.isbn) as AnyObject
                    let image = UIImage(data: (retrievedImage as! NSData) as Data)
                    cell.view!.image = image
                    cell.view!.contentMode = UIViewContentMode.scaleAspectFit
                    
                    //  Make the image view occupy the entire row:
                    cell.viewRightMargin = 0.0
                    cell.viewLeftMargin = 0.0
                    cell.viewTopMargin = 0.0
                    cell.viewBottomMargin = 0.0
                    
                    //  Define the cell's height
                    cell.height = { return CGFloat(200) }
            }
            
            +++ Section("Description")
            
            <<< TextAreaRow("description") {
                $0.value = book!.book_description
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 50)
                $0.disabled = true
            }
            
            +++ Section("Location")
            
            <<< LabelRow () {
                $0.title = book?.address
                $0.cell.textLabel?.numberOfLines = 0
            }
            
            +++ Section()
            
            <<< CheckRow("Show Next Section"){
                $0.title = "Show more details"
                $0.tag = "Show Next Section"
            }
            
            //This section is shown only when 'Show Next Row' switch is enabled
            +++ Section(){
                $0.hidden = .function(["Show Next Section"], { form -> Bool in
                    let row: RowOf<Bool>! = form.rowBy(tag: "Show Next Section")
                    return row.value ?? false == false
                })
                $0.tag = "hidden_details_section"
            }
            
            <<< LabelRow () {
                $0.title = "ISBN"
                $0.value = book!.isbn
            }
            
            <<< LabelRow () {
                $0.title = "Publisher"
                $0.value = book!.publisher
            }
            
            <<< LabelRow () {
                $0.title = "Published Date"
                $0.value = book!.publishedDate
            }
            
            <<< LabelRow () {
                $0.title = "Categories"
                $0.value = book!.categories
            }
            
            //            <<< LabelRow () {
            //                $0.title = "For sale"
            //                $0.value = book!.sale
            //            }
            
            <<< IntRow () {
                $0.title = "Pages"
                $0.value = book!.pages
                $0.disabled = false
            }
            
            <<< DecimalRow() {
                $0.title = "Rating"
                $0.value = book!.rating
                $0.formatter = DecimalFormatter()
                $0.useFormatterDuringInput = true
                $0.disabled = false
            }
            
            
            +++ Section()
            
            <<< ButtonRow() { (row: ButtonRow) -> Void in
                row.title = "Directions"
                }
                .onCellSelection { [weak self] (cell, row) in
                    //https://stackoverflow.com/a/21983980/1440037
                    let addr = self!.book?.address!.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                    let directionsURL = "http://maps.apple.com/?dirflg=d&saddr=Current%20Location&daddr="+addr!
                    print(directionsURL)
                    let url = URL(string: directionsURL)
                    UIApplication.shared.open(url!, options: [:], completionHandler: nil)
            }
            
            +++ Section()
            
            <<< ButtonRow() { (row: ButtonRow) -> Void in
                row.title = "Purchase"
                }
                .onCellSelection { [weak self] (cell, row) in
                    
                    let userDefaults = UserDefaults.standard
                    var books_purchased = [Book]()
                    
                    //read from userdefaults
                    if let decoded_purchased  = UserDefaults.standard.object(forKey: "books_purchased") as? Data {
                        books_purchased = NSKeyedUnarchiver.unarchiveObject(with: decoded_purchased) as! [Book]
                    }
      
                    //add current book if not already there
                    if (books_purchased.contains(where: {$0.isbn == self!.book!.isbn})) {
                        //display alert
                        let alert = UIAlertController(title: nil, message: "Book already purchased", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default)
                        alert.addAction(okAction)
                        self!.present(alert, animated: true)
                    } else {
                        books_purchased.append(self!.book!)
                    }
                    
                    //save to userdefaults
                    let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: books_purchased)
                    userDefaults.set(encodedData, forKey: "books_purchased")
                    userDefaults.synchronize()
                    
                    //display alert
                    let alert = UIAlertController(title: nil, message: "Item Purchased!", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default)
                    alert.addAction(okAction)
                    self!.present(alert, animated: true)
                    
            }
        
        
        // Enables the navigation accessory and stops navigation when a disabled row is encountered
        navigationOptions = RowNavigationOptions.Disabled
        // Enables smooth scrolling on navigation to off-screen rows
        animateScroll = true
        
    }
    


}
