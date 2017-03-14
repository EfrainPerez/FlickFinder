//
//  ViewController.swift
//  FlickFinder
//
//  Created by Jarrod Parkes on 11/5/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import UIKit

// MARK: - ViewController: UIViewController

class ViewController: UIViewController {
    
    // MARK: Properties
    
    var keyboardOnScreen = false
    // MARK: Outlets
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoTitleLabel: UILabel!
    @IBOutlet weak var phraseTextField: UITextField!
    @IBOutlet weak var phraseSearchButton: UIButton!
    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    @IBOutlet weak var latLonSearchButton: UIButton!
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        phraseTextField.delegate = self
        latitudeTextField.delegate = self
        longitudeTextField.delegate = self
        subscribeToNotification(.UIKeyboardWillShow, selector: #selector(keyboardWillShow))
        subscribeToNotification(.UIKeyboardWillHide, selector: #selector(keyboardWillHide))
        subscribeToNotification(.UIKeyboardDidShow, selector: #selector(keyboardDidShow))
        subscribeToNotification(.UIKeyboardDidHide, selector: #selector(keyboardDidHide))
    }
    
    private func checkReachability() ->Bool{
        var connectedToInternet : Bool = true
        
        if currentReachabilityStatus == .notReachable {
            connectedToInternet = false
            let alert = UIAlertController(title: "Alert", message: "Please Connect to Internet", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {
                (action) in alert.dismiss(animated: true, completion: nil)
            }))
            self.present(alert,animated:true,completion: nil)
        }
        //print("si hay")
        return connectedToInternet
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromAllNotifications()
    }
    
    // MARK: Search Actions
    
    @IBAction func searchByPhrase(_ sender: AnyObject) {
        if checkReachability(){
            let withPageNumber: Int? = nil
            userDidTapView(self)
            setUIEnabled(false)
            if !phraseTextField.text!.isEmpty {
                photoTitleLabel.text = "Searching..."
                // TODO: Set necessary parameters!
                let methodParameters: [String: AnyObject] =
                    [Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch as AnyObject,
                     Constants.FlickrParameterKeys.Text : phraseTextField.text! as AnyObject,
                     Constants.FlickrParameterKeys.Extras : Constants.FlickrParameterValues.MediumURL as AnyObject,
                     Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey as AnyObject,
                     Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod as AnyObject,
                     Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat as AnyObject,
                     Constants.FlickrParameterKeys.NoJSONCallback : Constants.FlickrParameterValues.DisableJSONCallback as AnyObject
                ]
                displayImageFromFlickrBySearch(methodParameters,withPageNumber)
            } else {
                setUIEnabled(true)
                photoTitleLabel.text = "Phrase Empty."
            }
        }
        
    }
    
    @IBAction func searchByLatLon(_ sender: AnyObject) {
        if checkReachability(){
            let withPageNumber: Int? = nil
            userDidTapView(self)
            setUIEnabled(false)
            if isTextFieldValid(latitudeTextField, forRange: Constants.Flickr.SearchLatRange) && isTextFieldValid(longitudeTextField, forRange: Constants.Flickr.SearchLonRange) {
                photoTitleLabel.text = "Searching..."
                // TODO: Set necessary parameters!
                
                let methodParameters: [String: AnyObject] =
                    [Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch as AnyObject,
                     Constants.FlickrParameterKeys.BoundingBox: bboxString() as AnyObject,
                     Constants.FlickrParameterKeys.Extras : Constants.FlickrParameterValues.MediumURL as AnyObject,
                     Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey as AnyObject,
                     Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod as AnyObject,
                     Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat as AnyObject,
                     Constants.FlickrParameterKeys.NoJSONCallback : Constants.FlickrParameterValues.DisableJSONCallback as AnyObject
                ]
                displayImageFromFlickrBySearch(methodParameters, withPageNumber)
            }
            else {
                setUIEnabled(true)
                photoTitleLabel.text = "Lat should be [-90, 90].\nLon should be [-180, 180]."
            }
        }
        
        
    }
    
    private func bboxString() -> String{
        if let latitud = Double(self.latitudeTextField.text!), let longitud = Double(self.longitudeTextField.text!){
            let minLongitude = max(longitud - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
            let minLatitud = max(latitud - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
            let maxLongitude = min(longitud + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
            let maxLatiud = min(latitud + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
            return "\(minLongitude),\(minLatitud),\(maxLongitude),\(maxLatiud)"
        }else{
            return "0,0,0,0"
        }
    }
    
    // MARK: Flickr API
    
     func displayImageFromFlickrBySearch(_ methodParameters: [String: AnyObject],_ withPageNumber: Int?) {
        
        //print(flickrURLFromParameters(methodParameters))
        // TODO: Make request to Flickr!
        // create session and request
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
//            if error == nil {
//                print(data?.base64EncodedData() ?? "No hay nada")
//            } else {
//                print(error!.localizedDescription)
//            }
            
            func displayError(_ error: String) {
                print(error)
                print("URL at time of error: \(flickrURLFromParameters(methodParameters))")
                performUIUpdatesOnMain {
                    self.setUIEnabled(true)
                    self.photoTitleLabel.text = "No Photo Returned."
                    self.photoImageView.image = nil
                }
            }
            
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            //print(parsedResult)
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject], let photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                displayError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' and '\(Constants.FlickrResponseKeys.Photo)' in \(parsedResult)")
                return
            }
            
            
            
            if photoArray.count <= 0{
                displayError("There is not Photo with this Title")
                return
            }
            
            if withPageNumber == nil{
                guard let numberOfPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                    displayError("Cannot find keys \(Constants.FlickrResponseKeys.Pages)")
                    return
                }
                let pageLimit = min(numberOfPages, 40)
                let randomPage = (Int(arc4random_uniform(UInt32(pageLimit))) + 1)
                var methodParametersWithPageNumber = methodParameters
                methodParametersWithPageNumber[Constants.FlickrParameterKeys.Page] = randomPage as AnyObject?
                self.displayImageFromFlickrBySearch(methodParametersWithPageNumber, randomPage)
                return
            }
            print(flickrURLFromParameters(methodParameters))
            let randomIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
            let randomPhoto = photoArray[randomIndex] as [String:AnyObject]
            let photoTitle = randomPhoto[Constants.FlickrResponseKeys.Title] as? String
            
            guard let imageUrlString = randomPhoto[Constants.FlickrResponseKeys.MediumURL] as? String else{
                displayError("Cannot find key '\(Constants.FlickrResponseKeys.MediumURL)' in \(randomPhoto)")
                return
            }
            
            // if an image exists at the url, set the image and title
            let imageURL = URL(string: imageUrlString)
            if let imageData = try? Data(contentsOf: imageURL!) {
                performUIUpdatesOnMain {
                    self.setUIEnabled(true)
                    self.photoImageView.image = UIImage(data: imageData)
                    self.photoTitleLabel.text = photoTitle ?? "(Untitled)"
                }
            } else {
                displayError("Image does not exist at \(imageURL)")
            }

        }
        task.resume()
    }
    }
    
    // MARK: Helper for Creating a URL from Parameters
    
    private func flickrURLFromParameters(_ parameters: [String: AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }


// MARK: - ViewController: UITextFieldDelegate

extension ViewController: UITextFieldDelegate {
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: Show/Hide Keyboard
    
    func keyboardWillShow(_ notification: Notification) {
        if !keyboardOnScreen {
            view.frame.origin.y -= keyboardHeight(notification)
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        if keyboardOnScreen {
            view.frame.origin.y += keyboardHeight(notification)
        }
    }
    
    func keyboardDidShow(_ notification: Notification) {
        keyboardOnScreen = true
    }
    
    func keyboardDidHide(_ notification: Notification) {
        keyboardOnScreen = false
    }
    
    func keyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = (notification as NSNotification).userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    func resignIfFirstResponder(_ textField: UITextField) {
        if textField.isFirstResponder {
            textField.resignFirstResponder()
        }
    }
    
    @IBAction func userDidTapView(_ sender: AnyObject) {
        resignIfFirstResponder(phraseTextField)
        resignIfFirstResponder(latitudeTextField)
        resignIfFirstResponder(longitudeTextField)
    }
    
    // MARK: TextField Validation
    
    func isTextFieldValid(_ textField: UITextField, forRange: (Double, Double)) -> Bool {
        if let value = Double(textField.text!), !textField.text!.isEmpty {
            return isValueInRange(value, min: forRange.0, max: forRange.1)
        } else {
            return false
        }
    }
    
    func isValueInRange(_ value: Double, min: Double, max: Double) -> Bool {
        return !(value < min || value > max)
    }
}

// MARK: - ViewController (Configure UI)

private extension ViewController {
    
     func setUIEnabled(_ enabled: Bool) {
        photoTitleLabel.isEnabled = enabled
        phraseTextField.isEnabled = enabled
        latitudeTextField.isEnabled = enabled
        longitudeTextField.isEnabled = enabled
        phraseSearchButton.isEnabled = enabled
        latLonSearchButton.isEnabled = enabled
        
        // adjust search button alphas
        if enabled {
            phraseSearchButton.alpha = 1.0
            latLonSearchButton.alpha = 1.0
        } else {
            phraseSearchButton.alpha = 0.5
            latLonSearchButton.alpha = 0.5
        }
    }
}

// MARK: - ViewController (Notifications)

private extension ViewController {
    
    func subscribeToNotification(_ notification: NSNotification.Name, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: notification, object: nil)
    }
    
    func unsubscribeFromAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}
