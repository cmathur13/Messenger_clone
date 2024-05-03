//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Ritik Srivastava on 13/10/20.
//  Copyright © 2020 Ritik Srivastava. All rights reserved.
//

import Foundation
import FirebaseDatabase
import MessageKit

final class DatabaseManager {
    
    //creating a shared delegate
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
}

//MARK: - Database query
extension DatabaseManager {
    
    ///Insert query
    public func insertUser(with user : ChatAppUser , completion : @escaping (Bool)-> Void){
        
        guard let uid = Helper.uniqueId() else { return }
        
        database.child(uid).setValue([
            "username" : user.username,
            "email" : user.email
            ] , withCompletionBlock: { (error, _ ) in
                guard error == nil else {
                    print("failed to write in database")
                    completion(false)
                    return
                }
                
                self.database.child("users").observeSingleEvent(of: .value) { (snapshot) in
                    if var userCollection = snapshot.value as? [[String:String]] {
                        //append to the user dictionary
                        let newElement : [[String:String]] = [
                            [
                                "name": user.username,
                                "uid": user.currentId
                            ]
                        ]
                        userCollection.append(contentsOf: newElement)
                        self.database.child("users").setValue(userCollection , withCompletionBlock: { (error , _ ) in
                            guard error == nil else {
                                print("failed to write in database")
                                completion(false)
                                return
                            }
                            
                            completion(true)
                            
                        })
                        
                    }else{
                        //create an array
                        let newCollection : [[String:String]] = [
                            [
                            "name": user.username,
                            "uid": user.currentId
                            ]
                        ]
                        print(newCollection)
                        self.database.child("users").setValue(newCollection , withCompletionBlock: { (error , _ ) in
                            guard error == nil else {
                                print("failed to write in database")
                                completion(false)
                                return
                            }
                            
                            completion(true)
                        })
                    }
                    
                    
                }
                
                
        })
        
    }
        
    /// get all the user from database in child("users")
    func getAllUser(completion : @escaping (Result<[[String:String]] , Error>)-> Void){
        database.child("users").observeSingleEvent(of: .value) { (snapshot) in
            guard let users = snapshot.value as? [[String : String]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            completion(.success(users))
        }
    }
    
    
}

public enum DatabaseErrors : Error {
    case failedToFetch
}

struct ChatAppUser {
    let username:String
    let email : String
    // let profileImage : URL
    
    let currentId = Helper.uniqueId()!

    var profileImageFileName : String {
        return "\(currentId)_profile_Picture.png"
    }
}

//MARK: this is used to send message to
extension DatabaseManager {
    
    /*
      "UUISIDIIhxiAI": {
            "messages" :[
                {
                    "id" : String,
                    "type" : text , video , photo,
                    "content" : String,
                    "date" : Date(),
                    "sender_id": String,
                    "isRead" : True/false
                }
            ]
        }
     
     
        Conversation => [
            [
                "conversation_id" : "UUISIDIIhxiAI",
                "otherUserId" : String,
                "latestMessage" => {
                    "date" : Date(),
                    "latestMessage" : String,
                    "isRead" : True/false,
                }
            ]
        ]
     
     */
    
    ///create new user with the current target user id
    public func createNewConversation(with otherUserID: String , name : String, message:Message , completion : @escaping (Bool) -> Void) {
        
        guard let uid = Helper.uniqueId() ,
              let myName = UserDefaults.standard.object(forKey: "username") as? String  else {
            print("current user not found")
            completion(false)
            return
        }
        
        
        let ref = database.child(uid)
        ref.observeSingleEvent(of: .value) {[weak self] (snapshot) in
            
            guard var userNode = snapshot.value as? [String:Any] else {
                print("user not found")
                completion(false)
                return
            }
            
            //conversation id
            let conversationId = "conversation_\(message.messageId)"
            
            //convert date in string
            let messageDate = message.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            //convert type of date text
            var messageTxt = ""
            switch message.kind {
            case .text(let text):
                messageTxt = text
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            
            let Newconversation : [String:Any] = [
                "id" : conversationId,
                "otherUserId" : otherUserID,
                "latestMessage" :[
                    "date" : dateString,
                    "latestMessage" : messageTxt,
                    "isRead" : false,
                ],
                "name" : name
            ]
            
            let recipentNewconversation : [String:Any] = [
                "id" : conversationId,
                "otherUserId" : uid,
                "latestMessage" :[
                    "date" : dateString,
                    "latestMessage" : messageTxt,
                    "isRead" : false,
                ],
                "name" : myName
            ]
            
            
            //update recipent user entry
            print(uid)
            self?.database.child("\(otherUserID)/conversation").observeSingleEvent(of: .value) { [weak self ](snapshot) in
                
                guard let strongSelf = self else { return }
                
                if var conversations = snapshot.value as? [[String:Any]]{
                    //append it
                    
                    conversations.append(recipentNewconversation)
                    strongSelf.database.child("\(otherUserID)/conversation").setValue(conversations)
                    
                }else{
                    //create it
                    
                    strongSelf.database.child("\(otherUserID)/conversation").setValue([recipentNewconversation])
                    
                }
            }

            // update current uder entry
            if var conversation = userNode["conversation"] as? [[String:Any]] {
                //conversation array exist for cuurent user
                //you shoud append
                
                conversation.append(Newconversation)
                userNode["conversation"] = conversation
                
                ref.setValue(userNode) { (error, _) in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingFunction(name: name, conversationId: conversationId, message: message, completion: completion)
                }
                
            }else{
                // conversation array donot exist for current user
                //you should create it
                userNode["conversation"] = [Newconversation]

                
                ref.setValue(userNode) { (error, _) in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingFunction(name: name, conversationId: conversationId, message: message, completion: completion)
                }
                
            }
            
        }
        
    }
    
    private func finishCreatingFunction(name: String ,conversationId : String , message : Message , completion : @escaping (Bool)-> Void){
        
        guard let uid = Helper.uniqueId() else {
            print("current user not found")
            completion(false)
            return
        }
        
        //convert date in string
        let messageDate = message.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        //convert type of date text
        var messageTxt = ""
        var type = ""
        switch message.kind {
        case .text(let text):
            messageTxt = text
            type = "text"
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .custom(_):
            break
        }
        
        
        let newMessage : [String : Any] = [
                "id" : conversationId,
                "type" : type,
                "content" : messageTxt,
                "date" : dateString,
                "sender_id": uid,
                "isRead" : false,
                "name" : name
        ]
        
        let value : [String :Any] = [
            "messages" : [
                newMessage
            ]
        ]
        
        database.child(conversationId).setValue(value) { (error, _) in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    ///Fetch and return all the mesage from the user id
    public func getAllConversation(for userId:String , completion : @escaping (Result<[Converstaion], Error>)->Void){
     
        database.child("\(userId)/conversation").observe(.value) { (snapshot) in
            
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            
            let conversation : [Converstaion] = value.compactMap { (dictionary) in
                
                guard   let conversationId = dictionary["id"] as? String ,
                        let name = dictionary["name"] as? String ,
                        let otherUserId = dictionary["otherUserId"] as? String,
                        let latestMessage = dictionary["latestMessage"] as? [String:Any] ,
                        let date = latestMessage["date"] as? String ,
                        let isRead = latestMessage["isRead"] as? Bool ,
                        let message = latestMessage["latestMessage"] as? String else {
                            return nil
                }
                
                let latestMessageRecieved = LatestMessage(date: date, text: message, isRead: isRead)
                let convestationRecieved =  Converstaion(id: conversationId, name: name, otherUserId: otherUserId, latestMessage: latestMessageRecieved)
                return convestationRecieved
            }
            
            completion(.success(conversation))
            
        }
    }
    
    /// Get all message for the conversation
    public func getAllMessageConveration(with id:String , completion: @escaping (Result<[Message] , Error>)->Void ){
        
        database.child("\(id)/messages").observe(.value) { (snapshot) in
//            print("\(id)/messages")
            
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            
            let messages : [Message] = value.compactMap { (dictionary) in
                
                guard   let messageid = dictionary["id"] as? String ,
                        let name = dictionary["name"] as? String ,
                        let otherUserId = dictionary["sender_id"] as? String,
                        let dateString = dictionary["date"] as? String ,
                        let date = ChatViewController.dateFormatter.date(from: dateString),
                        let _ = dictionary["isRead"] as? Bool ,
                        let message = dictionary["content"] as? String,
                        let type = dictionary["type"] as? String else {
                            return nil
                        }
                    
                var kind: MessageKind?
                
                if type == "photo" {
                    // photo
                    guard let imageUrl = URL(string: message),
                          let placeholder = UIImage(systemName: "photo") else { return nil }
                    
                    let media = Media(url: imageUrl,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: CGSize(width: 300, height: 300))
                    
                    kind = .photo(media)
                    
                }else if type == "video"{
                 
                    guard let videoUrl = URL(string: message),
                          let placeholder = UIImage(systemName: "video") else { return nil }
                    
                    let media = Media(url: videoUrl,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: CGSize(width: 300, height: 300))
                    
                    kind = .video(media)
                    
                }else{
                    // media
                    kind = .text(message)
                }
                
                guard let finalKind = kind else { return nil }
                
                        let sender = Sender(senderId: otherUserId,
                                            displayName: name,
                                            photoUrl: "")
                
                        let msg = Message(sender: sender,
                                          messageId: messageid ,
                                          sentDate: date,
                                          kind: finalKind)
                        return msg
                }
    
                completion(.success(messages))
        }
            
        
    }
    
    /// send a message to the target user 
    public func sendMessage(to conversationId:String , otherUserId:String , name: String , message: Message ,completion: @escaping (Bool) -> Void){
        
        // add new message to message
     
        self.database.child("\(conversationId)/messages").observeSingleEvent(of: .value) {[weak self] (snapshot) in
            
            guard let strongSelf = self else { return }
            
            guard var currentMessage = snapshot.value as? [[String:Any]] ,
                  let myid = Helper.uniqueId() else {
                completion(false)
                return
            }
            
            //convert date in string
            let messageDate = message.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            //convert type of date text
            var messageTxt = ""
            var type = ""
            
            switch message.kind {
            case .text(let text):
                messageTxt = text
                type = "text"
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString{
                    messageTxt = targetUrlString
                }
                type = "photo"
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString{
                    messageTxt = targetUrlString
                }
                type = "video"
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            
            
            let newMessage : [String : Any] = [
                    "id" : conversationId,
                    "type" : type,
                    "content" : messageTxt,
                    "date" : dateString,
                    "sender_id": myid,
                    "isRead" : false,
                    "name" : name
            ]
            
            currentMessage.append(newMessage)
            
            strongSelf.database.child("\(conversationId)/messages").setValue(currentMessage) { (error, _) in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                // upadte sender id latest message
                strongSelf.database.child("\(myid)/conversation").observeSingleEvent(of: .value) { (snapshot) in
                    
                    guard var currentUserConversation = snapshot.value as? [[String:Any]] else{
                        completion(false)
                        return
                    }
                    
                    let updateValue : [String:Any] = [
                        "date": dateString,
                        "isRead":false,
                        "latestMessage":messageTxt
                    ]
                    
                    var targetConversation : [String:Any]?
                    
                    var position = 0
                    
                    for conversation in currentUserConversation {
                        if let currentId = conversation["id"] as? String , currentId == conversationId
                        {
                            targetConversation = conversation
                            break;
                        }
                        position+=1
                    }
                    
                    targetConversation?["latestMessage"] = updateValue
                    
                    guard let finalConversation = targetConversation else{
                        completion(false)
                        return
                    }
                    currentUserConversation[position] = finalConversation
                    
                    strongSelf.database.child("\(myid)/conversation").setValue(currentUserConversation) { (error, _) in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                    }
                    completion(true)
                }
                
                //update recepint id latest message
                strongSelf.database.child("\(otherUserId)/conversation").observeSingleEvent(of: .value) { (snapshot) in
                    
                    guard var currentUserConversation = snapshot.value as? [[String:Any]] else{
                        completion(false)
                        return
                    }
                    
                    let updateValue : [String:Any] = [
                        "date": dateString,
                        "isRead":false,
                        "latestMessage":messageTxt
                    ]
                    
                    var targetConversation : [String:Any]?
                    
                    var position = 0
                    
                    for conversation in currentUserConversation {
                        if let currentId = conversation["id"] as? String , currentId == conversationId
                        {
                            targetConversation = conversation
                            break;
                        }
                        position+=1
                    }
                    
                    targetConversation?["latestMessage"] = updateValue
                    
                    guard let finalConversation = targetConversation else{
                        completion(false)
                        return
                    }
                    currentUserConversation[position] = finalConversation
                    
                    strongSelf.database.child("\(otherUserId)/conversation").setValue(currentUserConversation) { (error, _) in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                    }
                    completion(true)
                }
                
            }
            
        }
    }
    
    
}
