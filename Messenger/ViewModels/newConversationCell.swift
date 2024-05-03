//
//  newConversationCell.swift
//  Messenger
//
//  Created by Ritik Srivastava on 23/10/20.
//  Copyright © 2020 Ritik Srivastava. All rights reserved.
//

import Foundation


import SDWebImage

class newConversationCell: UITableViewCell {

    static let identifier = "newConversationCell"
    
    private let containerView : UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 38, green: 198, blue: 298, alpha: 0)
        view.layer.cornerRadius = CGFloat(8)
        return view
    }()
    
    private let userImage : UIImageView = {
         let img = UIImageView()
         img.contentMode = .scaleAspectFill // image will never be strecthed vertially or horizontally
         img.translatesAutoresizingMaskIntoConstraints = false // enable autolayout
        return img
    }()
    
    private var userlabel : UILabel = {
       let label = UILabel()
       label.font = UIFont.boldSystemFont(ofSize: 18)
       label.textColor = UIColor(displayP3Red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
       label.translatesAutoresizingMaskIntoConstraints = false
       return label
    }()
    


    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(containerView)
        
        containerView.addSubview(userImage)
        containerView.addSubview(userlabel)

    
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        containerView.frame = CGRect(x: 5, y: 4, width: contentView.width - 18, height: contentView.height-14)
        
        userImage.frame = CGRect(x: 10,
                                 y: 10,
                                 width: 75,
                                 height: 75)
        userImage.layer.cornerRadius = userImage.width/2
        userImage.layer.masksToBounds = true
        
        userlabel.frame = CGRect(x: userImage.right + 10,
                                 y: 15,
                                 width: containerView.width - 20 - userImage.width ,
                                 height: 20)
        
    }
    
    public func configure(with model: [String : String]){
        print(model)
        
        guard let uid = model["uid"] ,
            let name = model["name"]  else { return }
        
        let path = "images/\(uid)_profile_Picture.png"

        StorageManager.shared.downloadUrl(with: path) { (result) in

            switch result {
            case .success(let url):

                DispatchQueue.main.async {
                    self.userImage.sd_setImage(with: url, completed: nil)
                }

            case .failure((let error)):
                print("failed to get the image url \(error)")
            }

        }

        userlabel.text = name
    }
   
}
