//
//  ViewController.swift
//  Messenger
//
//  Created by Виталий on 01.03.2022.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
import SwiftUI

struct Conversation {
    let id: String
    let name : String
    let otherUserEmail : String
    let latestMessage : LatestMessage
}
struct LatestMessage {
    let date: String
    let text : String
    let isRead : Bool
}

class ConversationsViewController: UIViewController {
    private let spinner = JGProgressHUD(style: .dark)
    
    
    private let noConversationsYet: UILabel = {
        let label = UILabel()
        label.text = "No conversations"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21)
        label.isHighlighted = true
        return label
    }( )
    
    private var converations = [Conversation] ( )
    
    private let tableView : UITableView = {
        let table = UITableView( )
        table.isHidden = true
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.id)
        
        return table
    }( )
    private var loginObserver : NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        view.addSubview(tableView)
        startListeningForConvarsations( )
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil , queue: .main, using: { [weak self] _  in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.startListeningForConvarsations()
        })
        
    }
    
    private func startListeningForConvarsations( ){
        
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        guard let email = UserDefaults.standard.value(forKey: "email" ) as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(email: email)
        
        DatabaseManager.shared.gatAllConversations(for: safeEmail) { [weak self] result in
            switch result {
                
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    self?.tableView.isHidden = true
                    self?.noConversationsYet.isHidden = false
                    return
                }
                self?.noConversationsYet.isHidden = true
                self?.tableView.isHidden = false
                self?.converations = conversations
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                self?.tableView.isHidden = true
                self?.noConversationsYet.isHidden = false
                print("failed to get conversations \(error)")
            }
        }
    }
    
    @objc private func didTapComposeButton ( ){
        
        let vc = NewConversationViewController( )
        vc.completion = {[weak self]  result in
            let currentConversation = self?.converations
            
            if let targetConversation = currentConversation?.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(email: result.email)
            }){
                let vc = ChatViewController( with: targetConversation.otherUserEmail , id: targetConversation.id)
                vc.isNewConversation = false
                vc.title = targetConversation.name
                vc.navigationItem.largeTitleDisplayMode = .never
                self?.navigationController?.pushViewController(vc, animated: true )
            }
            else {
                self?.createNewConversation(result: result)
            }
            
            
            
        }
        let navVc = UINavigationController(rootViewController: vc )
        present(navVc, animated: true, completion: nil)
    }
    
    private func createNewConversation(result : SearchResult){
        let name = result.name 
        let email = DatabaseManager.safeEmail(email: result.email)
        DatabaseManager.shared.conversationExists(with: email) { [weak self] result in
            switch result {
            case .success(let conversationId):
                let vc = ChatViewController( with: email , id: conversationId)
                vc.isNewConversation = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                self?.navigationController?.pushViewController(vc, animated: true )
            case .failure(_):
                let vc = ChatViewController( with: email , id: nil)
                vc.isNewConversation = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                self?.navigationController?.pushViewController(vc, animated: true )
            }
        }
        
      
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noConversationsYet.frame = CGRect(x: 10, y: (view.height - 100) / 2 , width: view.width - 20 , height: 100)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth( )
    }
    
    
    private func validateAuth( ){
        
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController( )
            let nav = UINavigationController( rootViewController: vc)
            
            
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false, completion: nil)
        }
    }
    
    
    
    
    
    private func fetchConverations ( ){
        tableView.isHidden = false
    }
}


extension ConversationsViewController : UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return converations.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = converations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.id, for: indexPath) as! ConversationTableViewCell
        
        cell.configure(with: model)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = converations[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        openConversation(model: model)
    }
    
    func openConversation ( model : Conversation ){
        let vc = ChatViewController( with: model.otherUserEmail , id : model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true )
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let conversationId = converations[indexPath.row].id
            
            tableView.beginUpdates()
            self.converations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            DatabaseManager.shared.deleteConversation(conversationId: conversationId) { success in
                if !success {
                   
                    print("faild to delete")
                    
                    
                }
            }
            
            
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
}
