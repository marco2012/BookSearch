import UIKit
import FirebaseUI
import FirebaseFirestore
import SDWebImage
import Kingfisher

class BooksTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

  @IBOutlet var tableView: UITableView!
  @IBOutlet var activeFiltersStackView: UIStackView!
  @IBOutlet var stackViewHeightConstraint: NSLayoutConstraint!

  @IBOutlet var cityFilterLabel: UILabel!
  @IBOutlet var categoryFilterLabel: UILabel!
  @IBOutlet var priceFilterLabel: UILabel!

  let backgroundView = UIImageView()

    private var restaurants: [Restaurant] = []
    private var books: [Book] = []
    private var documents: [DocumentSnapshot] = []

  fileprivate var query: Query? {
    didSet {
      if let listener = listener {
        listener.remove()
        observeQuery()
      }
    }
  }

  private var listener: ListenerRegistration?

  fileprivate func observeQuery() {
    guard let query = query else { return }
    stopObserving()

    // Display data from Firestore, part one

    listener = query.addSnapshotListener { [unowned self] (snapshot, error) in
      guard let snapshot = snapshot else {
        print("Error fetching snapshot results: \(error!)")
        return
      }
        
    DispatchQueue.main.async {
      let models = snapshot.documents.map { (document) -> Book in
        
        let x = document.data()
        
        let book = Book(isbn: x["isbn"] as! String, title: x["title"] as! String, author: x["author"] as! String, book_description: x["book_description"] as! String, pages: x["pages"] as! Int, rating: x["rating"] as! Double, image_link: x["image_link"] as! String, publisher: x["publisher"] as! String, publishedDate: x["publishedDate"] as! String, categories: x["categories"] as! String, sale: x["sale"] as! String, address: x["address"] as? String, latitude: x["latitude"] as? Double, longitude: x["longitude"] as? Double, seller: x["seller"] as? String)
        
    
        return book
        
      }
        self.books = models
        self.documents = snapshot.documents
        
        //remove duplicates in array
        self.books = Array(Set(self.books))
        //sort array
        self.books.sort(by: { $0.title > $1.title })

        
        //save to userdefaults
        let userDefaults = UserDefaults.standard
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: self.books)
        userDefaults.set(encodedData, forKey: "books")
        userDefaults.synchronize()
    }
      
      if self.documents.count > 0 {
        self.tableView.backgroundView = nil
      } else {
        self.tableView.backgroundView = self.backgroundView
      }

      self.tableView.reloadData()
    }
  }
    

  fileprivate func stopObserving() {
    listener?.remove()
  }

  fileprivate func baseQuery() -> Query {
    return Firestore.firestore().collection("books").limit(to: 50)
  }


  override func viewDidLoad() {
    super.viewDidLoad()
    backgroundView.image = UIImage(named: "shelves")!
    backgroundView.contentMode = .scaleAspectFit
    backgroundView.alpha = 0.5
    tableView.backgroundView = backgroundView
    tableView.tableFooterView = UIView()

//    // Blue bar with white color
//    navigationController?.navigationBar.barTintColor =
//      UIColor(red: 0x3d/0xff, green: 0x5a/0xff, blue: 0xfe/0xff, alpha: 1.0)
//    navigationController?.navigationBar.isTranslucent = false
//    navigationController?.navigationBar.titleTextAttributes =
//        [ NSAttributedStringKey.foregroundColor: UIColor.white ]

    tableView.dataSource = self
    tableView.delegate = self
    query = baseQuery()
    stackViewHeightConstraint.constant = 0
    activeFiltersStackView.isHidden = true
    
    self.tableView.register(FriendlyEats.RestaurantTableViewCell.self, forCellReuseIdentifier: "Cell")
    
  }
    
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.setNeedsStatusBarAppearanceUpdate()
    observeQuery()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    let auth = FUIAuth.defaultAuthUI()!
    if auth.auth?.currentUser == nil {
      auth.providers = []
      present(auth.authViewController(), animated: true, completion: nil)
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    stopObserving()
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    set {}
    get {
      return .lightContent
    }
  }

  deinit {
    listener?.remove()
  }

  // MARK: - UITableViewDataSource

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "RestaurantTableViewCell",
                                             for: indexPath) as! RestaurantTableViewCell
    let book = books[indexPath.row]
    cell.populate(book: book)
    return cell
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return books.count
  }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailsSegue" {
            let detailsVC = segue.destination as! BookDetailsViewController
            let cell = sender as! RestaurantTableViewCell
            let indexPaths = self.tableView.indexPath(for: cell)
            
            let book = self.books[indexPaths!.row] as Book
            detailsVC.book = book
        }
    }
}

class RestaurantTableViewCell: UITableViewCell {

  @IBOutlet private var thumbnailView: UIImageView!

  @IBOutlet private var nameLabel: UILabel!

  @IBOutlet var starsView: ImmutableStarsView!

  @IBOutlet private var cityLabel: UILabel!

  @IBOutlet private var categoryLabel: UILabel!

  @IBOutlet private var priceLabel: UILabel!

  func populate(book: Book) {
    // Displaying data
    nameLabel.text = book.title
    cityLabel.text = "\(book.pages) pages"
    categoryLabel.text = book.author
    
    starsView.rating = Int(book.rating.rounded())
    priceLabel.text = ""
    
    self.thumbnailView.image = UIImage.gifImageWithURL("https://www.fcnaustin.com/wp-content/uploads/2018/11/AppleLoading.gif") //loading indicator
//    self.thumbnailView.transform = CGAffineTransform(rotationAngle: .pi/2) //rotate image 90
    
        if let retrievedImage = UserDefaults.standard.object(forKey: book.isbn)  {
            let storedImage = UIImage(data: (retrievedImage as! NSData) as Data)
            self.thumbnailView.image = storedImage!
        } else {
             DispatchQueue.main.async {
                BackendAPI().getImage(isbn: book.isbn) { (image) in
                    let jpgImage = UIImageJPEGRepresentation(image, 0.3)
                    UserDefaults.standard.set(jpgImage, forKey: book.isbn)
                    self.thumbnailView.image = image
                }
            }
        }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    thumbnailView.sd_cancelCurrentImageLoad()
  }

}
