//
//  extension.swift
//  Messenger
//
//  Created by Ritik Srivastava on 12/10/20.
//  Copyright © 2020 Ritik Srivastava. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    public var width : CGFloat {
        return self.frame.size.width
    }
    
    public var height : CGFloat {
        return self.frame.size.height
    }
    
    public var top : CGFloat {
        return self.frame.origin.y
    }
    
    public var bottom : CGFloat {
        return self.frame.size.height + self.frame.origin.y
    }
    
    public var left : CGFloat {
        return self.frame.origin.x
    }
    
    public var right : CGFloat {
        return self.frame.size.width + self.frame.origin.x
    }
}


//to add spiner view in viewcontroller
extension UIViewController {
     
    class func displayLoading(withView: UIView) -> UIView{
        
        //to make cover all cuurent view
        let spinnerView = UIView.init(frame: withView.frame)
        
        spinnerView.backgroundColor = UIColor.clear
        
        let ActvitySpinner = UIActivityIndicatorView.init(style: .medium)
        
        ActvitySpinner.startAnimating()
        
        ActvitySpinner.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ActvitySpinner)
            
            withView.addSubview(spinnerView)
        }
        
        return spinnerView
    }
    
    class func removingLoading(spinner : UIView) {
        
        DispatchQueue.main.async {
            spinner.removeFromSuperview()
        }
        
    }
    
}


extension Notification.Name {
    static let didLogInNotificationByGoogle  = Notification.Name("didLogInNotificationByGoogle")
}

//MARK: To convert hex color in UIcolor
extension UIColor {
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }

        return nil
    }
}
