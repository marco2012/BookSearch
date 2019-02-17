//
//  ScanViewController.swift
//  FriendlyEats
//
//  Created by Marco on 29/10/2018.
//  Copyright © 2018 Firebase. All rights reserved.
//

import Eureka
import BarcodeScanner
import FirebaseFirestore
import ImageRow
import GoogleMaps
import GooglePlaces
import FirebaseUI

class ScanViewController: FormViewController,
BarcodeScannerCodeDelegate, BarcodeScannerDismissalDelegate, BarcodeScannerErrorDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(someImageView) //This add it the view controller without constraints
        someImageViewConstraints() //This function is outside the viewDidLoad function that controls the constraints
        
        //scan barcode
        let viewController = makeBarcodeScannerViewController()
        present(viewController, animated: true, completion: nil)
        
    }
    
    //create barcode scanner view
    private func makeBarcodeScannerViewController() -> BarcodeScannerViewController {
        self.form.removeAll()
        let viewController = BarcodeScannerViewController()
        viewController.codeDelegate = self
        viewController.errorDelegate = self
        viewController.dismissalDelegate = self
        return viewController
    }
    
    //scanner success
    func scanner(_ controller: BarcodeScannerViewController, didCaptureCode code: String, type: String) {
        print("Barcode Data: \(code)")
        print("Symbology Type: \(type)")
        
        self.form.removeAll()
        
        if Auth.auth().currentUser != nil { //user is signed in
            let user = Auth.auth().currentUser
            getBook(isbn: code, completionHandler: {
                book in
                book.seller = user?.email
                self.makeBookForm(book: book)
                
            })
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    //scanner error
    func scanner(_ controller: BarcodeScannerViewController, didReceiveError error: Error) {
        print(error)
        controller.resetWithError(message: "Nothing found")
    }
    
    //scanner dismiss
    func scannerDidDismiss(_ controller: BarcodeScannerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    //scanner button tap
    @IBAction func scanBtn(_ sender: UIBarButtonItem) {
        //scan barcode
        let viewController = makeBarcodeScannerViewController()
        present(viewController, animated: true, completion: nil)
    }
    
    @IBAction func clearForm(_ sender: UIBarButtonItem) {
         self.form.removeAll()
    }
    
    
    //make form
    private func makeBookForm(book:Book) {
        
        //remove book image
        self.view.viewWithTag(100)?.removeFromSuperview()
        
        //create form
        form
            
            +++ Section("Book details")
            
            <<< LabelRow () {
                $0.title = "Title"
                $0.value = book.title
            }
            
            <<< LabelRow () {
                $0.title = "Author"
                $0.value = book.author
                
            }
        
            <<< MyImageRow() { row in
                row.title = "Book Cover"
                row.sourceTypes = [.Camera , .PhotoLibrary]
                row.clearAction = .yes(style: UIAlertActionStyle.destructive)
                row.tag = "image1"
                }
        
        +++ Section("Book description")
            
            <<< TextAreaRow("description") {
                $0.value = book.book_description
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 50)
                $0.disabled = true
            }
            
            
            +++ Section("Location")
            
            <<< GooglePlacesTableRow() { row in
                row.placeFilter?.type = .address    //suggest addresses
                row.placeholder = "Enter your location"
                row.tag = "location" // Upon parsing a form you get a nice key if you use a tag
                row.add(ruleSet: RuleSet<GooglePlace>()) // We can use GooglePlace() as a rule
                row.validationOptions = .validatesOnChangeAfterBlurred
                row.cell.textLabel?.textColor = UIColor.black
                row.cell.textLabel?.numberOfLines = 0
                }
                .cellUpdate { cell, row in // Optional
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
                $0.value = book.isbn
            }
            
            <<< LabelRow () {
                $0.title = "Publisher"
                $0.value = book.publisher
            }
            
            <<< LabelRow () {
                $0.title = "Published Date"
                $0.value = book.publishedDate
            }
            
            <<< LabelRow () {
                $0.title = "Categories"
                $0.value = book.categories
            }
            
//            <<< LabelRow () {
//                $0.title = "For sale"
//                $0.value = book.sale
//            }
            
            <<< IntRow () {
                $0.title = "Pages"
                $0.value = book.pages
                $0.disabled = false
            }
            
            <<< DecimalRow() {
                $0.title = "Rating"
                $0.value = book.rating == 0.0 ? Double.random(in: 0.0 ..< 5.0) : book.rating //if rating is 0 create a random rating for the book
                $0.formatter = DecimalFormatter()
                $0.useFormatterDuringInput = true
                $0.disabled = false
            }
        
    
        +++ Section()
            <<< ButtonRow() { (row: ButtonRow) -> Void in
                row.title = "Save to Library"
                }
                .onCellSelection { [weak self] (cell, row) in
                    
                    book.latitude = 0.0
                    book.longitude = 0.0
                    
                    ViewControllerUtils().showActivityIndicator(uiView: self!.view)
                    
                    //ASYNC Operation
                    DispatchQueue.main.async {
                        
                        let row: GooglePlacesTableRow? = self?.form.rowBy(tag: "location")
                        let address_value = row?.value.debugDescription
                        
                        if address_value == "nil" {
                            ViewControllerUtils().hideActivityIndicator(uiView: self!.view)
                            self!.alert(title: "Missing address")
                        } else {
                            let address = address_value!.components(separatedBy: "\"")[1]
                            book.address = address
                        }

                        let row1: MyImageRow? = self?.form.rowBy(tag: "image1")
                        let image_data = row1?.value
                        
                        if image_data == nil {
                            ViewControllerUtils().hideActivityIndicator(uiView: self!.view)
                            self!.alert(title: "Take a picture of the book")
                        } else {
//                            let jpgImage = UIImageJPEGRepresentation(image_data!, 0.6)
//                            UserDefaults.standard.set(jpgImage, forKey: book.isbn)
//                            print(image_data)
                            BackendAPI().sendImage(isbn: book.isbn, image: image_data!)
                        }
                        
                        if address_value != "nil" && image_data != nil {
                            //add book to library
                           self?.saveBookToFirebase(book: book)
                        }
                        
                    }
        }
        
        animateScroll = true
        
    }
    
     //TODO check if book already exist by isbn
    private func saveBookToFirebase(book:Book) {
        //Get remote collection
        let collection = Firestore.firestore().collection("books")
        
        //Save current book to collection
        collection.addDocument(data: book.dictionary)
        
        ViewControllerUtils().hideActivityIndicator(uiView: self.view)
        
        //display alert
        let alert = UIAlertController(title: "Book saved in database", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default)
        alert.addAction(okAction)
        self.present(alert, animated: true)
    }
    
    //book image to show when search is empty
    let someImageView: UIImageView = {
        let theImageView = UIImageView()
        theImageView.image = UIImage(named: "books_drawing")
        theImageView.translatesAutoresizingMaskIntoConstraints = false //You need to call this property so the image is added to your view
        theImageView.tag = 100
        return theImageView
    }()
    
    //book image constraints
    func someImageViewConstraints() {
        someImageView.widthAnchor.constraint(equalToConstant: 280).isActive = true
        someImageView.heightAnchor.constraint(equalToConstant: 280).isActive = true
        someImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        someImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 28).isActive = true
    }
    
    
}

/// CustomPickerController: a selector row where the user can pick an image and edit it then of the selection
public final class MyImageRow: _ImageRow<PushSelectorCell<UIImage>>, RowType {
    public required init(tag: String?) {
        super.init(tag: tag)
        
        // Set a nib file to the cell privider
        cellProvider = CellProvider<PushSelectorCell<UIImage>>(nibName: "CustomRow", bundle: Bundle.main)
    }
}
