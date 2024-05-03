

import UIKit
import FirebaseAuth
import FBSDKLoginKit

class RegisterViewController: UIViewController {

    private var imageView : UIImageView = {
        let image = UIImageView()
        image.image = UIImage(systemName: "person.circle")
        image.contentMode = .scaleAspectFit
        image.tintColor = .gray
        image.layer.borderWidth = 2
        image.layer.borderColor = UIColor.gray.cgColor
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
    
    
    private let userNameField : UITextField = {
        let userName = UITextField()
        
        userName.autocapitalizationType = .none
        userName.autocorrectionType = .no
        userName.backgroundColor = .white
        userName.layer.cornerRadius = 12
        userName.layer.borderWidth = 1
        userName.layer.borderColor = UIColor.lightGray.cgColor
        userName.placeholder = "Username .."
        userName.returnKeyType = .continue
        //to clear side buffer because text and border touches at left
        userName.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        userName.leftViewMode = .always
        
        return userName
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
        
        button.setTitle("Regsiter", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.addTarget(self , action: #selector(LoginButtonDidTouch), for: .touchUpInside)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    
    let facebookloginButton = FBLoginButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Create New Account"
      
        // Do any additional setup after loading the view.
        
        emailField.delegate = self
        passwordField.delegate = self
        
        //adding tap gesture on image on clicking double click
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTouch))
//        tapGesture.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(tapGesture)
        imageView.isUserInteractionEnabled = true
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(userNameField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(LoginButton)
        
        //adding facebook button
        scrollView.addSubview(facebookloginButton)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        //adding profile image circular
        
        
        scrollView.frame = view.bounds
        
        let size = view.frame.size.width / 3;
        imageView.frame = CGRect(x: (view.frame.size.width-size)/2, y: 20, width: size, height: size)
        imageView.layer.cornerRadius = imageView.width / 2
        userNameField.frame = CGRect(x: 30, y: imageView.bottom+10, width: scrollView.width-60, height: 52)
        
        emailField.frame = CGRect(x: 30, y: userNameField.bottom+15, width: scrollView.width-60, height: 52)
        
        passwordField.frame = CGRect(x: 30, y: emailField.bottom+15, width: scrollView.width-60, height: 52)
        
        LoginButton.frame = CGRect(x: 30, y: passwordField.bottom+20, width: scrollView.width-60, height: 52)
        
        facebookloginButton.frame = CGRect(x: 30, y: LoginButton.bottom+20, width: scrollView.width-60, height: 52)
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
        
        guard let username = userNameField.text  ,let email = emailField.text  , let password = passwordField.text ,!email.isEmpty ,!password.isEmpty , password.count>=6  else {
            let error = Helper.error(title: "Details are Invalid", message: "Please retry to fill!")
            present(error, animated:  true)
            return
        }
        
        //firbase login
        
        //spinner to avoid freeze of UI
        let spinner = UIViewController.displayLoading(withView: self.view)
        
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (result, error) in
            guard let strongSelf = self else { return }

            if error == nil {
                DispatchQueue.main.async {
                    //remove spinner
                    UIViewController.removingLoading(spinner: spinner)
                }
                
                // it is used to chache the username and email locally with this key
                UserDefaults.standard.set(username, forKey: "username")
                UserDefaults.standard.set(email, forKey: "email")
                
                print("welcome to database")
                
                let chatUser = ChatAppUser(username: username, email: email)
                DatabaseManager.shared.insertUser(with: chatUser , completion: { sucess in
                    if sucess {
                        print("image upload sucesfully")
                        guard  let image = strongSelf.imageView.image,
                               let data = image.pngData() else { return }
                        
                        
                        
                        let filename = chatUser.profileImageFileName
                        
                        StorageManager.shared.uploadProfilePicture(with: data, filename: filename) { (result) in
                            
                            switch result {
                            case .failure(let error):
                                print(error)
                            case .success(let downloadUrl):
                                UserDefaults.standard.set(downloadUrl, forKey: "profile_pic")
                                print(downloadUrl)
                            }
                        }
                    }
                })
                
                //back to navigation controller where it is instaniate
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
            else if let error = error {
                
                DispatchQueue.main.async {
                    UIViewController.removingLoading(spinner: spinner)
                }
                                   
                let alert = Helper.loginSignError(error: error , title: "Login" )
                print("error to database")
                DispatchQueue.main.async {
                    strongSelf.present(alert ,animated: true ,completion: nil)
                }
            }
        }
        
    }
    
    @objc func profileImageTouch(){
        print("Profile image touch")
        
        presentPhotoOption()
    }
}

// this help on clicking enter in the text it will goes to other field we can also do textEditing
extension RegisterViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == userNameField {
            emailField.becomeFirstResponder()
        }
        else if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            LoginButtonDidTouch()
        }
        return true
    }
    
}

//MARK: it help in select the image from the camera and photo acees libarary
extension RegisterViewController : UIImagePickerControllerDelegate  , UINavigationControllerDelegate{
    
    func presentPhotoOption(){
        let actionSheet = UIAlertController(title: "Profile Image", message: "Select mode of Image access", preferredStyle: .actionSheet)
        
        let camera = UIAlertAction(title: "Take photo", style: .default) {[weak self] _ in
            self?.presentCamera()
        }
        
        let photoLibrary = UIAlertAction(title: "Choose Photo", style: .default) {[weak self] _ in
            self?.presentPhotoLibrary()
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel , handler: nil)
        
        actionSheet.addAction(camera)
        actionSheet.addAction(photoLibrary)
        actionSheet.addAction(cancel)
        present(actionSheet ,animated: true)
    }
    
    func presentCamera(){
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc , animated: true)
    }
    
    func presentPhotoLibrary(){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc , animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//      print(info)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else { return }
        self.imageView.layer.masksToBounds = true
        self.imageView.image = selectedImage
        picker.dismiss(animated: true, completion: nil)
    }
    
    //called when user clicked in image clicking
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}

