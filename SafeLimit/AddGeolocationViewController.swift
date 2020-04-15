//
//  AddGeolocationViewController.swift
//  SafeLimit
//
//  Created by DotVision DotVision on 22/03/2020.
//  Copyright © 2020 Guillaume Blanchet. All rights reserved.
//

import UIKit
import MapKit

protocol AddGeolocationsViewControllerDelegate {
  func addGeotificationViewController(_ controller: AddGeolocationViewController, didAddCoordinate coordinate: CLLocationCoordinate2D,
                                      radius: Double, identifier: String, note: String, eventType: Geolocation.EventType)
}

class AddGeolocationViewController: UITableViewController, UITextFieldDelegate {
  
  @IBOutlet var addButton: UIBarButtonItem!
  @IBOutlet var zoomButton: UIBarButtonItem!
    @IBOutlet weak var eventTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var radiusTextField: UITextField!
    @IBOutlet weak var noteTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
  
  var delegate: AddGeolocationsViewControllerDelegate?
  
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        radiusTextField.delegate = self
        noteTextField.delegate = self
        navigationItem.rightBarButtonItems = [addButton, zoomButton]
        addButton.isEnabled = false
    }

    @IBAction func textFieldEditingChanged(sender: UITextField) {
      addButton.isEnabled = !radiusTextField.text!.isEmpty && !noteTextField.text!.isEmpty
    }
    
    @IBAction func onCancel(sender: AnyObject) {
      dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func onAdd(sender: AnyObject) {
      let coordinate = mapView.centerCoordinate
      let radius = Double(radiusTextField.text!) ?? 0
      let identifier = NSUUID().uuidString
      let note = noteTextField.text
      let eventType: Geolocation.EventType = (eventTypeSegmentedControl.selectedSegmentIndex == 0) ? .onEntry : .onExit
      delegate?.addGeotificationViewController(self, didAddCoordinate: coordinate, radius: radius, identifier: identifier, note: note!, eventType: eventType)
    }

    @IBAction private func onZoomToCurrentLocation(sender: AnyObject) {
      mapView.zoomToUserLocation()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
}
