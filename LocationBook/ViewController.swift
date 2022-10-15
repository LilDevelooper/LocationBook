//
//  ViewController.swift
//  LocationBook
//
//  Created by yunus emre vural on 12.10.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate  {
    
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var noteText: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var saveButton: UIButton!
    
    var choosenLongitude = Double()
    var choosenLatitude = Double()
    var flag = Bool()
    var locationManager = CLLocationManager()
    
    var annonationLongitude = Double()
    var annonationLatitude = Double()
    
    
    //Yeni bir kayıt mı atıyoruz yoksa listviewerden mi tıklandı ?
    var selectedName = ""
    var selectedId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        
        //Doğruluk oranı. Pil ömrünü uzatmak için kilometerde seçilebilir.
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        //Uygulamayı kullanırken lokasyonunu görmek için izin talebi
        locationManager.requestWhenInUseAuthorization()
        
        //Lokasyonu almaya başla
        locationManager.startUpdatingLocation()
        
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        
        //Kaç saniye basılı durulduğunda algılasın
        gestureRecognizer.minimumPressDuration = 2
        
        mapView.addGestureRecognizer(gestureRecognizer)
        
        
        //Yeni bir kayıt mı atıyoruz yoksa listviewerden mi tıklandı ?
        
        if selectedName != "" {
            
            //Save butonunu inaktif et
            //saveButton.isEnabled = false
            
            //Save butonunu sakla
            saveButton.isHidden = true
            
            // CoreDatadan seçilen satırı çek.
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Locations")
            
            let idString = selectedId?.uuidString
            
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString!)
            
            fetchRequest.returnsObjectsAsFaults = false
            
            
            do{
                let results = try context.fetch(fetchRequest)
                
                if results.count > 0{
                    
                    for result in results as! [NSManagedObject] {
                        
                        if let name = result.value(forKey: "name") as? String{
                            nameText.text = name
                            if let note = result.value(forKey: "note") as? String{
                                noteText.text = note
                                if let latitude = result.value(forKey: "latitude") as? Double{
                                    annonationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double{
                                        annonationLongitude = longitude
                                        
                                        let annonation = MKPointAnnotation()
                                        
                                        annonation.title = name
                                        annonation.subtitle = note
                                        
                                        let coordinate =  CLLocationCoordinate2D(latitude: annonationLatitude, longitude: annonationLongitude)
                                        
                                        annonation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annonation)
                                        
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                        
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        
                                        mapView.setRegion(region, animated: true)
                                        
                                        
                                        
                                        
                                    }
                                }
                            }
                        }
                    }
                }
                
            }catch{
                
                
            }
            
            
        }else{
            // New data
            
        }
        
        let keyboardGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(keyboardGesture)
    }
    
    @objc func hideKeyboard(){
        
        view.endEditing(true)
    }
    
    @objc func chooseLocation(gestureRecognizer : UILongPressGestureRecognizer) {
        
        if let name = nameText.text{
            
            if name.isEmpty{
                flag = true
                alertPop(title: "Error", message: "Enter name before pick the location")
            }else{
                if gestureRecognizer.state == .began {
                    
                    //Dokunulan noktayı algılar
                    let touchedPoint = gestureRecognizer.location(in: self.mapView)
                    
                    //Dokunulan noktayı koordinata çevirir.
                    let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
                    
                    choosenLatitude = touchedCoordinates.latitude
                    choosenLongitude = touchedCoordinates.longitude
                    
                    //Bayrak koyma
                    let annotation = MKPointAnnotation()
                    
                    //Koordinatı aktar
                    annotation.coordinate = touchedCoordinates
                    
                    //Ana başlık
                    annotation.title = nameText.text
                    
                    //Alt başlık
                    annotation.subtitle = noteText.text
                    
                    self.mapView.addAnnotation(annotation)
                    
                }
            }
            
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if selectedName == ""{
            //Enlem - Boylam
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            
            //Zoom oranı
            let span = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
            
            //Bölge
            let region = MKCoordinateRegion(center: location, span: span)
            
            mapView.setRegion(region, animated: true)
            
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        
        if selectedName != ""{
            
            let requestLocation = CLLocation(latitude: annonationLatitude, longitude: annonationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                //closuref
                
                if let placemark = placemarks{
                    
                    if placemark.count > 0 {
                        
                        let newPlaceMark = MKPlacemark(placemark: placemark[0])
                        
                        let item = MKMapItem(placemark: (newPlaceMark))
                        
                        item.name = self.selectedName
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions )
                        
                    }
                    
                }
                
                
            }
            
        }
        
    }
    
    @IBAction func saveButton(_ sender: Any) {
        
        if let name = nameText.text{
            
            if name.isEmpty{
                flag = true
                alertPop(title: "Error", message: "Name can not be empty")
            }
        }
        
        if !flag == true{
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            let context = appDelegate.persistentContainer.viewContext
            
            let newLocations = NSEntityDescription.insertNewObject(forEntityName: "Locations", into: context)
            
            newLocations.setValue(nameText.text, forKey: "name")
            newLocations.setValue(noteText.text, forKey: "note")
            newLocations.setValue(choosenLatitude, forKey: "latitude")
            newLocations.setValue(choosenLongitude, forKey: "longitude")
            newLocations.setValue(UUID(), forKey: "id")
            
            do{
                try context.save()
                print("success")
            }catch{
                print("error")
                
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("newData"), object: nil)
            
            self.navigationController?.popViewController(animated: true)
            
        }
        
    }
    
    func alertPop(title:String,message:String){
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        
        alert.addAction(okButton)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
}

