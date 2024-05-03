//
//  Helper.swift
//  Messenger
//
//  Created by Ritik Srivastava on 12/10/20.
//  Copyright © 2020 Ritik Srivastava. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

class Helper {
    
    class func error(title: String , message:String)-> UIAlertController {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            alert.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(okAction)
        
        return alert
    }
    
    
    class func loginSignError(error: Error , title: String )-> UIAlertController {
        
        var errorTitle: String = "\(title) Error"
        
        var errorMessage : String = "There was a problem \(title)ing in"
        
        if let errorCode = AuthErrorCode(rawValue: error._code) {
            
            switch errorCode {
            
            case .wrongPassword :
                errorTitle = "Wrong password"
                errorMessage = "Password you entered is wrong! "
                
            case .invalidEmail :
                errorTitle = "Email Invalid"
                errorMessage = "Email you entered is wrong! "
            
            case .weakPassword :
                errorTitle = "Password Weak"
                errorMessage = "Password is weak! "
                
            case .emailAlreadyInUse :
                errorTitle = "Email is Already in use"
                errorMessage = "Please provide a different email ! "

            default :
                break
            }
        }
        
        let alert = Helper.error(title: errorTitle, message: errorMessage)
        return alert
    }

}


extension Helper {
    // for getting current userid
    class func uniqueId()->String?{
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return uid
    }
    
}
