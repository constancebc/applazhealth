//
//  CreateViewController.swift
//  b03-ios
//
//  Created by Bossly on 9/12/16.
//  Copyright © 2016 Bossly. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation
import MobileCoreServices

class CreateViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!

    var currentUser: SocialUserModel? = SocialUserModel.current
    private var sharedObj: Shared?
    private var notes = [Note]()
    private var database = DatabaseService() //Database
    
    override func viewDidLoad() {
        initialSetUp()
    }
}

extension CreateViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "NotesTableCell") as! NotesTableCell
        cell.configureCell(noteData: self.notes[indexPath.row])
        
        cell.editButtonClouser = { [weak self] in
            self?.updateCategoryNotes(indexPath: indexPath)
        }
        
        cell.deleteButtonClouser = { [weak self] in
            alertView(nil, kDELETE_CATEGORY, ["No", "Yes"]) { (index) in
                if index == 1 {
                    self?.deleteNotesCategories(indexPath: indexPath)
                }
            }
        }
        
        cell.privateButtonClouser = { [weak self] in
            guard let self else { return }
            
            var note = self.notes[indexPath.row]
                guard let isPrivateNote = note.isPrivateNote else { return }
                
                if isPrivateNote {
                    // Ask here to make socialised
                    self.alertPermissionMessage(message: "Are you sure? \n To make your notebook public.") { isProceed in
                        if isProceed {
                            // Update the note as social isPrivate = false
                            if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
                                self.database.editDatabaseRecords(categoryNote: note.categoryName, titleNote: nil, categoryKey: note.categoryKey, titleKey: nil, note: nil, isPrivateNote: false){ (err) in
                                    if let _ = err {
                                        // Toast(text: "\(kCATEGORY_NOT_UPDATED)").show()
                                    } else {
                                        // Toast(text: "\(kCATEGORY_UPDATED)").show()
                                    }
                                }
                                  self.getNotesAllCategories()
                            } else {
                                note.categoryName = note.categoryName
                                self.notes.remove(at: indexPath.row)
                                self.notes.append(note)
                                self.tableView.reloadData()
                            }
                        }
                    }
                } else {
                    // Ask here to make private
                    self.alertPermissionMessage(message: "Are you sure? \n To make your notebook private.") { isProceed in
                        // Update the note as private = true
                        if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
                            self.database.editDatabaseRecords(categoryNote: note.categoryName, titleNote: nil, categoryKey: note.categoryKey, titleKey: nil, note: nil, isPrivateNote: true){ (err) in
                                if let _ = err {
                                    // Toast(text: "\(kCATEGORY_NOT_UPDATED)").show()
                                } else {
                                    // Toast(text: "\(kCATEGORY_UPDATED)").show()
                                }
                            }
                              self.getNotesAllCategories()
                        } else {
                            note.categoryName = note.categoryName
                            self.notes.remove(at: indexPath.row)
                            self.notes.append(note)
                            self.tableView.reloadData()
                        }
                    }
                }
        }
        
        return cell
    }
}
extension CreateViewController {
    func initialSetUp() {
        sharedObj = Shared.sharedInstance
        self.tableView.delegate = self
        self.tableView.dataSource = self
        if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
             self.getNotesAllCategories()
        }
    }
}

//MARK: - Fire Base
extension CreateViewController {

    //MARK:- GET NOTE'S ALL CATEGORIES
    func getNotesAllCategories(specificUserId: String? = nil) {
        database.getData(specificUserId: specificUserId) { (arrayOfNotes) in
            DispatchQueue.main.async {
                self.notes = arrayOfNotes
                self.tableView.reloadData()
            }
        }
    }
    
    //MARK:- DELETE NOTE'S CATEGORIES
    func deleteNotesCategories(indexPath: IndexPath) {
        if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
            let note = notes[indexPath.row]
            database.deleteFromDatabase(category: note.categoryKey, title: nil)
            self.getNotesAllCategories()
        } else {
            notes.remove(at: indexPath.row)
            self.tableView.reloadData()
        }
    }
    
    func updateCategoryNotes(indexPath: IndexPath) {
        var note = self.notes[indexPath.row]
        
        let alertController = UIAlertController(title: "Notebook", message: "Update Notebook", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Update", style: .default) { (_) in
            if let field = alertController.textFields![0] as? UITextField {
                if field.text?.removeNull() != "" {
                    
                    if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
                        self.database.editDatabaseRecords(categoryNote: field.text!.removeNull(), titleNote: nil, categoryKey: note.categoryKey, titleKey: nil, note: nil, isPrivateNote: nil){ (err) in
                            if let _ = err {
                                // Toast(text: "\(kCATEGORY_NOT_UPDATED)").show()
                            } else {
                                // Toast(text: "\(kCATEGORY_UPDATED)").show()
                            }
                        }
                        self.getNotesAllCategories()
                    } else {
                        note.categoryName = field.text!.removeNull()
                        self.notes.remove(at: indexPath.row)
                        self.notes.append(note)
                        self.tableView.reloadData()
                    }
                    
                } else {
                    // Toast(text: kENTER_NOTE_CATEGORY).show()
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.text = note.categoryName!
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.navigationController?.present(alertController, animated: true, completion: nil)
    }
}

class NotesTableCell: UITableViewCell {
    
    @IBOutlet weak private var customBackgroundView: UIView!
    @IBOutlet weak private var notesTitle: UILabel!
    @IBOutlet weak private var btn_EditRef: UIButton!
    @IBOutlet weak private var btn_DeleteRef: UIButton!
    @IBOutlet weak private var btn_PrivateRef: UIButton!
    
    var editButtonClouser: (() -> ())?
    var deleteButtonClouser: (() -> ())?
    var privateButtonClouser: (() -> ())?
    
    override func awakeFromNib() {
        customBackgroundView.addCornerRadius(radius: 15)
        btn_EditRef.madeCornerCircularWithShadow()
        btn_DeleteRef.madeCornerCircularWithShadow()
        btn_PrivateRef.madeCornerCircularWithShadow()
    }
    
    func configureCell(noteData: Note) {
        self.notesTitle.text = noteData.categoryName
                        
        if noteData.isPrivateNote ?? false {
            btn_PrivateRef.setImage(UIImage(systemName: "lock"), for: .normal)
        } else {
            btn_PrivateRef.setImage(UIImage(systemName: "globe.americas.fill"), for: .normal)
        }
    }
    
    @IBAction func btn_Edit(_ sender: Any) {
        editButtonClouser?()
    }
    
    @IBAction func btn_Delete(_ sender: Any) {
        deleteButtonClouser?()
    }
    
    @IBAction func btn_Private(_ sender: Any) {
        privateButtonClouser?()
    }
}





///// Old code of original Create post from the template
//class CreateViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//
//    @IBOutlet weak var previewView: UIImageView?
//    @IBOutlet weak var descriptionView: UITextView? {
//        didSet {
//            descriptionView?.layer.cornerRadius = 6
//        }
//    }
//    @IBOutlet weak var descriptionPlaceholderView: UILabel?
//    @IBOutlet weak var progressView: UIProgressView?
//    @IBOutlet weak var progressLabel: UILabel?
//    @IBOutlet weak var shareButton: UIBarButtonItem?
//    @IBOutlet weak var hintLabel: UILabel?
//
//
//    var previewImage: UIImage? {
//        didSet {
//            previewView?.image = previewImage
//            shareButton?.isEnabled = (previewImage != nil)
//            hintLabel?.isHidden = (previewImage != nil)
//        }
//    }
//    var videoData: Data?
//
//    override func viewDidLoad() {
//        openPicker(true)
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//        descriptionView?.becomeFirstResponder()
//    }
//
//    @IBAction func shareStory(_ sender: Any) {
//        uploadMedia()
//    }
//
//    @IBAction func onCancel(_ sender: Any) {
//        self.dismiss(animated: true, completion: {})
//    }
//
//    @IBAction func onEditMedia(_ sender: Any) {
//        // open picker
//        openPicker()
//    }
//
//    // MARK: - Helpers
//
//    func openPicker(_ animated:Bool = true) {
//        self.progressView?.isHidden = true
//        self.progressLabel?.isHidden = true
//
//        if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
//            // Has camera
//            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//
//            alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action) in
//                self.openCamera(.photo)
//            }))
//
//            alert.addAction(UIAlertAction(title: "Recorder", style: .default, handler: { (action) in
//                self.openCamera(.video)
//            }))
//
//            alert.addAction(UIAlertAction(title: "Library", style: .default, handler: { (action) in
//                self.openLibrary()
//            }))
//
//            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//
//            present(alert, animated: true, completion: nil)
//        } else {
//            self.openLibrary(animated)
//        }
//    }
//
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//
//        guard let mediaType = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.mediaType.rawValue)] as? String else {
//             return
//        }
//
//        if "public.movie".compare(mediaType).rawValue == 0,
//           let video = info[.mediaURL] as? URL {
//            // for movie
//            videoData = try? Data(contentsOf: video)
//
//            // generate thumbnail
//            let asset = AVAsset(url: video)
//            let imageGenerator = AVAssetImageGenerator(asset: asset)
//            imageGenerator.appliesPreferredTrackTransform = true
//
//            if (asset.tracks(withMediaType: .video).count > 0) {
//                var time = asset.duration
//                // If possible - take not the first frame (it could be completely black or white on camara's videos)
//                time.value = min(time.value, 2)
//
//                if let imageRef = try? imageGenerator.copyCGImage(at: time, actualTime: nil) {
//                    let image = UIImage(cgImage: imageRef)
//                    previewImage = image
//                }
//            } else {
//                // error with loading video
//            }
//        } else if let image = info[.editedImage] as? UIImage {
//            previewImage = image
//            videoData = nil
//        }
//
//        // hide picker and show uploading process
//        picker.dismiss(animated: true, completion: {})
//    }
//
//    func onCompleted() {
//        self.dismiss(animated: true, completion: {})
//    }
//
//    func uploadMedia() {
//        self.shareButton?.isEnabled = false
//
//        guard let image = previewImage,
//              let data = image.jpegData(compressionQuality: kJPEGImageQuality) else
//        {
//            let message = "Cannot generate thumbnail for selected video"
//            let alert = UIAlertController(title: "Warning", message: message, preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
//            present(alert, animated: true, completion: nil)
//            self.shareButton?.isEnabled = true
//            return
//        }
//
//        self.progressView?.isHidden = false
//        self.progressLabel?.isHidden = false
//
//        // Data in memory
//        let storage = Storage.storage().reference()
//        let type = (videoData == nil) ? ".jpg" : ".mov"
//
//        if let user = Auth.auth().currentUser {
//            let imgref = storage.child("\(user.uid)/\(NSDate().timeIntervalSince1970).jpg")
//            let metadata = StorageMetadata(dictionary: [ "contentType" : "image/jpg"])
//
//            // Upload the file to the path "media/"
//            let uploadTask = imgref.putData(data, metadata: metadata) { metadata, error in
//                if (error != nil) {
//                    // Uh-oh, an error occurred!
//                    let alert = UIAlertController(title: kAlertErrorTitle, message: "Can't upload now. Please try later", preferredStyle: .alert)
//                    alert.addAction(UIAlertAction(title: kAlertErrorDefaultButton, style: .default) { (action) in })
//                    self.present(alert, animated: true) {}
//                    self.shareButton?.isEnabled = true
//                } else {
//                    imgref.downloadURL(completion: { (url, error) in
//                        let urlImage = url?.absoluteString ?? ""
//
//                        if let video = self.videoData {
//                            let videoref = storage.child("\(user.uid)/\(NSDate().timeIntervalSince1970)\(type)")
//                            let videoMeta = StorageMetadata(dictionary: [ "contentType" : "video/quicktime"])
//                            videoref.putData(video, metadata: videoMeta) { metadata, error in
//                                videoref.downloadURL(completion: { (vurl, verror) in
//                                    let videourl = vurl?.absoluteString ?? ""
//                                    let comment = self.descriptionView?.text
//                                    Story.createStory(user, url: urlImage, video: videourl, comment: comment)
//                                    self.onCompleted()
//                                })
//                            }
//                        } else {
//                            let comment = self.descriptionView?.text
//                            Story.createStory(user, url: urlImage, video:"", comment: comment)
//                            self.onCompleted()
//                        }
//
//                        self.shareButton?.isEnabled = true
//                        self.progressView?.isHidden = true
//                        self.progressLabel?.text = kMessageUploadingDone
//                    })
//                }
//            }
//
//            uploadTask.observe(.progress) { snapshot in
//                // A progress event occurred
//                if let progress = snapshot.progress {
//                    let complete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
//                    let percentComplete = Int(complete * 98) + 1 // never show 0% or 100%
//                    self.progressView?.progress = Float(complete)
//                    self.progressLabel?.text = "\(kMessageUploadingProcess): \(percentComplete)%"
//                }
//            }
//        } else {
//            self.shareButton?.isEnabled = true
//        }
//    }
//
//    func openCamera(_ mode:UIImagePickerController.CameraCaptureMode = .photo, _ animated: Bool = true) {
//        let picker:UIImagePickerController = UIImagePickerController()
//        picker.sourceType = .camera
//        picker.allowsEditing = true
//        picker.videoMaximumDuration = 60 // seconds
//
//        if (mode == .video) {
//            picker.mediaTypes = [kUTTypeMovie] as [String]
//            picker.cameraCaptureMode = mode
//        } else {
//            picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .camera)!
//        }
//
//        picker.delegate = self
//        self.present(picker, animated: animated, completion: nil)
//    }
//
//    func openLibrary(_ animated: Bool = true) {
//        let picker:UIImagePickerController = UIImagePickerController()
//        picker.sourceType = .photoLibrary
//        picker.allowsEditing = true
//        picker.videoMaximumDuration = 60 // seconds
//        picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
//        picker.delegate = self
//        self.present(picker, animated: animated, completion: nil)
//    }
//
//    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        picker.dismiss(animated: true, completion: {})
//    }
//}

//extension CreateViewController: UITextViewDelegate {
//    func textViewDidChange(_ textView: UITextView) {
//        descriptionPlaceholderView?.isHidden = !textView.text.isEmpty
//    }
//}
