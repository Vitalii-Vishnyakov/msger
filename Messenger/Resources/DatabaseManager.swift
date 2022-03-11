//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Виталий on 03.03.2022.
//

import Foundation
import FirebaseDatabase
import RealmSwift
import MessageKit

final class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let database = FirebaseDatabase.Database.database(url: "https://messenger-6b239-default-rtdb.europe-west1.firebasedatabase.app/").reference()
    
    static func safeEmail( email: String) -> String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "^")
        return safeEmail
    }
}
//MARK: - Account manager
extension DatabaseManager {
    public func getDataFor(path: String, completion : @escaping (Result<Any, Error>  ) -> Void){
        self.database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseErrors.FaildToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    
    public func  userExists ( with email : String, complition : @escaping ((Bool) -> Void))  {
        
        
        var safeEmail = DatabaseManager.safeEmail(email: email)
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: {snapchot in
            guard snapchot.value as? [String:Any] != nil else {
                complition(false)
                return
            }
            complition(true)
        })
        
    }
    public func getAllUsers(completion: @escaping (Result<[[String: String]],Error>) -> Void){
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseErrors.FaildToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    /// insert new user to database
    public func insertUser (with user : ChatAppUser ,completion : @escaping (Bool) -> Void){
        
        
        database.child(user.safeEmail).setValue(["first_name" : user.firstName, "last_name" : user.lastName]) { error, _ in
            guard error == nil else {
                print("failed to write to database")
                completion(false)
                return
            }
            self.database.child("users").observeSingleEvent(of: .value) { [weak self]  snapshot in
                if var usersCollection = snapshot.value as? [ [String:String]]{
                    let newElement = ["name": user.firstName + " " + user.lastName, "email" : user.safeEmail]
                    usersCollection.append(newElement)
                    self?.database.child("users").setValue(usersCollection) { error, _ in
                        
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                    
                    
                }
                else{
                    let newCollection : [[String: String]] = [["name": user.firstName + " " + user.lastName, "email" : user.safeEmail]]
                    self?.database.child("users").setValue(newCollection) { error, _ in
                        
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
            }
            completion(true)
        }
        
    }
}

extension DatabaseManager {
    
    ///Create a new conversation with target user email and first message
    public func createNewConversation (with otherUserEmail: String ,name: String, firstMessage : Message, completion : @escaping (Bool) -> Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String , let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        
        
        let safeEmail = DatabaseManager.safeEmail(email: currentEmail)
        
        let ref = database.child("\(safeEmail)")
        
        
        ref.observeSingleEvent(of: .value) { snapshot in
            guard var userNode = snapshot.value as? [String:Any] else {
                completion(false)
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateStr = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            switch firstMessage.kind {
                
            case .text(let messageText):
                message = messageText
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
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "converstion_\(firstMessage.messageId)"
            let newConversationData: [String : Any] = [
                "id": conversationId,
                "other_user_email" : otherUserEmail,
                "name" : name,
                "latest_message" : [
                    "date" : dateStr,
                    "is_read" : false,
                    "message" : message,
                ]
            ]
            
            let recipientNewConversationData: [String : Any] = [
                "id": conversationId,
                "other_user_email" : safeEmail,
                "name" : currentName,
                "latest_message" : [
                    "date" : dateStr,
                    "is_read" : false,
                    "message" : message,
                ]
            ]
            self.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) {[weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]]{
                    conversations.append(recipientNewConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                }
                else {
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipientNewConversationData])
                }
            }
            
            
            if var conversations = userNode["conversations"] as? [[String: Any]]{
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode) {[weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConverastion(name: name , conversationId: conversationId, firstMessage: firstMessage, completion: completion)
                    
                }
            }
            else {
                userNode["conversations"] = [newConversationData
                ]
                ref.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConverastion(name: name , conversationId: conversationId, firstMessage: firstMessage, completion: completion)
                    
                    
                }
            }
            
        }
        
        
    }
    private func finishCreatingConverastion(name:String , conversationId : String , firstMessage : Message , completion  : @escaping (Bool) -> Void ){
        
        let messageDate = firstMessage.sentDate
        let dateStr = ChatViewController.dateFormatter.string(from: messageDate)
        var message = ""
        switch firstMessage.kind {
            
        case .text(let messageText):
            message = messageText
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
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion( false)
            return
        }
        let  currentUserEmail = DatabaseManager.safeEmail(email: myEmail)
        
        let collectionMessage: [String : Any] = [
            "id" : firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date" :dateStr ,
            "sender_email": currentUserEmail,
            "isRead" : false,
            "name" : name
            
        ]
        
        
        let value : [String : Any] = [ "messages" : [collectionMessage ]]
        database.child("\(conversationId)").setValue(value) { error , _  in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
        
    }
    
    ///fetch all conversations for the user with email
    public func gatAllConversations ( for email : String, completion : @escaping (Result<[Conversation], Error>) -> Void){
        database.child("\(email)/conversations").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseErrors.FaildToFetch))
                return
            }
            
            let conversation : [Conversation] = value.compactMap { dict in
                guard let conversationId = dict["id"] as? String ,
                      let name = dict["name"] as? String ,  let otherUserEmail = dict["other_user_email"] as? String,
                      let latestMessage = dict["latest_message"] as? [String: Any], let date = latestMessage["date"] as? String , let message  = latestMessage["message"] as? String , let isRead = latestMessage["is_read"] as? Bool else {
                          return nil
                      }
                
                let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
            }
            completion(.success(conversation))
        }
        
    }
    
    ///geta all messages for given converation
    public func gerAllMessagesForConversation(with id : String, completion : @escaping (Result<[Message], Error > ) -> Void){
        database.child("\(id)/messages").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseErrors.FaildToFetch))
                return
            }
            
            let messages : [Message] = value.compactMap { dict in
                guard let name = dict["name"] as? String,
                      let content = dict["content"] as? String,
                      let dateStr = dict["date"] as? String,
                      let messageId = dict["id"] as? String,
                      let senderEmail = dict["sender_email"] as? String,
                      let isRead  = dict["isRead"] as? Bool  ,
                      let type = dict["type"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateStr) else {
                          
                          return nil
                          
                      }
                
                var kind : MessageKind?
                
                
                if type == "photo" {
                    guard let imageUrl = URL(string: content) , let placeholder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    let media = Media(url: imageUrl, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                }
                else if type == "video" {
                        guard let videoUrl = URL(string: content) , let placeholder = UIImage(named: "video_placeholder") else {
                            return nil
                        }
                        let media = Media(url: videoUrl, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                        kind = .video(media)
                    
                }
                else{
                    kind = .text(content)
                }
                
                guard let finalKind = kind else {
                    return nil
                }
                
                let sender = Sender(senderId: senderEmail, displayName: name, photoURL: "")
                
                return Message(sender: sender, messageId: messageId, sentDate: date, kind: finalKind)
            }
            completion(.success(messages))
        }
        
        
    }
    ///sends a message with target vonversation and message
    public func sendMessage(to conversation :String ,  otherUserEmail: String , name : String , newMessage : Message , completion : @escaping (Bool) -> Void){
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentEmail = DatabaseManager.safeEmail(email: myEmail)
        self.database.child("\(conversation)/messages").observeSingleEvent(of: .value) {[weak self] snapshot in
            guard var currentMessages =  snapshot.value as? [[String : Any]] else {
                completion(false)
                return
            }
            
            let messageDate = newMessage.sentDate
            let dateStr = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            
            switch newMessage.kind {
                
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion( false)
                return
            }
            let  currentUserEmail = DatabaseManager.safeEmail(email: myEmail)
            
            let newMessageEntry: [String : Any] = [
                "id" : newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date" :dateStr ,
                "sender_email": currentUserEmail,
                "isRead" : false,
                "name" : name
                
            ]
            currentMessages.append(newMessageEntry)
            self?.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                self?.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                    var databaseEntryConversations = [ [String: Any]]()
                    let updateValue : [String: Any] = ["date" : dateStr , "is_read" : false ,"message" : message ]
                    if var currentUserConversations = snapshot.value as? [[String : Any]]  {
                        
                        let updateValue : [String: Any] = ["date" : dateStr , "is_read" : false ,"message" : message ]
                        
                        var position = 0
                        var targetConv : [String : Any]?
                        
                        for conversationDict in currentUserConversations {
                            if let currentId = conversationDict["id"] as? String, currentId == conversation{
                                targetConv = conversationDict
                                break
                            }
                            position += 1
                        }
                        if var targetConv = targetConv {
                            targetConv["latest_message"] = updateValue
                            
                            currentUserConversations[position] = targetConv
                            databaseEntryConversations = currentUserConversations
                        }else {
                            let newConversationData: [String : Any] = [
                                "id": conversation,
                                "other_user_email" : DatabaseManager.safeEmail(email: otherUserEmail),
                                "name" : name,
                                "latest_message" : updateValue
                            ]
                            currentUserConversations.append(newConversationData)
                            databaseEntryConversations = currentUserConversations
                        }
                        
                       
                    }else {
                        let newConversationData: [String : Any] = [
                            "id": conversation,
                            "other_user_email" : DatabaseManager.safeEmail(email: otherUserEmail),
                            "name" : name,
                            "latest_message" : updateValue
                        ]
                        databaseEntryConversations = [newConversationData]
                    }
                    
                    
                    self?.database.child("\(currentEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                            let updateValue : [String: Any] = ["date" : dateStr , "is_read" : false ,"message" : message ]
                            var databaseEntryConversations = [ [String: Any]]()
                            guard let currentName  = UserDefaults.standard.value(forKey: "name") as? String else {
                                return
                            }
                            
                            if var otherUserConversations = snapshot.value as? [[String : Any]]  {
                                
                                var position = 0
                                var targetConv : [String : Any]?
                                
                                for conversationDict in otherUserConversations {
                                    if let currentId = conversationDict["id"] as? String, currentId == conversation{
                                        targetConv = conversationDict
                                        break
                                    }
                                    position += 1
                                }
                                
                                if var targetConv = targetConv {
                                    targetConv["latest_message"] = updateValue
                                    
                                    otherUserConversations[position] = targetConv
                                    databaseEntryConversations = otherUserConversations
                                }else {
                                    let newConversationData: [String : Any] = [
                                        "id": conversation,
                                        "other_user_email" : DatabaseManager.safeEmail(email: currentEmail),
                                        "name" : currentName,
                                        "latest_message" : updateValue
                                    ]
                                    otherUserConversations.append(newConversationData)
                                    databaseEntryConversations = otherUserConversations
                                }
                                
                              
                            }else {
                                let newConversationData: [String : Any] = [
                                    "id": conversation,
                                    "other_user_email" : DatabaseManager.safeEmail(email: currentEmail),
                                    "name" : currentName,
                                    "latest_message" : updateValue
                                ]
                                databaseEntryConversations = [newConversationData]
                            }
                            
                            
                            
                            self?.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: { error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                                
                            })
                        })
                        
                        
                        completion(true)
                        
                    })
                })
                
                
            }
            
        }
        
    }
    public func deleteConversation( conversationId : String , comletion : @escaping (Bool) -> Void){
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(email: email)
        let ref = database.child("\(safeEmail)/conversations")
       
        
        ref.observeSingleEvent(of: .value) { snapshot in
            if var conversations = snapshot.value as? [ [String:Any]]{
                var positionToRemove = 0
                
                for conversation in conversations {
                    if let id = conversation["id"] as? String, id == conversationId{
                        break
                    }
                    
                    positionToRemove += 1
                }
                
                
                conversations.remove(at: positionToRemove)
                ref.setValue(conversations) { error, _ in
                    guard error == nil else {
                        comletion(false)
                        print("fail to write new conversation ")
                        return
                    }
                    print("delete")
                    comletion(true)
                }
            }
        }
        
    }
    
    public func conversationExists( with targerRecipientEmail : String, completion : @escaping (Result<String  , Error>) -> Void) {
        let safeRecipEmail  = DatabaseManager.safeEmail(email: targerRecipientEmail)
        
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeSenderEmail = DatabaseManager.safeEmail(email: senderEmail)
        
        database.child("\(safeRecipEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
            guard let collection = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseErrors.FaildToFetch))
                return
            }
            
            if let conversation = collection.first(where: {
                guard let tergetSenderEmail = $0["other_user_email"] as? String else {
                    return false
                }
                return safeSenderEmail == tergetSenderEmail
                
            }){
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DatabaseErrors.FaildToFetch))
                    return
                }
                completion(.success(id))
                return
                
            }
                
            completion(.failure(DatabaseErrors.FaildToFetch))
            return
            
            
            
        }
        
    }
}




struct ChatAppUser{
    let firstName : String
    let lastName : String
    let emailAdress : String
    var safeEmail : String {
        var safeEmail = emailAdress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "^")
        return safeEmail
    }
    var profilePicture : String {
        return "\(safeEmail)_profile_picture.png"
    }
    
}
enum DatabaseErrors: Error {
    case FaildToFetch
}

