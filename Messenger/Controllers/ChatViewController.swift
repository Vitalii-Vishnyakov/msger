//
//  ChatViewController.swift
//  Messenger
//
//  Created by Виталий on 04.03.2022.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SwiftUI
import SDWebImage
import AVKit
import AVFoundation
import MapKit
import RealmSwift
struct Message: MessageType{
    var sender: SenderType
    
    var messageId: String
    
    var sentDate: Date
    var kind: MessageKind
    
}
struct Media: MediaItem{
    var url: URL?
    
    var image: UIImage?
    
    var placeholderImage: UIImage
    
    var size: CGSize
    
    
}


extension MessageKind{
    var messageKindString : String {
        switch self {
            
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link_preview"
        case .custom(_):
            return "custom"
        }
    }
}
struct Sender : SenderType{
    var senderId: String
    var displayName: String
    var photoURL : String
}

class ChatViewController: MessagesViewController{
    private var senderPhotoUrl : URL?
    private var otherUserPhotoUrl : URL?
    
    
    public static var  dateFormatter : DateFormatter = {
        let fm = DateFormatter()
        fm.dateStyle = .medium
        fm.timeStyle = .long
        fm.locale = .current
        return fm
    }( )
    public var isNewConversation = false
    public var otherUserEmail : String
    private var conversationId : String?
    private var messages =   [Message]()
    private var selfSender : Sender?  {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail
        = DatabaseManager.safeEmail(email: email)
        
        return  Sender(senderId: safeEmail , displayName: "Me", photoURL: "")
    }
    
    
    init(with email: String , id : String?) {
        self.conversationId = id
        self.otherUserEmail = email
        super.init(nibName: nil,  bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate  = self
        messagesCollectionView.messageCellDelegate  = self
        messageInputBar.inputTextView.becomeFirstResponder()
        setupInputButton( )
    }
    private func setupInputButton( ){
        let button = InputBarButtonItem( )
        button.setSize(CGSize(width: 35, height: 35 ), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside {[weak self] _ in
            self?.presentInputActionSheet()
        }
        
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    private func presentInputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach media", message: "What to attache", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: {  _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {  _ in
            
        }))
        
        present(actionSheet, animated:  true)
    }
    
    private func presentPhotoInputActionSheet ( ) {
        let actionSheet = UIAlertController(title: "Attach Photo", message: "From ... ", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController( )
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated:  true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController( )
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated:  true)
        }))
        
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated:  true)
    }
    
    private func presentVideoInputActionSheet ( ) {
        let actionSheet = UIAlertController(title: "Attach Video", message: "From ... ", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController( )
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated:  true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController( )
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated:  true)
        }))
        
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated:  true)
    }
    
    
    private func listenForMessages ( id : String , shouldScrollToBottom : Bool){
        
        DatabaseManager.shared.gerAllMessagesForConversation(with: id) {[weak self] result in
            switch result {
                
            case .success(let messages):
                
                guard !messages.isEmpty else {
                    
                    return
                }
                
                self?.messages = messages
                
                DispatchQueue.main.async {
                    
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    
                    
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
                    }
                    
                }
                
                
            case .failure(let error):
                print("fail to ger all msg for conv \(error)")
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId{
            
            listenForMessages(id: conversationId, shouldScrollToBottom : true)
        }
    }
    
}

extension ChatViewController : UIImagePickerControllerDelegate , UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let  messageId = idGenerator() ,
              let conversationId = conversationId ,
              let name = self.title ,
              let selfSender = self.selfSender else {
                  return
              }
        
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage ,
           let imageData = image.pngData() {
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " " , with: "-") + ".png"
            
            StorageManager.shared.uploadMessagePicture(with: imageData, fileName: fileName, completion: {[weak self] result in
                switch result {
                    
                    
                case .success(let urlString):
                    
                    guard let url = URL(string: urlString), let placeholder = UIImage(systemName: "plus")  , let strongSelf = self else {
                        return
                    }
                    
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    
                    let message = Message(sender: selfSender, messageId: messageId, sentDate: Date( ), kind: .photo(media))
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message) { success in
                        if success {
                            print("sent photo message")
                        }else {
                            print("faild to send photo message")
                        }
                    }
                case .failure(_):
                    print("faild to upload message photo")
                }
            })
        }
        else if let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL{
            print("video URL ------------ \(videoUrl)")
            let fileName = "video_message_" + messageId.replacingOccurrences(of: " " , with: "-") + ".mov"
            
            
            StorageManager.shared.uploadMessageVideo(with: videoUrl.standardizedFileURL, fileName: fileName, completion: {[weak self] result in
                switch result {
                    
                    
                case .success(let urlString):
                    
                    guard let url = URL(string: urlString), let placeholder = UIImage(systemName: "plus")  , let strongSelf = self else {
                        return
                    }
                    
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    
                    let message = Message(sender: selfSender, messageId: messageId, sentDate: Date( ), kind: .video(media))
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message) { success in
                        if success {
                            print("sent video message")
                        }else {
                            print("faild to send video")
                        }
                    }
                case .failure(_):
                    print("faild to upload message video")
                }
            })
            
        }
        
        
        
    }
    
}


extension ChatViewController : InputBarAccessoryViewDelegate{
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty  , let selfSender = self.selfSender , let messageId = idGenerator() else {
            return
        }
        let message = Message(sender: selfSender, messageId: messageId, sentDate: Date( ), kind: .text(text))
        if isNewConversation {
            
            
            DatabaseManager.shared.createNewConversation(with: otherUserEmail,name: self.title ?? "user" , firstMessage: message, completion:    { [weak self] success in
                if success {
                    self?.isNewConversation = false
                    let conversation = "conversation_\(message.messageId)"
                    self?.conversationId = conversation
                    self?.listenForMessages(id: conversation, shouldScrollToBottom: true)
                    self?.messageInputBar.inputTextView.text = nil
                }
                else {
                    
                }
            }  )
        }
        else {
            
            guard let conversationId = conversationId , let name = self.title else {
                return
            }
            
            DatabaseManager.shared.sendMessage(to: conversationId,otherUserEmail : otherUserEmail ,name : name, newMessage: message) {[weak self] success in
                if success {
                    self?.messageInputBar.inputTextView.text = nil
                }else {
                    
                }
            }
            
        }
        
    }
    private func idGenerator ( ) -> String?{
        //otherUserEmail , senderEmail , date
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeCurrenetEmail = DatabaseManager.safeEmail(email: currentUserEmail)
        let dateString = Self.dateFormatter.string(from: Date( ))
        let newId = "\(otherUserEmail)_\(safeCurrenetEmail)_\(dateString)"
        return newId
    }
}

extension ChatViewController : MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate{
    func currentSender() -> SenderType {
        if let sender = selfSender  {
            return sender
        }
        fatalError("self sender in nil , email should be cashed")
        
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
        case .text(_):
            break
        case .attributedText(_):
            break
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            
            imageView.sd_setImage(with: imageUrl, completed: nil)
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
    }
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId{
            return .link
        }else{
            return .lightGray
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId{
            if let currentImageUrl = self.senderPhotoUrl{
                avatarView.sd_setImage(with: currentImageUrl, completed: nil)
            }
            else {
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                    return
                }
                let safeEmail = DatabaseManager.safeEmail(email: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                
                StorageManager.shared.downloadURL(for: path) { [weak self] result in
                    switch result {
                        
                    case .success(let url):
                        self?.senderPhotoUrl = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                       
                    case .failure(_):
                        print("error in chats avatar img")
                    }
                }
            }
        }else {
            
            if let otherUserPhotoUrl = self.otherUserPhotoUrl{
                avatarView.sd_setImage(with: otherUserPhotoUrl, completed: nil)
            }
            else {
                 let email = self.otherUserEmail
                let safeEmail = DatabaseManager.safeEmail(email: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                
                StorageManager.shared.downloadURL(for: path) { [weak self] result in
                    switch result {
                        
                    case .success(let url):
                        self?.otherUserPhotoUrl = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                       
                    case .failure(_):
                        print("error in chats avatar img")
                    }
                }
            }
        }
        
    }
    
    
    
    
    
}
extension ChatViewController : MessageCellDelegate {
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        switch message.kind {
        case .text(_):
            break
        case .attributedText(_):
            break
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            
            let vc = PhotoViewerViewController(with: imageUrl)
            self.navigationController?.pushViewController(vc, animated: true)
            
        case .video(let media):
            guard let videoUrl = media.url else {
                return
            }
            
            let vc = AVPlayerViewController( )
            
            vc.player = AVPlayer( url: videoUrl)
            present ( vc , animated:  true)
            
             
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
        
    }
}
