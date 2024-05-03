//
//  LoginViewController.swift
//  Messenger
//
//  Created by Ritik Srivastava on 11/10/20.
//  Copyright © 2020 Ritik Srivastava. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import GoogleSignIn

class LoginViewController: UIViewController {

    private var imageView : UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "Logo")
        image.contentMode = .scaleAspectFit
        return image
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let emailField : UITextField = {
        let email = UITextField()
        
        email.autocapitalizationType = .none
        email.autocorrectionType = .no
        email.backgroundColor = .white
        email.layer.cornerRadius = 12
        email.layer.borderWidth = 1
        email.layer.borderColor = UIColor.lightGray.cgColor
        email.placeholder = "Email Address ..."
        email.returnKeyType = .continue
        //to clear side buffer because text and border touches at left
        email.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        email.leftViewMode = .always
        
        return email
    }()
    
    
    private let passwordField : UITextField = {
        let password = UITextField()
        
        password.autocapitalizationType = .none
        password.autocorrectionType = .no
        password.returnKeyType = .done
        password.backgroundColor = .white
        password.layer.cornerRadius = 12
        password.layer.borderWidth = 1
        password.layer.borderColor = UIColor.lightGray.cgColor
        password.placeholder = "Password ..."
        password.isSecureTextEntry = true
        //to clear side buffer because text and border touches at left
        password.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        password.leftViewMode = .always
        return password
    }()
    
    
    private let LoginButton : UIButton = {
        let button = UIButton()
        
        button.setTitle("Login", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.addTarget(self,action: #selector(LoginButtonDidTouch), for: .touchUpInside)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let facebookloginButton : FBLoginButton = {
        let button  = FBLoginButton()
        button.permissions = ["email,public_profile"]
        return button
    }()
    
    private let GoogleloginButton : GIDSignInButton = {
        let button  = GIDSignInButton()
        return button
    }()
    
    private var loginObserver : NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Log In"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(registerButtonDidTouch))
        // Do any additional setup after loading the view.
        
        emailField.delegate = self
        passwordField.delegate = self
        
        facebookloginButton.delegate = self
        
        //observer for getting to chat view controller since it is in google
        loginObserver = NotificationCenter.default.addObserver(forName:  Notification.Name.didLogInNotificationByGoogle,
                                                               object: nil,
                                                               queue: .main) { [weak self] _ in
                                                                guard let strongSelf = self else { return }
                                                                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
        GIDSignIn.sharedInstance()?.presentingViewController = self
        
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(LoginButton)
        
        //adding google button
        scrollView.addSubview(GoogleloginButton)
        
        //adding facebook button
        scrollView.addSubview(facebookloginButton)
        
    }
    
    //de inrialize observer
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        scrollView.frame = view.bounds
        
        let size = view.frame.size.width / 3;
        imageView.frame = CGRect(x: (view.frame.size.width-size)/2, y: 20, width: size, height: size)
        
        emailField.frame = CGRect(x: 30, y: imageView.bottom+10, width: scrollView.width-60, height: 52)
        
        passwordField.frame = CGRect(x: 30, y: emailField.bottom+15, width: scrollView.width-60, height: 52)
        
        LoginButton.frame = CGRect(x: 30, y: passwordField.bottom+20, width: scrollView.width-60, height: 52)
        
        GoogleloginButton.frame = CGRect(x: 30, y: LoginButton.bottom+20, width: scrollView.width-60, height: 52)
        
        facebookloginButton.frame = CGRect(x: 30, y: GoogleloginButton.bottom+20, width: scrollView.width-60, height: 52)
    }
    
    
    @objc func registerButtonDidTouch(){
        print("register clecked")
        
        let vc = RegisterViewController()
        
        vc.title = "Register"
        
        navigationController?.pushViewController(vc, animated: true)
    }

    
    @objc func LoginButtonDidTouch(){
        print("Login is clicked")
        
        //get rid of keyboard
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text  , let password = passwordField.text ,!email.isEmpty ,!password.isEmpty , password.count>=6  else {
            let error = Helper.error(title: "Email or Password Invalid", message: "Please retry to fill!")
            present(error, animated:  true)
            return
        }
        
        //firebase login
        let spinner = UIViewController.displayLoading(withView: self.view)
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (result, error) in
            guard let strongSelf = self else { return }
            
            if error == nil {
                DispatchQueue.main.async {
                    //remove spinner
                    UIViewController.removingLoading(spinner: spinner)
                }
                print("enter to database")
                
                // it is used to chache the email locally with this key
                UserDefaults.standard.set(email, forKey: "email")
                
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
                
            else if let error = error{
                DispatchQueue.main.async {
                    UIViewController.removingLoading(spinner: spinner)
                }
                let alertError = Helper.loginSignError(error: error , title: "Email or password is invalid")
                DispatchQueue.main.async {
                    strongSelf.present(alertError , animated: true)
                }
            }
        }
        
    }
    
}

//MARK: this help on clicking enter in the text it will goes to other field we can also do textEditing
extension LoginViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if passwordField == passwordField {
            LoginButtonDidTouch()
        }
        return true
    }
    
}

//MARK: For facebook login button delegate
extension LoginViewController : LoginButtonDelegate {
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        
        guard let token = result?.token?.tokenString else {
            return
        }
        
        //take the name photo and email from facebook
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields" :
                                                            "email,name,picture.type(large)"
                                                            ],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        
        facebookRequest.start { [weak self] (_, result , error) in
            
            guard let strongSelf = self else { return }
            
            guard let result = result as? [String : Any] , error == nil else {
                print("Failed to get data request")
                return
            }
            
            print("\(result)")
            
            guard
                let username = result["name"] as? String ,
                let email = result["email"] as? String,
                let image = result["picture"] as? [String : Any],
                let data = image["data"] as? [String : Any] ,
                let imageUrl = data["url"] as? String else {
                print("email and username is not found")
                let errorAlert = Helper.error(title: "facebook login failed", message: "no email is found")
                DispatchQueue.main.async {
                    strongSelf.present(errorAlert , animated: true)
                }
                //logout facebook if some error occured
                FBSDKLoginKit.LoginManager().logOut()
                return
            }
            strongSelf.fillUserDetailFirebase(username: username, email: email, token: token , imageUrl : imageUrl)
        }
        
        
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        //nothing
    }
    
    
    func fillUserDetailFirebase(username:String , email: String , token : String , imageUrl :String){
        
        // it is used to chache the username and email locally with this key
        UserDefaults.standard.set(username, forKey: "username")
        UserDefaults.standard.set(email, forKey: "email")
        
        let chatUser = ChatAppUser(username: username, email: email)
        
        DatabaseManager.shared.insertUser(with: chatUser , completion: { sucess in
            if sucess {
                guard let url = URL(string : imageUrl) else { return }
                
                URLSession.shared.dataTask(with: url, completionHandler: { (data, _ , _) in
                    guard let data = data else { return }
                    
                    print("image upload sucesfully")

                    let filename = chatUser.profileImageFileName

                    StorageManager.shared.uploadProfilePicture(with: data, filename: filename) { (result) in
                        switch result {
                        case .failure(let error):
                            print(error)
                        case .success(let downloadUrl):
                            // it is used to chache the downloadUrl locally with this key
                            UserDefaults.standard.set(downloadUrl, forKey: "profile_pic")
                            print(downloadUrl)
                        }
                    }
                    
                }).resume()
            }
            
        })
        
        let credential = FacebookAuthProvider.credential(withAccessToken: token)
        
        Auth.auth().signIn(with: credential) { [weak self] (result, error) in
            
            guard let strongSelf = self else { return }
            
            guard result != nil , error == nil else {
                print("You cannot sigin in due to MFA or other problem")
                return
            }
            
            print("Scuessfully signed with facebook")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
}
