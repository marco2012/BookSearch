//
//  UserViewController.swift
//  FriendlyEats
//
//  Created by Marco on 03/11/2018.
//  Copyright © 2018 Firebase. All rights reserved.
//

import UIKit
import Eureka
import FirebaseUI

class UserViewController: FormViewController {

    var books_purchased_titles = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getPurchasedBooks()
        
        setupForm()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        getPurchasedBooks()
    }
    
    func getPurchasedBooks(){
        DispatchQueue.main.async {
            BackendAPI().mybooks(user:(Auth.auth().currentUser?.email)!) {
                (purchases) in
                print(self.books_purchased_titles)
                self.books_purchased_titles = purchases
            }
//        if let decoded_purchased  = UserDefaults.standard.object(forKey: "books_purchased") as? Data {
//            let books_purchased = NSKeyedUnarchiver.unarchiveObject(with: decoded_purchased) as! [Book]
//            books_purchased_titles = books_purchased.map{$0.title}
//        } else {
//            BackendAPI().mybooks(user:(Auth.auth().currentUser?.email)!) {
//                (purchases) in
//                self.books_purchased_titles = purchases
//
//                let userDefaults = UserDefaults.standard
//                var books_purchased = [Book]()
//
//                //read from userdefaults
//                if let decoded_purchased  = UserDefaults.standard.object(forKey: "books_purchased") as? Data {
//                    books_purchased = NSKeyedUnarchiver.unarchiveObject(with: decoded_purchased) as! [Book]
//                }
//
//                //add current book if not already there
//                if (books_purchased.contains(where: {$0.isbn == self!.book!.isbn})) {
//                    self.alert(title: "Book already purchased")
//                } else {
//                    books_purchased.append(self.book!)
//                }
//
//                //save to userdefaults
//                let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: books_purchased)
//                userDefaults.set(encodedData, forKey: "books_purchased")
//                userDefaults.synchronize()
//
//            }
//        }
        }
    }
    
    func setupForm(){
        if Auth.auth().currentUser != nil { //user is signed in
            let user = Auth.auth().currentUser
            if let user = user {
                // The user's ID, unique to the Firebase project.
                // Do NOT use this value to authenticate with your backend server,
                // if you have one. Use getTokenWithCompletion:completion: instead.
                
                //let uid = user.uid
                //let photoURL = user.photoURL
                
                //create form
                form +++ Section("Profile")
                    
                    <<< LabelRow () {
                        $0.title = "Name"
                        $0.value = user.displayName
                    }
                    
                    <<< LabelRow () {
                        $0.title = "Email"
                        $0.value = user.email
                    }
                    
                    <<< PasswordRow () {
                        $0.title = "Password"
                        $0.value = "password"
                        $0.tag = "passwordTag"
                    }
                    
                    +++ Section("Manage Books")

                    <<< PushRow<String>() {
                        $0.title = "Purchased"
                        $0.options = books_purchased_titles    //books array
                        $0.selectorTitle = "Purchases"
                        
                        }.onPresent { from, to in
                            to.dismissOnSelection = false
                            to.dismissOnChange = false
                            
                        }.cellUpdate { cell, row in
                            row.options = self.books_purchased_titles
                        }
                
                
                form +++ Section("Manage account")
                    
                    //Button to sign out
                    <<< ButtonRow() { (row: ButtonRow) -> Void in
                        row.title = "Sign Out"
                        }
                        .onCellSelection { [weak self] (cell, row) in
                            ViewControllerUtils().showActivityIndicator(uiView: self!.view)
                            DispatchQueue.main.async {
                                try? Auth.auth().signOut()
                                ViewControllerUtils().hideActivityIndicator(uiView: self!.view)
                                self!.present(FUIAuth.defaultAuthUI()!.authViewController(), animated: true, completion: nil)
                            }
                    }
                    
                    //Button to change password
                    <<< ButtonRow() { (row: ButtonRow) -> Void in
                        row.title = "Update password"
                        }
                        .onCellSelection { [weak self] (cell, row) in
                            let row: PasswordRow? = self!.form.rowBy(tag: "passwordTag")
                            let password = row!.value
                            Auth.auth().currentUser?.updatePassword(to: password!) { (error) in
                                print(error)
                            }
                            self!.alert(message: "", title: "Password changed")
                            
                    }
                    
                    //Button to reset password
                    <<< ButtonRow() { (row: ButtonRow) -> Void in
                        row.title = "Forgot password"
                        }
                        .onCellSelection { [weak self] (cell, row) in
                            Auth.auth().currentUser?.sendEmailVerification { (error) in
                                print(error)
                            }
                            self?.alert(title: "Email sent")
                    }
                    
                    //Button to delete account
                    <<< ButtonRow() { (row: ButtonRow) -> Void in
                        row.title = "Delete account"
                        }
                        .onCellSelection { [weak self] (cell, row) in
                            
                            user.delete { error in
                                if let error = error {
                                    // An error happened.
                                    print(error)
                                    self?.alert(title: "Log in again to perform this action")
                                } else {
                                    // Account deleted.
                                    self?.presentAlertWithTitle(title: "Done", message: "Account deleted", options: "OK"){ (option) in
                                        switch(option) {
                                        case 0:
                                            self?.dismiss(animated: true, completion: nil)
                                            break
                                        default:
                                            break
                                        }
                                    }
                                    self!.present(FUIAuth.defaultAuthUI()!.authViewController(), animated: true, completion: nil)
                                }
                            }
                            
                }
                
            }
        }
    }
    

}
