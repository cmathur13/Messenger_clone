//
//  ChatViewController.swift
//  Messenger
//
//  Created by Ritik Srivastava on 13/10/20.
//  Copyright © 2020 Ritik Srivastava. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit

struct Message : MessageType {
    
    var sender: SenderType
    
    var messageId: String
    
    var sentDate: Date
    
    var kind: MessageKind
}

struct Sender : SenderType {
    var senderId: String
    var displayName: String
    var photoUrl : String
}


struct Media : MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

class ChatViewController: MessagesViewController {
    
    private var isNewConversation = true
    private var otherUserId : String
    private var conversationId : String?
    
    // it help to get date in form of long string
    public static let dateFormatter: DateFormatter = {
        let date = DateFormatter()
        date.dateStyle = .medium
        date.timeStyle = .long
        date.locale = .current
        return date
    }()
    
    private var messages = [Message]()
    private var selfSender : Sender?
    
    let myid = Helper.uniqueId()!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemPink
        
        let newsender = Sender(senderId: myid, displayName: navigationItem.title! , photoUrl: "")
        selfSender = newsender
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        messageInputBar.delegate = self
        // Do any additional setup after loading the view.
        
        //this added so when we click on photo to open newVc
        messagesCollectionView.messageCellDelegate = self
        
        // this help in sending photos, videos
        setupInputButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    init(with uid: String , conId : String?) {
        self.otherUserId = uid
        self.conversationId = conId
        super.init(nibName: nil, bundle: nil)
        
        if let conversatinId = conversationId {
            listenForMessage(id: conversatinId)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func listenForMessage(id : String){
        
        DatabaseManager.shared.getAllMessageConveration(with: id) {[weak self] (result) in
            
            guard let strongSelf = self else { return }
            
            switch result {
                
            case.success(let message):
                guard !message.isEmpty else { return }
                
                strongSelf.messages = message
                self?.isNewConversation = false
                DispatchQueue.main.async {
                    strongSelf.messagesCollectionView.reloadDataAndKeepOffset()
                }
                
            case .failure(let error):
                print("unable to downlaod chats \(error)")
                
            }
            
        }
        
    }
    
}


extension ChatViewController : InputBarAccessoryViewDelegate{
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty ,
             let selfsender = selfSender    else {
            return
        }
        
        let date = Self.dateFormatter.string(from: Date())
        let messageUniqueId = "\(otherUserId)-\(myid)-\(date)"
        
        print(text , otherUserId , date , messageUniqueId)
        
        let message = Message(sender: selfsender,
                              messageId: messageUniqueId,
                              sentDate: Date(),
                              kind: .text(text))
        
        if isNewConversation {
            // when new conversation first time
            DatabaseManager.shared.createNewConversation(with: otherUserId, name: self.title!, message: message) { (status) in
                if status {
                    print("inseted sucesfully")
                    self.isNewConversation = false
                }else{
                    print("It is inseted unsuscessfully")
                }
            }
        }
        else{
            // when you already had chat
            guard let conversationId = conversationId else {return }
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserId: otherUserId , name: self.title! , message: message) { (status) in
                if status {
                    print("You have talked already")
                }else{
                    print("It is inseted unsuscessfully")
                }
            }
        }
        
        inputBar.inputTextView.text = ""
    }
    
}

//MARK: We want to control the message delegate kit use in our app
extension ChatViewController : MessagesDataSource, MessagesLayoutDelegate , MessagesDisplayDelegate {
    
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("something went wrong")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else { return }
            
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
        
    }
        
}


//MARK: We want to add input like photos and video in messages
extension ChatViewController : UIImagePickerControllerDelegate , UINavigationControllerDelegate {
    
    func setupInputButton(){
        let button = InputBarButtonItem()
        
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        
        button.setImage(UIImage(systemName: "paperclip") , for: .normal)
        
        button.onTouchUpInside {[weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    func presentInputActionSheet(){
        
        let actionSheet = UIAlertController(title: "Type",
                                            message: "What you would like to have ?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Photos", style: .default, handler: {[weak self] (_) in
            self?.imageTypeActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: {[weak self] _ in
            self?.videoTypeActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "location", style: .default, handler: { (_) in
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "cancel", style: .cancel ,handler: nil ))
        
        present(actionSheet , animated:  true)
    }
    
    func imageTypeActionSheet(){
        
        let actionSheet = UIAlertController(title: "Attach photo",
                                            message: "What you would like to have ?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {[weak self] (_) in
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker , animated:true)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: {[weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .savedPhotosAlbum
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker , animated:true)
        }))
        

        actionSheet.addAction(UIAlertAction(title: "cancel", style: .cancel ,handler: nil ))
        
        present(actionSheet , animated:  true)
    }
    
    func videoTypeActionSheet(){
        
        let actionSheet = UIAlertController(title: "Attach Video",
                                            message: "What you would like to have ?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {[weak self] (_) in
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker , animated:true)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: {[weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .savedPhotosAlbum
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker , animated:true)
        }))
        

        actionSheet.addAction(UIAlertAction(title: "cancel", style: .cancel ,handler: nil ))
        
        present(actionSheet , animated:  true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        

        
        if  let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage ,
            let imageData = image.pngData() {
            
            //here means we are uploading image
            
            let date = Self.dateFormatter.string(from: Date())
            let fileName = "photo_message-\(otherUserId)-\(myid)-\(date).png"
            
            // uplaod the image
            StorageManager.shared.uploadImagePicture(with: imageData, filename: fileName) {[weak self] (result) in
                
                guard let strongSelf = self ,
                    let conversationId = strongSelf.conversationId,
                    let selfsender = strongSelf.selfSender else { return }
                
                switch result {
                
                case .success(let urlString):
                    print(urlString)
                    
                    guard let url = URL(string: urlString),
                        let placeholder = UIImage(systemName: "photo"),
                        let name = strongSelf.title else { return }
                    
                    let media  = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    
                    let message = Message(sender: selfsender,
                                          messageId: fileName,
                                          sentDate: Date(),
                                          kind: .photo(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserId: strongSelf.otherUserId , name: name , message: message) { (status) in
                        
                        if status {
                            print("You have sent  photo message")
                        }else{
                            print("It is donot sent photo  unsuscessfully")
                        }
                        
                    }
                    
                case .failure(let error):
                    print("There is error in uploading image of message chat \(error)")
                }
                
            }
            
        }
        
        else if let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL{
            // uploading a video
            
            let date = Self.dateFormatter.string(from: Date())
            let fileName = "photo_message-\(otherUserId)-\(myid)-\(date).mov"
            
            StorageManager.shared.uploadVideoPicture(with: videoUrl, filename: fileName) {[weak self] (result) in
                
                guard let strongSelf = self ,
                    let conversationId = strongSelf.conversationId,
                    let selfsender = strongSelf.selfSender else { return }
                
                switch result {
                
                case .success(let urlString):
                    print(urlString)
                    
                    guard let url = URL(string: urlString),
                        let placeholder = UIImage(systemName: "photo"),
                        let name = strongSelf.title else { return }
                    
                    let media  = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    
                    let message = Message(sender: selfsender,
                                          messageId: fileName,
                                          sentDate: Date(),
                                          kind: .video(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserId: strongSelf.otherUserId , name: name , message: message) { (status) in
                        
                        if status {
                            print("You have sent  video message")
                        }else{
                            print("It is donot sent video  unsuscessfully")
                        }
                        
                    }
                    
                case .failure(let error):
                    print("There is error in uploading video of message chat \(error)")
                }
                
            }
            
            
            
        }

        
        
      
        
    }
    
}




extension ChatViewController : MessageCellDelegate {
    func didTapImage(in cell: MessageCollectionViewCell) {
        
        //getting its cell
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        
        let message = messages[indexPath.section]
        print("we are going to present photoView controller")
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else { return }
            
            let vc = PhotoViewController(with: imageUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        
        case .video(let media):
            guard let videoUrl = media.url else { return }
            
            let vc = AVPlayerViewController()
            
            vc.player = AVPlayer(url: videoUrl)
            
            present(vc , animated: true)
            
        default:
            break
        }
    }
    
    
    
}
