//
//  EditProfileViewController.swift
//  Project
//
//  Created by Bossly on 10/12/16.
//  Copyright © 2016 Bossly. All rights reserved.
//

import UIKit
import Firebase
import Photos
import SDWebImage

class EditProfileViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var profileView:UITextField?
    @IBOutlet weak var profileBioView: UITextView?
    @IBOutlet weak var profileImage:ProfileView?
    @IBOutlet weak var uploadActivity:UIActivityIndicatorView?
    private var isUploadingPhoto = false
    var usernameCheckTimer: Timer?
    var user:SocialUserModel?
    private var database = DatabaseService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let currentUser = SocialUserModel.current {
            self.user = currentUser
            
            if let _user = self.user {
                _user.fetchInBackground(completed: { (model, success) in
                    self.profileView?.text = _user.getName()
                    self.profileBioView?.text = _user.bio
                    self.profileImage?.sd_setImage(with: URL(string:_user.photo))
                })
            }
        }
        profileView!.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard isMovingFromParent || isBeingDismissed || navigationController?.isBeingDismissed == true else { return }
        let username = self.profileView?.text ?? (SocialUserModel.current?.getName() ?? "")
        if username != SocialUserModel.current?.getName() {
            self.database.checkIfUserNameExistOrNot(userName: username) { isExist in
                Indicator.shared.hideProgressView()
                if isExist {
                    return
                } else {
                    // Username doesn't exist, it's safe to proceed
                    self.user?.name = username
                    self.user?.bio = self.profileBioView?.text ?? ""
                    self.user?.ref.updateChildValues(["User Name": username, "bio": self.profileBioView?.text ?? ""])
                }
            }
        } else {
            // Username is the same as the current one, proceed without checking
            self.user?.name = username
            self.user?.bio = self.profileBioView?.text ?? ""
            self.user?.ref.updateChildValues(["User Name": username, "bio": self.profileBioView?.text ?? ""])
        }
    }
    
    func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                completion(newStatus == .authorized || newStatus == .limited)
            }
        case .limited:
            completion(true)
        @unknown default:
            completion(false)
        }
    }
    
    func presentImagePicker() {
        requestPhotoLibraryPermission { [weak self] granted in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if granted {
                    let picker = UIImagePickerController()
                    picker.delegate = self
                    picker.allowsEditing = true
                    self.present(picker, animated: true)
                } else {
                    let alert = UIAlertController(title: "Permission Denied", message: "Please enable photo library access in Settings to set a profile photo.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    @IBAction func changePhoto(_ sender:Any) {
        
        presentImagePicker()
    }
    
    @IBAction func linkFacebook() {
        // TODO: link facebook to account
        
    }
    
    @IBAction func linkTwitter() {
        // TODO: link twitter to account
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        if let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage {
            picker.dismiss(animated: true) {
                self.compressImageToUpload(image: image)
            }
        }
    }
    
    func compressImageToUpload(image: UIImage) {
        guard !isUploadingPhoto else { return }
        isUploadingPhoto = true
        let previousImage = profileImage?.image
        profileImage?.sd_cancelCurrentImageLoad()
        profileImage?.image = image
        uploadActivity?.startAnimating()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let data = ApplazImagePayload.jpeg(from: image)
            DispatchQueue.main.async {
                guard let data else {
                    self.isUploadingPhoto = false
                    self.uploadActivity?.stopAnimating()
                    self.profileImage?.image = previousImage
                    let alert = UIAlertController(title: "Couldn't prepare photo", message: "Choose another image and try again.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                    return
                }
                self.upload(photoData: data) { success in
                    self.isUploadingPhoto = false
                    self.uploadActivity?.stopAnimating()
                    self.profileImage?.image = success ? UIImage(data: data) : previousImage
                }
            }
        }
    }

    // Helper function to resize the image
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height

        // Choose the smaller ratio to maintain aspect ratio
        let newSize = CGSize(width: size.width * min(widthRatio, heightRatio),
                             height: size.height * min(widthRatio, heightRatio))
        let rect = CGRect(origin: .zero, size: newSize)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }

    
    
    func upload(photoData: Data, with complete: @escaping (Bool) -> Void) {
        guard let user = self.user, let userKey = user.ref.key,
              Auth.auth().currentUser?.uid == userKey, !photoData.isEmpty else {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Profile photo wasn't saved", message: "Sign in again to save your profile photo.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                if self.view.window != nil { self.present(alert, animated: true) }
                complete(false)
            }
            return
        }
        self.user = user
        func finish(_ error: Error?) {
            DispatchQueue.main.async {
                if let error {
                    let alert = UIAlertController(title: "Profile photo wasn't saved", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    if self.view.window != nil { self.present(alert, animated: true) }
                }
                if error == nil {
                    NotificationCenter.default.post(name: Notification.Name("ApplazProfilePhotoUpdated"), object: userKey)
                }
                complete(error == nil)
            }
        }
        ApplazImageUploader.upload(photoData, path: "\(userKey)-\(Date().timeIntervalSince1970).jpg") { result in
            switch result {
            case .failure(let error): finish(error)
            case .success(let url):
                guard Auth.auth().currentUser?.uid == userKey else {
                    finish(NSError(domain: "ProfilePhoto", code: 2, userInfo: [NSLocalizedDescriptionKey: "Sign in again to save your profile photo."]))
                    return
                }
                user.ref.child("photo").setValue(url.absoluteString) { error, _ in
                    guard error == nil else { finish(error); return }
                    let oldURL = user.photo
                    user.photo = url.absoluteString
                    SDImageCache.shared.removeImage(forKey: oldURL) {
                        SDImageCache.shared.removeImage(forKey: url.absoluteString) { finish(nil) }
                    }
                }
            }
        }
    }

    
}


extension UIImage {
    enum JPEGQuality: CGFloat {
        case negative  = -2.0
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }

    /// Returns the data for the specified image in JPEG format.
    /// If the image object’s underlying image data has been purged, calling this function forces that data to be reloaded into memory.
    /// - returns: A data object containing the JPEG data, or nil if there was a problem generating the data. This function may return nil if the image has no data or if the underlying CGImageRef contains data in an unsupported bitmap format.
    func jpeg(_ jpegQuality: JPEGQuality) -> Data? {
        return jpegData(compressionQuality: jpegQuality.rawValue)
    }
}
extension EditProfileViewController:UITextFieldDelegate{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        profileView!.resignFirstResponder()
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let username = self.profileView?.text ?? (SocialUserModel.current?.getName() ?? "")
        if username != SocialUserModel.current?.getName() {
            self.database.checkIfUserNameExistOrNot(userName: username) { isExist in
                if isExist {
                    self.normal_AlertMessage(message: "The entered username is already exists. Please enter a new username.")
                }
            }
        }
        profileView!.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard let text = textField.text else { return true }

            if textField == profileView {
                let proposedText = (text as NSString).replacingCharacters(in: range, with: string)
                let isInvalidInput = proposedText.contains(" ") || proposedText.count > 25

                // Allow the change only if it doesn't violate the conditions
                if isInvalidInput {
                    return false
                }

                // Invalidate any existing timer
                usernameCheckTimer?.invalidate()
                
                // Set up a new timer to check the username after a delay
                usernameCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                    self?.checkUsernameAvailability(proposedText)
                }
            }

            return true
        }

        private func checkUsernameAvailability(_ username: String) {
            // Ensure we're not checking the current username
            if username != SocialUserModel.current?.getName() {
                self.database.checkIfUserNameExistOrNot(userName: username) { isExist in
                    if isExist {
                        self.normal_AlertMessage(message: "The entered username already exists. Please enter a new username.")
                    }
                }
            }
        }
}
