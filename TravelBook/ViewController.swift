//
//  ViewController.swift
//  TravelBook
//
//  Created by Eren on 24.08.2024.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameLabel: UITextField!
    @IBOutlet weak var commentLabel: UITextField!
    
    var locationManager = CLLocationManager()
    var choosenLatitude = Double()
    var choosenLongitude = Double()
    
    var selectedTitle = ""
    var selectedTitleID : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Location Manager
        mapView.delegate = self // Delegate, bu tanımladığımız objelerin fonksiyonlarını kullanabilmek için.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization() //Kullanıcıdan izin istemek için.
        locationManager.startUpdatingLocation() //İzinden sonra konum verilerini çekmek için.
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 3
        
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if selectedTitle != "" {
            //CoreData
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let stringID = selectedTitleID!.uuidString
            fetchRequest.predicate = NSPredicate.init(format: "id = %@", stringID) // Filtreleme işlemi, eşleşen uuid'li objecti çağır.
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                
                if results.count > 0 {
                    
                    // Objelere erişip, eğer boş değillerse variable'lara kaydedip ekranda bu variable'ları göstermek için.
                    for result in results as! [NSManagedObject]{
                        
                        // Tüm ifleri birbiri içinde kullandık. Çünkü biri olmazsa hiç birini göstermesin istiyoruz.
                        if let title = result.value(forKey: "title") as? String {
                            annotationTitle = title
                            
                            if let subtitle = result.value(forKey: "subtitle") as? String {
                                annotationSubtitle = subtitle
                                
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    annotationLatitude = latitude
                                    
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        annotationLongitude = longitude
                                        
                                        // Hepsinin olduğuna emin olduktan sonra.
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        
                                        // Pin için, Latitude ve Longitude'u (Enlem ve Boylam) birleştirip bir koordinat oluşturmamız gerekli.
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        // Mevcut bilgileri ve pini ekrana eklemek için.
                                        mapView.addAnnotation(annotation)
                                        nameLabel.text = annotationTitle
                                        commentLabel.text = annotationSubtitle
                                        
                                        //İşaretlenmiş konumun olduğu bölgeyi tutabilmek için anlık konum almayı durdurmak için.
                                        locationManager.stopUpdatingLocation()
                                        
                                        // İşaretlenmiş konuma zoom yapmak için.
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                        
                                    }
                                }
                            }
                        }
                    }
                }
            }
            catch {
                print("Fetch Request Error!")
            }
            
        }
        else {
            //Add New Data
        }
        
    }
    
    @objc func chooseLocation(gestureRecognizer : UILongPressGestureRecognizer) {
        
        // Dokunma işlemi başladığında
        if gestureRecognizer.state == .began {
            
            let touchPoint = gestureRecognizer.location(in: self.mapView) //Ekranda nereye dokunulduğunu point olarak alıyoruz.
            let touchedCoordinate = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView) //Aldığımız pointi koordinasyona çeviriyoruz.
            choosenLatitude = touchedCoordinate.latitude
            choosenLongitude = touchedCoordinate.longitude
            
            // Pin ekleme
            let annotation = MKPointAnnotation() //Pin oluşturduk.
            annotation.coordinate = touchedCoordinate //Pin için koordinatları veriyoruz.
            annotation.title = nameLabel.text //Textfield'dan aldığımız text'leri pine ekledik.
            annotation.subtitle = commentLabel.text
            self.mapView.addAnnotation(annotation)
            
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if selectedTitle == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude) //Kullanıcının anlık lokasyonunu harita üzerine aktarıyoruz.
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1) //Aktarılan lokasyona zoom değerleri için. Değer ne kadar küçük olursa o kadar yakınlaşır.
            let region = MKCoordinateRegion(center: location, span: span) //Hangi merkeze ne kadar zoom yapılacağı fonksiyonu.
            mapView.setRegion(region, animated: true) //Yapılan her şeyi haritaya eklemek için.
        }
        
    }
    
    // Pinleri özelleştirmek için.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        // Kullanıcının konumunu pin ile göstermemek için kontrol.
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseID = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        
        // PinView'i özelleştirmek
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = true //Yanında baloncuk ile gösterebilmek.
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure) //Detay gösterilecek bir buton. i butonu.
            pinView?.rightCalloutAccessoryView = button //Callout'un sağ yanında göster.
            
        }
        else {
            // PinView önceden doluysa
            pinView?.annotation = annotation
        }
        
        return pinView
        
    }
    
    // Callout'a tıklandı kontrolü.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if selectedTitle != "" {
            
            var requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude) //Location için latitude ve longitude'dan coordinate oluşturduk.
            // Navigasyonu çalıştırabilmek için gerekli objeyi alabilmek için.
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks, error in
                //closure
                
                if let placemark = placemarks {
                    
                    if placemark.count > 0 {
                        
                        // Haritalardan navigasyon tarifi almak.
                        let newPlacemark = MKPlacemark(placemark: placemark[0]) //Map item için gerekli.
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.selectedTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving] //Arabayla gitmek için tarif.
                        item.openInMaps(launchOptions: launchOptions) //Haritalarda navigasyon tarifi açmak için.
                        
                    }
                    
                }
            }
        }
    }
    
    @IBAction func saveButton(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        // Yeni girilen değerleri kaydetmek için.
        newPlace.setValue(nameLabel.text, forKey: "title")
        newPlace.setValue(commentLabel.text, forKey: "subtitle")
        newPlace.setValue(choosenLatitude, forKey: "latitude")
        newPlace.setValue(choosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id") //Her yeni location kaydedildiğinde otomatik id oluşturacak.
        
        do {
            try context.save()
            print("Saved Successfully!")
        }
        catch {
            print("Context Save Error!")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil) //App içerisinde bir mesaj yayınladık.
        navigationController?.popViewController(animated: true) //Bir önceki ViewController'a döndürmek için.
        
    }
    
}

