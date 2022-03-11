//
//  LoginViewController.swift
//  Messenger
//
//  Created by Виталий on 01.03.2022.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
class LoginViewController: UIViewController {
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView : UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        
        return scrollView
    }()
    
    private let emailField : UITextField = {
        let field = UITextField( )
        field.autocapitalizationType = .none
        field.autocorrectionType  = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.placeholder = "Email..."
        
        return field
    }()
    
    private let passwordField : UITextField = {
        let field = UITextField( )
        field.autocapitalizationType = .none
        field.autocorrectionType  = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        field.placeholder = "Password..."
        
        return field
    }()
    
    private let imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let loginButton : UIButton = {
        let bt = UIButton( )
        bt.setTitle("Log In", for: .normal)
        bt.backgroundColor = .link
        bt.setTitleColor(.secondarySystemBackground, for: .normal)
        bt.layer.cornerRadius = 12
        bt.layer.masksToBounds = true
        bt.titleLabel?.font = .systemFont(ofSize: 20 , weight : .bold)
        
        return bt
    }( )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        title = "Log In"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        view.addSubview(scrollView)
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        emailField.delegate = self
        passwordField.delegate = self
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.bounds
        
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: (scrollView.width - size) / 2, y: 20, width: size, height: size)
        emailField.frame = CGRect(x: 30, y: imageView.bottom + 10, width: scrollView.width - 60, height: 52)
        passwordField.frame = CGRect(x: 30, y: emailField.bottom + 10, width: scrollView.width - 60, height: 52)
        loginButton.frame = CGRect(x: 30, y: passwordField.bottom + 10, width: scrollView.width - 60, height: 52)
    }
    
    @objc private func loginButtonTapped( ){
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email  = emailField.text , let password = passwordField.text  , !email.isEmpty , !password.isEmpty , password.count >= 6 else {
            alertUserLoginError()
            return
            
        }
        spinner.show(in: view)
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] authResult , error in
           
            
            DispatchQueue.main.async {
                self?.spinner.dismiss(animated: true)
            }
            
            guard let result = authResult, error == nil else {
                print("Login error !!!")
                return
            }
            let user = result.user
            
            let safeEmail = DatabaseManager.safeEmail(email: email)
            
            DatabaseManager.shared.getDataFor(path: safeEmail) { result in
                switch result{
                    
                case .success(let data):
                    guard let userData = data as? [String: Any] ,let firstName = userData["first_name"] as? String,  let lastName = userData["last_name"] as? String else {
                        return
                    }
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                            
                case .failure(_):
                    print ("faild to fetch ")
                }
            }
            
            print("Login User \( user)")
            UserDefaults.standard.set(email, forKey: "email")
            
            
            
            self?.navigationController?.dismiss(animated: true, completion: nil)
        })
        
        
        
    }
    func alertUserLoginError( ){
        let alert = UIAlertController(title: "Woops", message: "Please enter correct data about you", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil ))
        present(alert, animated: true, completion: nil)
    }
    
    
    @objc private func didTapRegister ( ){
        let vc = RegisterViewController( )
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension LoginViewController : UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            loginButtonTapped()
        }
        return true
    }
    
}
