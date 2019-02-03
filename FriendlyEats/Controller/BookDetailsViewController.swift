//
//  BookDetailsViewController.swift
//  FriendlyEats
//
//  Created by Marco on 10/11/2018.
//  Copyright © 2018 Firebase. All rights reserved.
//

import Eureka
import ViewRow
import FirebaseFirestore
import MessageUI

class BookDetailsViewController: FormViewController, MFMailComposeViewControllerDelegate {
    
    var book : Book?
    var db: Firestore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = book?.title
        db = Firestore.firestore()
        
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
                }.cellUpdate{ cell, row in
                    cell.detailTextLabel?.textColor = .blue
                }.onCellSelection { [weak self] (cell, row) in
                    
                    self?.presentAlertWithTitle(title: "Send email to seller?", message: "", options: "Cancel","Send"){ (option) in
                        switch(option) {
                        case 0:
                            self?.dismiss(animated: true, completion: nil)
                            break
                        default:
                            
                            //open mail
                            if MFMailComposeViewController.canSendMail() {
                                let mail = MFMailComposeViewController()
                                mail.mailComposeDelegate = self!
                                mail.setToRecipients([self!.book!.seller!])
                                mail.setSubject("Question about \(self!.book!.title)")
                                //mail.setMessageBody("<p>Hello, I have a question about <i>\(self!.book!.title)</i> by  </p>", isHTML: true)
                                self!.present(mail, animated: true)
                            }
                            
                        }
                    }
                    
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
                $0.disabled = true
            }
            
            <<< DecimalRow() {
                $0.title = "Rating"
                $0.value = book!.rating
                $0.formatter = DecimalFormatter()
                $0.useFormatterDuringInput = true
                $0.disabled = true
            }
            
            
            +++ Section("Actions")
            
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
                        self!.alert(title: "Book already purchased")
                    } else {
                        books_purchased.append(self!.book!)
                    }
                    
                    //save to userdefaults
                    let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: books_purchased)
                    userDefaults.set(encodedData, forKey: "books_purchased")
                    userDefaults.synchronize()
                    
                    self!.alert(title: "Item Purchased")
                    
            }
        

            <<< ButtonRow() {
                $0.title = "Delete"
                }.cellSetup() {cell, row in
                    //cell.backgroundColor = UIColor.red
                    cell.tintColor = UIColor.red
                }.onCellSelection { [weak self] (cell, row) in
                    //https://stackoverflow.com/a/51793963/1440037
                    
                    // Create the alert controller
                    let alertController = UIAlertController(title: "Do you want to delete this book?", message: "", preferredStyle: .alert)
                    
                    // Create the actions
                    let okAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.destructive) {
                        UIAlertAction in
                        NSLog("OK Pressed")
                        
                        self!.db.collection("books").whereField("isbn", isEqualTo: self!.book?.isbn as Any).getDocuments() { (querySnapshot, err) in
                            if let err = err {
                                print("Error getting documents: \(err)")
                            } else {
                                for document in querySnapshot!.documents {
                                    document.reference.delete()
                                    self!.alert(title: "Deleted")
                                }
                            }
                        }
                        self!.navigationController?.popViewController(animated: true) //go back
                        
                    }
                    let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) {
                        UIAlertAction in
                        NSLog("Cancel Pressed")
                    }
                    
                    // Add the actions
                    alertController.addAction(okAction)
                    alertController.addAction(cancelAction)
                    
                    // Present the controller
                    self!.present(alertController, animated: true, completion: nil)
                    
                }
        
        
        // Enables the navigation accessory and stops navigation when a disabled row is encountered
        navigationOptions = RowNavigationOptions.Disabled
        // Enables smooth scrolling on navigation to off-screen rows
        animateScroll = true
        
    }
    
    //dismiss email
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    


}
