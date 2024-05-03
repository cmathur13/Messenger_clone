//
//  ProfileViewController.swift
//  Messenger
//
//  Created by Ritik Srivastava on 11/10/20.
//  Copyright © 2020 Ritik Srivastava. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import GoogleSignIn

class ProfileViewController: UIViewController {

    @IBOutlet var tableView : UITableView!
    
    var data = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //setting up the table view
        setupTableView()

    }
    

}

//MARK: - It is an more option in profile bar button icon
extension ProfileViewController {
    
    @IBAction func moreOption(_ sender: Any) {
        
        let alert = UIAlertController(title: "Setting", message: "option available", preferredStyle: .actionSheet)
        
        let logout = UIAlertAction(title: "Logout", style: .default) {[weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.doYouReallyWantToExist()
        }
        
        let setting = UIAlertAction(title: "Setting", style: .default) { _ in
            print("In the setting")
        }
        
        let cancel = UIAlertAction(title: "No", style: .cancel) { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(logout)
        alert.addAction(setting)
        alert.addAction(cancel)
        present(alert,animated: true)
    }
    
    func doYouReallyWantToExist(){
        let alert = UIAlertController(title: "Logout", message: "Really want to logout?", preferredStyle: .alert)
        
        let yes = UIAlertAction(title: "Yes", style: .default) { [weak self]  _ in
            
            guard let strongSelf = self else { return }
            do {
                //logout from facebook
                FBSDKLoginKit.LoginManager().logOut()
                
                //logout from google
                GIDSignIn.sharedInstance().signOut()
                
                //lohout from firebase
                try Auth.auth().signOut()
                let vc = LoginViewController()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                strongSelf.present(nav , animated: true)
                
            }catch{
                print("Failed to logout")
            }
        }
        
        let no = UIAlertAction(title: "No", style: .cancel) { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(yes)
        alert.addAction(no)
        self.present(alert , animated:  true)
    }
    
    
}



extension ProfileViewController : UITableViewDelegate ,UITableViewDataSource  {
    
    func setupTableView(){
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        
        //we can edit first row design
        tableView.tableHeaderView = createTableHeader()
    }
    
    func createTableHeader() -> UIView? {
        
        guard let userId = Helper.uniqueId() else { return nil }
        
        let fileName = "\(userId)_profile_Picture.png"
        
        let path = "images/\(fileName)"
        
        print(path)
        
        let headerView = UIView(frame: CGRect(x: 0,
                                              y: 0,
                                              width: self.view.width,
                                              height: 300))
        headerView.backgroundColor = .link
        
        let image = UIImageView()
        image.frame = CGRect(x: (headerView.width-150)/2,
                             y: 50,
                             width: 150,
                             height: 150)
        
        image.contentMode = .scaleAspectFill
        image.layer.cornerRadius = image.width/2
        image.layer.borderColor = UIColor.white.cgColor
        image.layer.borderWidth = CGFloat(5.0)
        image.layer.masksToBounds = true
        
        let label = UILabel()
        label.text = UserDefaults.standard .string(forKey: "username")
        label.textAlignment = .center
        
        
        StorageManager.shared.downloadUrl(with: path) { (result) in
            print("trying to download image url")
            switch result {
            case (.success(let url)):
                self.downloadImage(imageView: image, url: url)
            case (.failure(let error)):
                print("Failed to get download url \(error)")
            }
        }
        
        
        self.view.addSubview(headerView)
        headerView.addSubview(image)
        
        return headerView
    }
    
    func downloadImage(imageView : UIImageView , url : URL) {
        
        URLSession.shared.dataTask(with: url) {  (data, _ , error) in
            
            guard let data = data , error == nil else { return }
            print("image in UI")
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageView.image = image
            }

        }.resume()
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        return cell
    }
    
}
