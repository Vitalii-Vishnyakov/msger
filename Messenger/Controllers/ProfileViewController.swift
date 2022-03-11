//
//  ProfileViewController.swift
//  Messenger
//
//  Created by Виталий on 01.03.2022.
//

import UIKit

import FirebaseAuth
import SDWebImage

enum ProfileViewModelType{
case info
    case logout
}

struct ProfileViewModel{
    let viewModelType : ProfileViewModelType
    let title : String
    let handler : (( ) -> Void)?
    
}

class ProfileViewController: UIViewController {
    
    
    @IBOutlet var tableView : UITableView!
    
    var data = [ProfileViewModel]( )
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.id )
        data.append(ProfileViewModel(viewModelType: .info, title: "Name: \( UserDefaults.standard.value(forKey : "name") as? String ?? "No name")", handler: nil))
        data.append(ProfileViewModel(viewModelType: .logout, title: "Log Out", handler: { [weak self ] in
            let alert = UIAlertController(title: "Log Out?", message: "", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Log out", style: .destructive, handler: { [weak self] _ in
                UserDefaults.standard.setValue(nil, forKey: "email")
                UserDefaults.standard.setValue(nil, forKey: "name")
                
                do {
                    try FirebaseAuth.Auth.auth().signOut()
                    let vc = LoginViewController( )
                    let nav = UINavigationController( rootViewController: vc)
                    
                    
                    nav.modalPresentationStyle = .fullScreen
                    self?.present(nav, animated: true, completion: nil)
                    
                } catch  {
                    print("LogOut error")
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self?.present(alert , animated: true, completion: nil)
            
            
        }))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
    }
    
    func createTableHeader( ) -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(email: email)
        let fileName = "\(safeEmail)_profile_picture.png"
        let path = "images/" + fileName
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 300) )
        headerView.backgroundColor = .link
        
        let imageView = UIImageView(frame: CGRect(x: (headerView.width - 150)/2, y: 75, width: 150, height: 150))
        imageView.backgroundColor = .secondarySystemBackground
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 2
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width / 2 
        headerView.addSubview(imageView)
        StorageManager.shared.downloadURL(for: path, completion: { result in
            switch result {
            case .success(let url):
                imageView.sd_setImage(with: url,  completed: nil)
                
            case .failure(let error):
                print("Faild to download url : \(error)")
            }
        })
        
        return headerView
    }
    
    
}

extension ProfileViewController : UITableViewDelegate , UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.id, for: indexPath) as! ProfileTableViewCell
        let viewModel = data[indexPath.row]
        cell.setUp(with : viewModel)
        
        
        return cell
        
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        data[indexPath.row].handler?( )
        
    }
    
}


class ProfileTableViewCell : UITableViewCell {
    
    static let id = "ProfileTableViewCell"
    public func setUp ( with viewModel : ProfileViewModel) {
        self.textLabel?.text = viewModel.title
        switch viewModel.viewModelType {
            
        case .info:
            
            self.selectionStyle = .none
            self.textLabel?.textAlignment = .left
        case .logout:
          
            self.textLabel?.textColor = .red
            self.textLabel?.textAlignment = .center
        }
    }
}
