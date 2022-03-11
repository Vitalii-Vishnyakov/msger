//
//  NewConversationViewController.swift
//  Messenger
//
//  Created by Виталий on 01.03.2022.
//

import UIKit
import JGProgressHUD
class NewConversationViewController: UIViewController {
    
    private let spinner = JGProgressHUD( style: .dark)
    private let standardAppearance = UINavigationBarAppearance()
    
    private var users = [ [String : String]]( )
    private var results = [ SearchResult]( )
    
    private var hasFetched = false
    
    public var completion : ((SearchResult) -> (Void))?
    
    
    private let searchBar : UISearchBar = {
        let searchBar = UISearchBar( )
        searchBar.placeholder = "Search for Users..."
        return searchBar
    }( )
    private let noResoultsLabel : UILabel = {
        let label = UILabel( )
        label.text = "No Results"
        label.textAlignment = .center
        label.textColor = .green
        label.font = .systemFont(ofSize: 21)
        label.isHidden = true
        return label
    }( )
    
    private let tableView: UITableView = {
       let table = UITableView()
        table.register(NewConversationViewCell.self, forCellReuseIdentifier: NewConversationViewCell.id)
        table.isHidden = true
       return table
    }( )
    
 
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(noResoultsLabel)
        view.addSubview(tableView)
        
        tableView.delegate  = self
        tableView.dataSource = self
        standardAppearance.configureWithOpaqueBackground()
        navigationController?.navigationBar.scrollEdgeAppearance = standardAppearance
        searchBar.delegate = self
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
        searchBar.becomeFirstResponder()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame  = view.bounds
        noResoultsLabel.frame = CGRect(x: 0, y: (view.height - 200) / 2 , width: view.width, height: 200)
    }
    
    @objc private func dismissSelf( ){
        dismiss(animated: true)
    }
    
}
extension NewConversationViewController : UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text , !text.replacingOccurrences(of: " ", with: "").isEmpty else{
            return
        }
        searchBar.resignFirstResponder()
        results.removeAll()
        spinner.show(in: view)
        self.searchUsers(query: text)
    }
    
    func searchUsers(query : String){
        if hasFetched {
            filterUsers(with: query)
        }
        else {
            DatabaseManager.shared.getAllUsers { [weak self] result in
                switch result {
                case .success(let userCollection):
                    self?.hasFetched = true
                    self?.users = userCollection
                    
                    self?.filterUsers(with: query)
                case .failure(let error) :
                    print("Faild to get users \(error)")
                
                }
            }
        }
    }
    
    func filterUsers( with term : String){
        guard hasFetched , let currentUersEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(email: currentUersEmail)
        
        
        self.spinner.dismiss(animated: true)
        let results : [ SearchResult] = self.users.filter {
            guard let email = $0["email"] , email != safeEmail else {
                return false
            }
            
            
            
            guard let name = $0["name"]?.lowercased()  else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        }.compactMap {
            
            
            
            guard let email = $0["email"] ,
            let name = $0["name"]
            else {
                return nil
            }

           
            return SearchResult(name: name, email: email)
        }
        self.results = results
        updateUI()
        
        
    }
    func updateUI() {
        if results.isEmpty{
            self.noResoultsLabel.isHidden = false
            self.tableView.isHidden = true
            
        }
        else {
            self.noResoultsLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}

extension NewConversationViewController: UITableViewDelegate , UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationViewCell.id, for: indexPath) as! NewConversationViewCell
        cell.configure(with: model)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let targetUserData = results[indexPath.row]
        
        dismiss(animated: true, completion: {[weak self] in
                                              self?.completion?(targetUserData) })
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
}

struct SearchResult {
    let name : String
    let email : String
}
