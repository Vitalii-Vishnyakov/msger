//
//  StorageManager.swift
//  Messenger
//
//  Created by Виталий on 04.03.2022.
//

import Foundation
import FirebaseStorage
import CoreMedia
final class StorageManager{
    static let shared = StorageManager( )
    
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureComplition = ( Result<String, Error>) -> Void
    
    public func uploadProfilePicture( with data : Data, fileName : String, completion : @escaping UploadPictureComplition) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: {
            metadata , error in
            guard   error == nil else {
                print("Error in picture upload")
                completion(.failure(StorageErrors.failedToUpload))
                return
                
            }
            self.storage.child("images/\(fileName)").downloadURL(completion: {url , error in
                guard let url = url else {
                    print("Error in picture download")
                    completion( .failure(StorageErrors.failedToDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("download url returned : \(urlString)")
                completion(.success(urlString))
            })
            
        })
        
    }
    public func uploadMessagePicture( with data : Data, fileName : String, completion : @escaping UploadPictureComplition) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: {[weak self]
            metadata , error in
            guard   error == nil else {
                print("Error in picture upload")
                completion(.failure(StorageErrors.failedToUpload))
                return
                
            }
            self?.storage.child("message_images/\(fileName)").downloadURL(completion: {url , error in
                guard let url = url else {
                    print("Error in picture download")
                    completion( .failure(StorageErrors.failedToDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("download url returned : \(urlString)")
                completion(.success(urlString))
            })
            
        })
        
    }
    
    
    public func uploadMessageVideo( with fileUrl : URL, fileName : String, completion : @escaping UploadPictureComplition) {
      
        print("\(fileUrl)------------------------------")
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil, completion: { [weak self]
            metadata , error in
            guard   error == nil else {
                print("Error in video upload---------->\(error)")
                completion(.failure(StorageErrors.failedToUpload))
                return
                
            }
            self?.storage.child("message_videos/\(fileName)").downloadURL(completion: {url , error in
                guard let url = url else {
                    print("Error in video download")
                    completion( .failure(StorageErrors.failedToDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("download url returned : \(urlString)")
                completion(.success(urlString))
            })
            
        })
        
    }
    
    
    public func downloadURL(for path : String,  completion : @escaping ( Result<URL, Error>) -> Void){
        let ref = storage.child(path)
        ref.downloadURL { url, error in
            guard let  url = url , error == nil else {
                completion(.failure(StorageErrors.failedToDownloadUrl))
                return
            }
            completion(.success(url))
        }
    }
    
    public enum StorageErrors: Error{
        case failedToUpload
        case failedToDownloadUrl
    }
}
