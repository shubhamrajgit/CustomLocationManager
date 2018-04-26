//
//  PAHLocationManager.swift
//  DevelopAll
//
//  Created by shubham on 3/30/17.
//  Copyright © 2017 SS. All rights reserved.
//

import UIKit
import CoreLocation
import ObjectMapper

protocol LocationServiceDelegate {
    func tracingLocation(currentLocation: CLLocation)
    func tracingLocationDidFailWithError(error: NSError)
    func tracingLocationAccessDenied()
    
    }

class LocationSingleton: NSObject,CLLocationManagerDelegate {
    var locationManager: CLLocationManager?
    var lastLocation: CLLocation?
    var delegate: LocationServiceDelegate?
    var currPlacemark : LocationModel?
    let baseUrl = "https://maps.googleapis.com/maps/api/geocode/json?address="
//    let apikey = "AIzaSyAxfHBGo2wHbuCwzXi79ecrU73e7OVXlG8"
    
    static let sharedInstance:LocationSingleton = {
        let instance = LocationSingleton()
        return instance
    }()
    
    override init() {
        super.init()
        self.locationManager = CLLocationManager()

        guard let locationManagers=self.locationManager else {
            return
        }
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            
            locationManagers.requestWhenInUseAuthorization()
        }
        if #available(iOS 9.0, *) {
            //            locationManagers.allowsBackgroundLocationUpdates = true
        } else {
            // Fallback on earlier versions
        }
        locationManagers.desiredAccuracy = kCLLocationAccuracyBest
        locationManagers.pausesLocationUpdatesAutomatically = false
        locationManagers.distanceFilter = 0.1
        locationManagers.delegate = self
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        self.lastLocation = location
        updateLocation(currentLocation: location)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager?.requestAlwaysAuthorization()
            break
        case .authorizedWhenInUse:
            locationManager?.startUpdatingLocation()
            break
        case .authorizedAlways:
            locationManager?.startUpdatingLocation()
            break
        case .restricted:
            // restricted by e.g. parental controls. User can't enable Location Services
            break
        case .denied:
            delegate?.tracingLocationAccessDenied()
            // user denied your app access to Location Services, but can grant access from Settings.app
            break
        default:
            break
        }
    }
    
    
    
    // Private function
    private func updateLocation(currentLocation: CLLocation){
        
        guard let delegate = self.delegate else {
            return
        }
        
        delegate.tracingLocation(currentLocation: currentLocation)
    }
    
    private func updateLocationDidFailWithError(error: NSError) {
        
        guard let delegate = self.delegate else {
            return
        }
        
        delegate.tracingLocationDidFailWithError(error: error)
    }
    
    func startUpdatingLocation() {
        print("Starting Location Updates")

        self.locationManager?.startUpdatingLocation()
        //        self.locationManager?.startMonitoringSignificantLocationChanges()
    }
    
    func stopUpdatingLocation() {
        print("Stop Location Updates")
        self.locationManager?.stopUpdatingLocation()
    }
    
    func startMonitoringSignificantLocationChanges() {
        self.locationManager?.startMonitoringSignificantLocationChanges()
    }
    
    // #MARK:   get the alarm time from date and time
    
    func getLatLngForZip(ZipCode: String, completionHandlerNew: @escaping GeolCompletionBlock) {
        
        let url = NSURL(string: "\(baseUrl)\(ZipCode)")
        let data = NSData(contentsOf: url! as URL)
        let json = try! JSONSerialization.jsonObject(with: data! as Data, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
        var lat = ""
        var long = ""
        if let result = json["results"] as? NSArray{
            if result.count > 0{
                let resultFirst = result.lastObject as! [String:Any]
                let geomatry = resultFirst["geometry"] as! [String:Any]
                let coordinates = geomatry["location"] as! [String: Float]
                lat = "\(coordinates["lat"]!)"
                long = "\(coordinates["lng"]!)"
        }
        }
        print("respnse is \(json)")
        
        let locationObjectArray  = Mapper<GoogleAPIModel>().mapArray(JSONArray: json["results"] as! [[String:Any]])
        if (locationObjectArray?.count)! > 0{
            var City = ""
            var State = ""
            var zipCode = ""
            var str = ""
            
            for comp in (locationObjectArray![0].addressComponent){
                
                if comp.type[0] == "postal_code" && comp.long_name == ZipCode{
                    zipCode = comp.long_name!
                }
                
                if comp.type[0] == "locality"{
                    City = comp.long_name!
                }
                else if City == "" && comp.type[0] == "administrative_area_level_2"{
                    City = comp.long_name!
                }
                
                if comp.type[0] == "administrative_area_level_1"{
                    State = comp.long_name!
                }
                
            }
            
            if  zipCode != ZipCode{
                completionHandlerNew(nil,false,"Please enter a valid Zip Code")
            }
            else {
                if City != "" && State != ""{
                    str = City + " " + State
                }
                else if City == ""{
                    str = State
                }
                else if State == ""{
                    str = City
                }
                if zipCode != "" && str != ""{
                    str = str + ", " + zipCode
                }
                
                let locModel = LocationModel(withLatitude: lat, longitude: long, location: str, State: State )
                completionHandlerNew(locModel,true,nil)
            }

            
        }
        else{
            completionHandlerNew(nil,false,"Please enter a valid Zip Code")
        }
    }
    
    func getLocationFromCoordinates(latitude: String,longitude: String, completionHandlerNew: @escaping GeolCompletionBlock){
        let url = NSURL(string: "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(latitude),\(longitude)&sensor=true)")
        let data = NSData(contentsOf: url! as URL)
        let json = try! JSONSerialization.jsonObject(with: data! as Data, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
        print("respnse is \(json)")
        let locationObjectArray  = Mapper<GoogleAPIModel>().mapArray(JSONArray: json["results"] as! [[String:Any]])
        if (locationObjectArray?.count)! > 0{
            var City = ""
            var State = ""
            var zipCode = ""
            var str = ""
            
            for comp in (locationObjectArray?[0].addressComponent)!{
                
                if comp.type[0] == "locality"{
                    City = comp.long_name!
                }
                else if City == "" && comp.type[0] == "administrative_area_level_2"{
                    City = comp.long_name!
                }
                
                if comp.type[0] == "administrative_area_level_1"{
                    State = comp.long_name!
                }
                
                if comp.type[0] == "postal_code"{
                    zipCode = comp.long_name!
                }
                
            }
            
            if City != "" && State != ""{
                str = City + " " + State
            }
            else if City == ""{
                str = State
            }
            else if State == ""{
                str = City
            }
            if zipCode != "" && str != ""{
                str = str + ", " + zipCode
            }
            
            let locModel = LocationModel(withLatitude: latitude, longitude: longitude, location: str, State: State )
            completionHandlerNew(locModel,true,nil)

            
        }
        else{
            completionHandlerNew(nil,false,"Invalid Location")
        }
    }
    
    //MARK: - get set current placemark
    func checkForCurrentPlacemark(completion : @escaping  CommonCompletionBlock){
        if self.currPlacemark != nil{
            completion(true , nil)
        }
        
        if(!PAHUtils .isInternetAvailable()){
            completion(false , Network_Mesage)
            return;
        }
        
        LocationSingleton.sharedInstance.getLocationFromCoordinates(latitude: PAHUtils.getLoginUserModel().lat!, longitude: PAHUtils.getLoginUserModel().long!) { (
            response, success, error) in
            if error != nil {
                completion(false,error)
            }
            else {
                self.currPlacemark = response
                completion(true , nil)
            }

        }
    }
    
    func getCurrentPlacemark(completion : @escaping  GeolCompletionBlock){
        if self.currPlacemark?.location?.characters.count == 0{
            
            LocationSingleton.sharedInstance.getLocationFromCoordinates(latitude: PAHUtils.getLoginUserModel().lat!, longitude: PAHUtils.getLoginUserModel().long!) { (
                response, success, error) in
                if error != nil {
                    completion(nil,false,error)
                }
                else {
                    self.currPlacemark = response
                    completion(self.currPlacemark,true,nil)
                }
                
            }
        }
        else{
            completion(self.currPlacemark,true,nil)
        }
    }
}
