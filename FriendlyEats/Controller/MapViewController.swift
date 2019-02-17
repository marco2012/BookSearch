
import UIKit
import GoogleMaps
import GooglePlaces
import HDAugmentedReality
import FirebaseUI
import FirebaseFirestore

class MapViewController: UIViewController, ARDataSource {
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var mapView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var zoomLevel: Float = 15.0
    
    // An array to hold the list of likely places.
    var likelyPlaces: [GMSPlace] = []
    
    // The currently selected place.
    var selectedPlace: GMSPlace?
    
    // A default location to use when location permission is not granted.
    let defaultLocation = CLLocation(latitude: -33.869405, longitude: 151.199)
    
    fileprivate var places = [Book]()

    var books = [Book]() //array of books
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize the location manager.
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        placesClient = GMSPlacesClient.shared()
        
        //get current location
        if( CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() ==  .authorizedAlways){
            currentLocation = locationManager.location
        }
        
        // Create a map.
        let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude,
                                              longitude: defaultLocation.coordinate.longitude,
                                              zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        
        // Add the map to the view, hide it until we've got a location update.
        view.addSubview(mapView)
        mapView.isHidden = true
        
        listLikelyPlaces()
        
        //read
//        if let decoded_purchased  = UserDefaults.standard.object(forKey: "books_purchased") as? Data {
//            let books_purchased = NSKeyedUnarchiver.unarchiveObject(with: decoded_purchased) as! [Book]
//            books_purchased_titles = books_purchased.map{$0.title}
//        }
        let decoded  = UserDefaults.standard.object(forKey: "books") as! Data
        books = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [Book]
        
        print("BOOKS \(books)")
        
        for book in books {
            
            getCoordinate(addressString: book.address!, completionHandler: {
                coordinates, error in
                
                book.latitude = coordinates.latitude
                book.longitude = coordinates.longitude
                
                // Creates a marker
                let marker = GMSMarker()
                marker.position = CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude)
                marker.title = book.title
                marker.snippet = book.address
                marker.map = self.mapView
                
            })
        }
    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        //read
        let decoded  = UserDefaults.standard.object(forKey: "books") as! Data
        books = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [Book]
    }
    
    //https://developer.apple.com/documentation/corelocation/converting_between_coordinates_and_user-friendly_place_names
    func getCoordinate( addressString : String,
                        completionHandler: @escaping(CLLocationCoordinate2D, NSError?) -> Void ) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(addressString) { (placemarks, error) in
            if error == nil {
                if let placemark = placemarks?[0] {
                    let location = placemark.location!
                    
                    completionHandler(location.coordinate, nil)
                    return
                }
            }
            completionHandler(kCLLocationCoordinate2DInvalid, error as NSError?)
        }
    }
    
    
    
    // Populate the array with the list of likely places.
    func listLikelyPlaces() {
        // Clean up from previous sessions.
        likelyPlaces.removeAll()

        placesClient.currentPlace(callback: { (placeLikelihoods, error) -> Void in
            if let error = error {
                // TODO: Handle the error.
                print("Current Place error: \(error.localizedDescription)")
                return
            }

            // Get likely places and add to the list.
            if let likelihoodList = placeLikelihoods {
                for likelihood in likelihoodList.likelihoods {
                    let place = likelihood.place
                    self.likelyPlaces.append(place)
                }
            }
        })
    }
    
    // Prepare the segue.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToSelect" {
//            if let nextViewController = segue.destination as? PlacesViewController {
//                nextViewController.likelyPlaces = likelyPlaces
//            }
        }
    }
    
    
    //https://github.com/DanijelHuis/HDAugmentedReality#how-to-use
    @IBAction func showARVIewController(_ sender: UIBarButtonItem) {
        showARViewController()
    }
    
    /// Creates random annotations around predefined center point and presents ARViewController modally
    func showARViewController(){
        // Check if device has hardware needed for augmented reality
        if let error = ARViewController.isAllHardwareAvailable(), !Platform.isSimulator {
            let message = error.userInfo["description"] as? String
            let alertView = UIAlertView(title: "Error", message: message, delegate: nil, cancelButtonTitle: "Close")
            alertView.show()
            return
        }
        
        
        // Create random annotations around center point
        
        //FIXME: set your initial position here, this is used to generate random POIs
        print( currentLocation!.coordinate.latitude)
        let lat = currentLocation!.coordinate.latitude
        let lon = currentLocation!.coordinate.longitude
        let deltaLat = 0.04 // Area in which to generate annotations
        let deltaLon = 0.07 // Area in which to generate annotations
        let altitudeDelta: Double = 0
        let count = books.count
        let dummyAnnotations = MapViewController.getDummyAnnotations(books: books, centerLatitude: lat, centerLongitude: lon, deltaLat: deltaLat, deltaLon: deltaLon, altitudeDelta: altitudeDelta, count: count)

        
        // ARViewController
        let arViewController = ARViewController()
        
        //===== Presenter - handles visual presentation of annotations
        let presenter = arViewController.presenter!
        // Vertical offset by distance
        presenter.distanceOffsetMode = .manual
        presenter.distanceOffsetMultiplier = 0.1   // Pixels per meter
        presenter.distanceOffsetMinThreshold = 500 // Doesn't raise annotations that are nearer than this
        // Filtering for performance
        presenter.maxDistance = 3000               // Don't show annotations if they are farther than this
        presenter.maxVisibleAnnotations = 100      // Max number of annotations on the screen
        // Stacking
        presenter.presenterTransform = ARPresenterStackTransform()
        
        //===== Tracking manager - handles location tracking, heading, pitch, calculations etc.
        // Location precision
        let trackingManager = arViewController.trackingManager
        trackingManager.userDistanceFilter = 15
        trackingManager.reloadDistanceFilter = 50
        
        //===== ARViewController
        // Ui
        arViewController.dataSource = self
        arViewController.uiOptions.closeButtonEnabled = true
        // Debugging
        arViewController.uiOptions.debugLabel = true
        arViewController.uiOptions.debugMap = true
        arViewController.uiOptions.simulatorDebugging = Platform.isSimulator
        arViewController.uiOptions.setUserLocationToCenterOfAnnotations =  Platform.isSimulator
        // Interface orientation
        arViewController.interfaceOrientationMask = .all
        // Failure handling
        arViewController.onDidFailToFindLocation =
            {
                [weak self, weak arViewController] elapsedSeconds, acquiredLocationBefore in
                
                self?.handleLocationFailure(elapsedSeconds: elapsedSeconds, acquiredLocationBefore: acquiredLocationBefore, arViewController: arViewController)
        }
        // Setting annotations
        arViewController.setAnnotations(dummyAnnotations)
        // Presenting controller
        self.present(arViewController, animated: true, completion: nil)
    }
    
    /// This method is called by ARViewController, make sure to set dataSource property.
    func ar(_ arViewController: ARViewController, viewForAnnotation: ARAnnotation) -> ARAnnotationView
    {
        // Annotation views should be lightweight views, try to avoid xibs and autolayout all together.
        let annotationView = TestAnnotationView()
        annotationView.frame = CGRect(x: 0,y: 0,width: 150,height: 50)
        return annotationView;
    }
    
  
    public class func getDummyAnnotations(books:[Book] ,centerLatitude: Double, centerLongitude: Double, deltaLat: Double, deltaLon: Double, altitudeDelta: Double, count: Int) -> Array<ARAnnotation> {
        var annotations: [ARAnnotation] = []
        
        //random annotation
        srand48(2)
        //for i in stride(from: 0, to: count, by: 1){
       
        for book in books{
            let location = self.getRandomLocation(centerLatitude: centerLatitude, centerLongitude: centerLongitude,
                                                  deltaLat: deltaLat, deltaLon: deltaLon, altitudeDelta: altitudeDelta)
            if let annotation = ARAnnotation(identifier: nil, title: book.title, location: location) {
                annotations.append(annotation)
            }
        }
        return annotations
    }
    
    func addDummyAnnotation(_ lat: Double,_ lon: Double, altitude: Double, title: String, annotations: inout [ARAnnotation])
    {
        let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon), altitude: altitude, horizontalAccuracy: 0, verticalAccuracy: 0, course: 0, speed: 0, timestamp: Date())
        if let annotation = ARAnnotation(identifier: nil, title: title, location: location)
        {
            annotations.append(annotation)
        }
    }
    
    public class func getRandomLocation(centerLatitude: Double, centerLongitude: Double, deltaLat: Double, deltaLon: Double, altitudeDelta: Double) -> CLLocation
    {
        var lat = centerLatitude
        var lon = centerLongitude
        
        let latDelta = -(deltaLat / 2) + drand48() * deltaLat
        let lonDelta = -(deltaLon / 2) + drand48() * deltaLon
        lat = lat + latDelta
        lon = lon + lonDelta
        
        let altitude = drand48() * altitudeDelta
        return CLLocation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon), altitude: altitude, horizontalAccuracy: 1, verticalAccuracy: 1, course: 0, speed: 0, timestamp: Date())
    }
    
}

// Delegates to handle events for the location manager.
extension MapViewController: CLLocationManagerDelegate {
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        
        if mapView.isHidden {
            mapView.isHidden = false
            mapView.camera = camera
        } else {
            mapView.animate(to: camera)
        }
        
        listLikelyPlaces()
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
    
    func handleLocationFailure(elapsedSeconds: TimeInterval, acquiredLocationBefore: Bool, arViewController: ARViewController?)
    {
        guard let arViewController = arViewController else { return }
        guard !Platform.isSimulator else { return }
        NSLog("Failed to find location after: \(elapsedSeconds) seconds, acquiredLocationBefore: \(acquiredLocationBefore)")
        
        // Example of handling location failure
        if elapsedSeconds >= 20 && !acquiredLocationBefore
        {
            // Stopped bcs we don't want multiple alerts
            arViewController.trackingManager.stopTracking()
            
            let alert = UIAlertController(title: "Problems", message: "Cannot find location, use Wi-Fi if possible!", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Close", style: .cancel)
            {
                (action) in
                
                self.dismiss(animated: true, completion: nil)
            }
            alert.addAction(okAction)
            
            self.presentedViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    
    
}
