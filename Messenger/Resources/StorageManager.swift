//
//  StorageManager.swift
//  Messenger
//
//  Created by Ritik Srivastava on 13/10/20.
//  Copyright © 2020 Ritik Srivastava. All rights reserved.
//

import Foundation
import FirebaseStorage

class StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    /*
     /images/uid
     */
    
    public typealias uploadPictureCompletion = (Result< String , Error>) -> Void
    
    ///Uplaod picture to firebase and return completion with url string
    public func uploadProfilePicture(with data: Data , filename : String , completion: @escaping uploadPictureCompletion ) {
        

        storage.child("images/\(filename)").putData(data, metadata: nil , completion: { (metaData , error) in
            
            guard error == nil else {
                print("Failed to uplaod profile image to firebase")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self.storage.child("images/\(filename)").downloadURL { (url, error) in
                
                guard let url = url else {
                    print("failed to downlaod url")
                    completion(.failure(StorageErrors.failedToDownlaodUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print(urlString)
                completion(.success(urlString))
            }
            
        })
        
    }
    
    
    public enum StorageErrors : Error {
        case failedToUpload
        case failedToDownlaodUrl
    }
    
    
    public func downloadUrl(with path:String , completion: @escaping (Result<URL , Error>) -> Void){
        print(path)
        let reference = storage.child(path)
        reference.downloadURL { (url, error) in
            guard let url = url , error == nil else {
                completion(.failure(StorageErrors.failedToDownlaodUrl))
                return
            }
            completion(.success(url.absoluteURL))
        }
        
    }
    
    ///Uplaod the message sent picture to firebase and return completion with url string
    public func uploadImagePicture(with data: Data , filename : String , completion: @escaping uploadPictureCompletion ) {
           

           storage.child("message_images/\(filename)").putData(data, metadata: nil , completion: { [weak self] (metaData , error) in
               
            guard let strongSelf = self else { return }
            
               guard error == nil else {
                   print("Failed to uplaod image to firebase")
                   completion(.failure(StorageErrors.failedToUpload))
                   return
               }
               
               strongSelf.storage.child("message_images/\(filename)").downloadURL { (url, error) in
                   
                   guard let url = url else {
                       print("failed to downlaod url")
                       completion(.failure(StorageErrors.failedToDownlaodUrl))
                       return
                   }
                   
                   let urlString = url.absoluteString
                   print(urlString)
                   completion(.success(urlString))
               }
               
           })
           
       }
 
    
    ///Uplaod the message sent video to firebase and return completion with url string
    public func uploadVideoPicture(with fileUrl: URL , filename : String , completion: @escaping uploadPictureCompletion ) {
        
        
        storage.child("message_videos/\(filename)").putFile(from: fileUrl, metadata: nil , completion: {[weak self] (metaData , error) in
            
            guard let strongSelf = self else { return }
            
            guard error == nil else {
                print("Failed to uplaod video to firebase")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            strongSelf.storage.child("message_videos/\(filename)").downloadURL { (url, error) in
                
                guard let url = url else {
                    print("failed to downlaod url")
                    completion(.failure(StorageErrors.failedToDownlaodUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print(urlString)
                completion(.success(urlString))
            }
            
        })
        
    }
}
