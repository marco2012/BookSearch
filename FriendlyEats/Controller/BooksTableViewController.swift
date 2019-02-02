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
        
        //let y:[String:Any] = ["author": "Mark Levine", "isbn": 9781935098553, "publisher": "Hillcrest Publishing Group", "categories": "Language Arts & Disciplines", "rating": 4, "longitude": 0, "image_link": "http://books.google.com/books/content?id=3VVxfvCeaHYC&printsec=frontcover&img=1&zoom=1&source=gbs_api", "latitude": 0, "address": "Via Ariosto, Rome, Metropolitan City of Rome, Italy", "publishedDate": 2011-04-02, "sale": "NOT_FOR_SALE", "title": "The Fine Print of Self-Publishing", "pages": 274, "book_description": "Analyzes and critiques the contracts and services of the top self-publishing companies, and deciphers the law jargon used in self-publishing contracts.", "seller": "lollo@gmail.com"]
        
        let book = Book(isbn: x["isbn"] as! String, title: x["title"] as! String, author: x["author"] as! String, book_description: x["book_description"] as! String, pages: x["pages"] as! Int, rating: x["rating"] as! Double, image_link: x["image_link"] as! String, publisher: x["publisher"] as! String, publishedDate: x["publishedDate"] as! String, categories: x["categories"] as! String, sale: x["sale"] as! String, address: x["address"] as? String, latitude: x["latitude"] as? Double, longitude: x["longitude"] as? Double, seller: x["seller"] as? String)
        

        return book
        
      }
        self.books = models
        self.documents = snapshot.documents
        
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

//    self.navigationController?.navigationBar.barStyle = .black
    
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

    // Displaying data, part two

    nameLabel.text = book.title
    cityLabel.text = "\(book.pages) pages"
    categoryLabel.text = book.author
    
    starsView.rating = Int(book.rating.rounded())
    priceLabel.text = ""
    
    let retrievedImage = UserDefaults.standard.object(forKey: book.isbn) as AnyObject
    thumbnailView.image = UIImage(data: (retrievedImage as! NSData) as Data)
    
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    thumbnailView.sd_cancelCurrentImageLoad()
  }

}
