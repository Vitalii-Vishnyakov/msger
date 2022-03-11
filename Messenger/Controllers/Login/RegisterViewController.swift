//
//  RegisterViewController.swift
//  Messenger
//
//  Created by Виталий on 01.03.2022.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
class RegisterViewController: UIViewController {
    
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
    
    private let firstNameField : UITextField = {
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
        field.placeholder = "First Name..."
        
        return field
    }()
    
    private let lastNameField : UITextField = {
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
        field.placeholder = "Last Name..."
        
        return field
    }()
    
    
    private let imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
    }()
    
    private let loginButton : UIButton = {
        let bt = UIButton( )
        bt.setTitle("Register", for: .normal)
        bt.backgroundColor = .systemGreen
        bt.setTitleColor(.secondarySystemBackground, for: .normal)
        bt.layer.cornerRadius = 12
        bt.layer.masksToBounds = true
        bt.titleLabel?.font = .systemFont(ofSize: 20 , weight : .bold)
        
        return bt
    }( )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Log In"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        view.addSubview(scrollView)
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        emailField.delegate = self
        passwordField.delegate = self
        lastNameField.delegate = self
        firstNameField.delegate = self
        scrollView.addSubview(imageView)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        
        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didChangeProfilePhoto))
        
        imageView.addGestureRecognizer(gesture)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.bounds
       
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: (scrollView.width - size) / 2, y: 20, width: size, height: size)
        imageView.layer.cornerRadius = imageView.width/2.0
        firstNameField.frame = CGRect(x: 30, y: imageView.bottom + 10, width: scrollView.width - 60, height: 52)
        lastNameField.frame = CGRect(x: 30, y: firstNameField.bottom + 10, width: scrollView.width - 60, height: 52)
        emailField.frame = CGRect(x: 30, y: lastNameField.bottom + 10, width: scrollView.width - 60, height: 52)
        passwordField.frame = CGRect(x: 30, y: emailField.bottom + 10, width: scrollView.width - 60, height: 52)
        loginButton.frame = CGRect(x: 30, y: passwordField.bottom + 10, width: scrollView.width - 60, height: 52)
    }
    
    @objc private func didChangeProfilePhoto ( ){
        presentPhotoActionSheet( )
    }
    
    
    @objc private func loginButtonTapped( ){
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        firstNameField.resignFirstResponder()
        guard let email  = emailField.text , let password = passwordField.text  , !email.isEmpty , !password.isEmpty , password.count >= 6 , let lastName =  lastNameField.text  , !lastName.isEmpty , let firstName = firstNameField.text, !firstName.isEmpty else {
            alertUserLoginError()
            return
            
        }
        spinner.show(in: view)
        DatabaseManager.shared.userExists(with: email, complition: { [weak self] exists in
            guard let strongSelf = self else {
                
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss(animated: true)
            }
            
            guard !exists else {
                strongSelf.alertUserLoginError(message: "User alredy exist")
                return
            }
                
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: {  authResult , error in
                guard authResult != nil, error == nil else {
                    print("Creating error !!!")
                    return
                }
                UserDefaults.standard.setValue(email, forKey: "email")
                UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
                let user = ChatAppUser(firstName: firstName, lastName: lastName, emailAdress: email)
                DatabaseManager.shared.insertUser(with: user , completion: {done in
                    if done {
                        guard let image = strongSelf.imageView.image, let data = image.pngData() else {
                            return
                        }
                        let fileName = user.profilePicture
                        StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { resualt  in
                            switch resualt {
                            case .success(let downloadURL):
                                UserDefaults.standard.set(downloadURL, forKey: "profilePicture")
                                print(downloadURL)
                            case .failure(let error):
                                print(error)
                            
                            }
                        }
                    }
                })
                
                
               
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                
            })
        })
        
       
        
    }
    
    
    func alertUserLoginError( message : String =  "Please enter correct data about you"){
        let alert = UIAlertController(title: "Woops", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil ))
        present(alert, animated: true, completion: nil)
    }
    
    
    @objc private func didTapRegister ( ){
        let vc = RegisterViewController( )
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension RegisterViewController : UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            loginButtonTapped()
        }
        else if textField == firstNameField {
            lastNameField.becomeFirstResponder()
        }
        else if textField == lastNameField {
            emailField.becomeFirstResponder()
        }
        return true
    }
    
}
extension RegisterViewController : UIImagePickerControllerDelegate , UINavigationControllerDelegate{
    
    func presentPhotoActionSheet( ){
        let actionSheet = UIAlertController(title: "Profile picture", message: "Take it from...", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { [weak self] _ in
            self?.presentCamera()
        }))
        actionSheet.addAction(UIAlertAction(title: "Chose Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoPicker()
        }))
        present(actionSheet, animated: true, completion: nil)
    }
    
    func presentCamera ( ){
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true, completion: nil)
    }
    
    func presentPhotoPicker( ){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard  let selectedImage = info[UIImagePickerController.InfoKey.editedImage] else {return}
        self.imageView.image = selectedImage as? UIImage
        picker.dismiss(animated: true, completion: nil)
    }
    
}
