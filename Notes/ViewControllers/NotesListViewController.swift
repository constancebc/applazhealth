//
//  NotesListViewController.swift
//  Whirlpost
//
//  Created by Sadaf Khan on 18/08/23.
//  Copyright © 2023 Sevenstar Infotech. All rights reserved.
//

import UIKit

class NotesListViewController: UIViewController {

    @IBOutlet weak private var collectionView: UICollectionView!
    
    private var sharedObj: Shared?
    private var notes = [Note]()    
    private var database = DatabaseService() //Database
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialSetUp()
        configureCollectionView()
    }
    
    
    @IBAction private func btn_Back(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
}

private extension NotesListViewController {
    func initialSetUp() {
        sharedObj = Shared.sharedInstance
        
        if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
             self.getNotesAllCategories()
        }
    }
    
    func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
    }
    
    
}

extension NotesListViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return notes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NoteCollectionItemCell", for: indexPath) as! NoteCollectionItemCell
        cell.configureCell(itemData: notes[indexPath.row])
        
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
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let noteTitleListVC = self.storyboard?.instantiateViewController(withIdentifier: "NoteTitleListVC") as! NoteTitleListVC
         var userNotes = notes[indexPath.row]
        if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
             guard let noteBody = userNotes.noteBody else { return }
              noteTitleListVC.noteDictionary = ["NotesBody" : noteBody,
                                                "CategoryKey" : userNotes.categoryKey!,
                                                "CategoryNoteName" : userNotes.categoryName! ]
        } else {
            guard let noteBody = userNotes.noteBody else{ return }
            noteTitleListVC.noteDictionary = ["NotesBody" : noteBody,
                                              "CategoryNoteName" : userNotes.categoryName!]
            
            noteTitleListVC.competionHandler = {[weak self] in
                // Delete notesTitle locally
                self?.notes.remove(at: indexPath.row)
                userNotes.noteBody?.removeAll()
                userNotes.noteBody?.append(contentsOf: $0)
                self?.notes.append(userNotes)
                self?.collectionView.reloadData()
            }
        }
        self.navigationController?.pushViewController(noteTitleListVC, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.collectionView.frame.width / 2 - 5
        
        return CGSize(width: width, height: 150)
    }
    
}

//MARK: - Fire Base
extension NotesListViewController {

    //MARK:- GET NOTE'S ALL CATEGORIES
    func getNotesAllCategories() {
        database.getData { (arrayOfNotes) in
            DispatchQueue.main.async {
                self.notes = arrayOfNotes
                self.collectionView.reloadData()
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
            self.collectionView.reloadData()
        }
    }
    
    func updateCategoryNotes(indexPath: IndexPath) {
        var note = self.notes[indexPath.row]
        
        let alertController = UIAlertController(title: "Notebook", message: "Update Notebook", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Update", style: .default) { (_) in
            if let field = alertController.textFields![0] as? UITextField {
                if field.text?.removeNull() != "" {
                    
                    if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
                        self.database.editDatabaseRecords(categoryNote: field.text!.removeNull(), titleNote: nil, categoryKey: note.categoryKey, titleKey: nil, note: nil){ (err) in
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
                        self.collectionView.reloadData()
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
class NoteCollectionItemCell: UICollectionViewCell {
    
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var deleteButton: UIButton!
    @IBOutlet weak private var editButton: UIButton!
    @IBOutlet weak private var gradientBackGroundView: UIView!
    
    var deleteButtonClouser: (() -> ())?
    var editButtonClouser: (() -> ())?
    
    override func awakeFromNib() {
        updateBackgroundColor()
        deleteButton.madeCornerCircularWithShadow()
        editButton.madeCornerCircularWithShadow()
        gradientBackGroundView.addCornerRadius(radius: 15)
    }
    
    func configureCell(itemData: Note) {
        self.titleLabel.text = itemData.categoryName
        deleteButton.removeTarget(self, action: #selector(btn_DeleteTapped(_:)), for: .touchUpInside)
        deleteButton.setImage(UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 21, weight: .regular)), for: .normal)
        deleteButton.tintColor = ApplazAppearance.accent
        deleteButton.accessibilityLabel = "More notebook options"
        deleteButton.showsMenuAsPrimaryAction = true
        deleteButton.menu = UIMenu(children: [UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
            self?.deleteButtonClouser?()
        }])
    }
    
    @IBAction private func btn_DeleteTapped(_ sender: Any) {
        deleteButtonClouser?()
    }
    
    @IBAction private func btn_EditTapped(_ sender: Any) {
        editButtonClouser?()
    }
    
    private func updateBackgroundColor() {
        
        let defaults = UserDefaults.standard
        let colorindex = defaults.integer(forKey: MYTHEMECOLORINDEX)
        
        var mythemecolor1 = mythemeColor5_1
        var mythemecolor2 = mythemeColor5_2
        
        switch colorindex {
        case 1:
            mythemecolor1 = mythemeColor1_1
            mythemecolor2 = mythemeColor1_2
        case 2:
            mythemecolor1 = mythemeColor2_1
            mythemecolor2 = mythemeColor2_2
        case 3:
            mythemecolor1 = mythemeColor3_1
            mythemecolor2 = mythemeColor3_2
        case 4:
            mythemecolor1 = mythemeColor4_1
            mythemecolor2 = mythemeColor4_2
        case 5:
            mythemecolor1 = mythemeColor5_1
            mythemecolor2 = mythemeColor5_2
        default:
            mythemecolor1 = mythemeColor5_1
            mythemecolor2 = mythemeColor5_2
        }
        
        let view = self.gradientBackGroundView
        let layer = view?.layer as! CAGradientLayer
        layer.colors = [mythemecolor1,mythemecolor2].map({$0.cgColor})
        
        layer.startPoint = CGPoint(x: 0, y: 1)
        layer.endPoint = CGPoint(x: 1, y: 0.0)
    }
}
