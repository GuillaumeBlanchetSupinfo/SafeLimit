//
//  GeolocationViewController.swift
//  SafeLimit
//
//  Created by DotVision DotVision on 22/03/2020.
//  Copyright © 2020 Guillaume Blanchet. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

struct PreferencesKeys {
    static let savedItems = "savedItems"
}

class GeolocationsViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!

    var geotifications: [Geolocation] = []
    var locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        loadAllGeotifications()
        mapView.showsUserLocation = CLLocationManager.authorizationStatus() == .authorizedWhenInUse
        for g in geotifications {
            startMonitoring(geotification: g)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addGeotification" {
            let navigationController = segue.destination as! UINavigationController
            let vc = navigationController.viewControllers.first as! AddGeolocationViewController
            vc.delegate = self
        }
    }

  // MARK: Loading and saving functions
    func loadAllGeotifications() {
        geotifications.removeAll()
        let allGeotifications = Geolocation.allGeolocations()
        allGeotifications.forEach { add($0) }
    }
  
    func saveAllGeolocations() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(geotifications)
            UserDefaults.standard.set(data, forKey: PreferencesKeys.savedItems)
        } catch {
            print("error encoding geotifications")
        }
    }

  // MARK: Functions that update the model/associated views with geotification changes
    func add(_ geotification: Geolocation) {
        geotifications.append(geotification)
        mapView.addAnnotation(geotification)
        addRadiusOverlay(forGeotification: geotification)
        updateGeotificationsCount()
    }

    func remove(_ geotification: Geolocation) {
        guard let index = geotifications.firstIndex(of: geotification) else { return }
        geotifications.remove(at: index)
        mapView.removeAnnotation(geotification)
        removeRadiusOverlay(forGeotification: geotification)
        updateGeotificationsCount()
    }

    func updateGeotificationsCount() {
        title = "Safe Zone: \(geotifications.count)"
        navigationItem.rightBarButtonItem?.isEnabled = (geotifications.count < 20)
    }

  // MARK: Map overlay functions
    func addRadiusOverlay(forGeotification geotification: Geolocation) {
        mapView?.addOverlay(MKCircle(center: geotification.coordinate, radius: geotification.radius))
    }
  
    func removeRadiusOverlay(forGeotification geotification: Geolocation) {
        // Find exactly one overlay which has the same coordinates & radius to remove
        guard let overlays = mapView?.overlays else { return }
        for overlay in overlays {
            guard let circleOverlay = overlay as? MKCircle else { continue }
            let coord = circleOverlay.coordinate
            if coord.latitude == geotification.coordinate.latitude && coord.longitude == geotification.coordinate.longitude && circleOverlay.radius == geotification.radius {
                mapView?.removeOverlay(circleOverlay)
                break
            }
        }
    }
  
  // MARK: Other mapview functions
    @IBAction func zoomToCurrentLocation(sender: AnyObject) {
      mapView.zoomToUserLocation()
    }
  
    func region(with geotification: Geolocation) -> CLCircularRegion {
        let region = CLCircularRegion(center: geotification.coordinate, radius: geotification.radius, identifier: geotification.identifier)
        region.notifyOnEntry = (geotification.eventType == .onEntry)
        region.notifyOnExit = !region.notifyOnEntry
        return region
    }
  
    func startMonitoring(geotification: Geolocation) {
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            showAlert(withTitle:"Error", message: "Geofencing is not supported on this device!")
            return
        }

        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            let message = """
            Your geotification is saved but will only be activated once you grant
            Geotify permission to access the device location.
            """
            showAlert(withTitle:"Warning", message: message)
        }

        let fenceRegion = region(with: geotification)
        locationManager.startMonitoring(for: fenceRegion)
    }

    func stopMonitoring(geotification: Geolocation) {
        for region in locationManager.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == geotification.identifier else { continue }
            locationManager.stopMonitoring(for: circularRegion)
        }
    }
}

// MARK: AddGeotificationViewControllerDelegate
extension GeolocationsViewController: AddGeolocationsViewControllerDelegate {
    func addGeotificationViewController(_ controller: AddGeolocationViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: Geolocation.EventType) {
        controller.dismiss(animated: true, completion: nil)
        let clampedRadius = min(radius, locationManager.maximumRegionMonitoringDistance)
        let geotification = Geolocation(coordinate: coordinate, radius: clampedRadius, identifier: identifier, note: note, eventType: eventType)
        add(geotification)
        startMonitoring(geotification: geotification)
        saveAllGeolocations()
    }
}

// MARK: - Location Manager Delegate
extension GeolocationsViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        mapView.showsUserLocation = status == .authorizedWhenInUse
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for region with identifier: \(region!.identifier)")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with the following error: \(error)")
    }
}

// MARK: - MapView Delegate
extension GeolocationsViewController: MKMapViewDelegate {
  
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "myGeotification"
        if annotation is Geolocation {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                let removeButton = UIButton(type: .custom)
                removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
                removeButton.setImage(UIImage(named: "DeleteGeotification")!, for: .normal)
                annotationView?.leftCalloutAccessoryView = removeButton
            } else {
                annotationView?.annotation = annotation
            }
            return annotationView
        }
        return nil
    }
  
  
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.lineWidth = 1.0
            circleRenderer.strokeColor = .systemRed
            circleRenderer.fillColor = UIColor.systemRed.withAlphaComponent(0.4)
            return circleRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
  
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // Delete geotification
        let geolocation = view.annotation as! Geolocation
        remove(geolocation)
        saveAllGeolocations()
    }
}

