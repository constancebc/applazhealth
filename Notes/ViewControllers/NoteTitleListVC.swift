//
//  NoteTitleListVC.swift
//  Notes
//
//  Created by Sevenstar Infotech on 07/02/18.
//  Copyright © 2018 Sevenstar Infotech. All rights reserved.
//

import UIKit
//import Toaster
import Firebase


class NoteTitleListVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    //MARK:- OBJECTS & OUTLETS
    @IBOutlet weak var userName: UIButton!
    
    @IBOutlet weak var followBtn: UIButton!
    @IBOutlet weak var lblNavigationBarTitle: UILabel!
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var tblViewNoteTitle: UITableView!
    @IBOutlet weak var lblNotesNotFound: UILabel!
    @IBOutlet weak var navigationBarView1: UIView!
    @IBOutlet weak var navigationBarView2: UIView!
    @IBOutlet weak var btnAddNote: UIButton!
    
    private var aiPanel: AIInlinePanelController?
    var isAddedFlow =  false
    private var notebookDisplayTitle: String {
        let name = categoryTitle.isEmpty ? (noteDictionary["CategoryNoteName"] as? String ?? "") : categoryTitle
        return name.isEmpty ? "Notebook" : name
    }
    var categoryTitle = ""
    var isFromProfile: Bool = false
    var userNameValue: String = ""
    var userId: String = ""
    
    var strSelectedNoteCategoryID = Int()
    var notesCategory = [Any]()
    var arrNotesTitle = [Any]()
    var selectedIndexForDelete : Int?
    var categoryNames = [String:Any]()
    var keyValueCategoryNote = [String:Any]()
    
    var competionHandler:(([NoteBody])->Void)?
    var notes = [Note]()
    
    var notesBody:[NoteBody] = [NoteBody]()
    var noteDictionary = [String:Any]()
    
    // database
    private var database = DatabaseService()
    
    var user: SocialUserModel?
    
    //MARK:- VIEW LIFE CYCLE
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isHidden = false
        self.tblViewNoteTitle.stopObserveScrollingTop()
        if let profileKey { ref?.removeObserver(withHandle: profileKey) }
        profileKey = nil
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        if isFromProfile { arrangeNotebookIdentity() }
        aiPanel = AIInlinePanelController.footer(in: self, table: tblViewNoteTitle, title: "Ask this notebook", scope: { [weak self] in
            guard let self else { return .all }
            let key = self.noteDictionary["CategoryKey"] as? String ?? ""
            if !self.isFromProfile || self.userId == Auth.auth().currentUser?.uid {
                return AIScope(key: "regular:" + key, title: self.notebookDisplayTitle, regularID: key)
            }
            return .note(self.notesBody.map { ($0.titleName ?? "") + "\n" + ($0.descriptionText ?? "") }.joined(separator: "\n"), key: "public-notebook:" + self.userId + ":" + key)
        })
        
        if isAddedFlow{
            self.getNotesAllCategories()
        }else{
            if notesBody.count > 0 {
                self.lblNavigationBarTitle.text = notebookDisplayTitle
            } else if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
                notesBody = noteDictionary["NotesBody"] as! [NoteBody]
                self.lblNavigationBarTitle.text = notebookDisplayTitle
                self.lblNotesNotFound.text = kNO_NOTE_FOUND
            } else {
                notesBody = noteDictionary["NotesBody"] as! [NoteBody]
                self.lblNavigationBarTitle.text = notebookDisplayTitle
                self.lblNotesNotFound.text = kNO_NOTE_FOUND
            }
        }
        self.tblViewNoteTitle.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        if isAddedFlow == false{
            self.getNotes()
        }
        invalidateComponents()
        lblNavigationBarTitle.text = notebookDisplayTitle
        lblNavigationBarTitle.font = ApplazAppearance.headerFont
        lblNavigationBarTitle.adjustsFontSizeToFitWidth = false
        lblNavigationBarTitle.lineBreakMode = .byTruncatingTail
        self.tblViewNoteTitle.reloadData()
        btnAddNote.isHidden =  isFromProfile
        if !userId.isEmpty {
            setProfile(userId: userId)
        } else {
            self.userName.isHidden = true
            self.followBtn.isHidden = true
        }
        self.tblViewNoteTitle.startObserveScrollingTop()
        followBtn.layer.cornerRadius = followBtn.frame.height / 2
        
        if !userId.isEmpty {
            user = SocialUserModel(userId)
            if let handle = profileKey { ref?.removeObserver(withHandle: handle) }
            ref = user?.ref
            profileKey = ref?.observe(.value) { [weak self] snapshot in
                guard let self, let user = self.user else { return }
                user.loadData(snap: snapshot) { _ in }
                self.configureNotebookIdentity()
            }
            configureNotebookIdentity()
        }
    }
    
    var ref:DatabaseQuery?
    var profileKey:UInt?


    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    
    @IBAction func followAction(_ sender: UIButton) {
        guard let user, !user.isCurrent() else { return }
        if user.isFollow { user.unfollow() } else { user.follow() }
        configureNotebookIdentity()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
            if let profileCtrl = segue.destination as? ProfileViewController {
                if let user = sender as? DatabaseReference, let key = user.key {
                    self.navigationController?.navigationBar.isHidden = false
                    self.navigationController?.navigationBar.barTintColor = .white
                    profileCtrl.currentUser = SocialUserModel(key)
                    profileCtrl.isFromSearch = true
                }
            }
    }
    
    private func arrangeNotebookIdentity() {
        guard let headerStack = followBtn.superview as? UIStackView, let bar = headerStack.superview else { return }
        userName.isHidden = true
        headerStack.removeArrangedSubview(followBtn)
        followBtn.removeFromSuperview()
        followBtn.constraints.filter { $0.firstAttribute == .height }.forEach { $0.isActive = false }
        bar.addSubview(followBtn)
        followBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            followBtn.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
            followBtn.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
            followBtn.widthAnchor.constraint(equalToConstant: 44),
            followBtn.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func configureNotebookIdentity() {
        userName.configuration = nil
        userName.setTitle(notebookDisplayTitle, for: .normal)
        userName.setTitleColor(ApplazAppearance.ink, for: .normal)
        userName.titleLabel?.font = ApplazAppearance.font(14, weight: .medium)
        userName.titleLabel?.lineBreakMode = .byTruncatingTail
        userName.isHidden = true
        userName.isUserInteractionEnabled = false
        followBtn.configuration = nil
        followBtn.setTitle(nil, for: .normal)
        followBtn.backgroundColor = .clear
        followBtn.tintColor = ApplazAppearance.accent
        followBtn.setImage(UIImage(systemName: user?.isFollow == true ? "person.crop.circle.badge.checkmark" : "person.badge.plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)), for: .normal)
        followBtn.isHidden = !isFromProfile || userId == SocialUserModel.current?.ref.key
        followBtn.accessibilityLabel = user?.isFollow == true ? "Following" : "Follow notebook creator"
        followBtn.showsMenuAsPrimaryAction = user?.isFollow == true
        followBtn.menu = user?.isFollow == true ? UIMenu(children: [UIAction(title: "Unfollow", image: UIImage(systemName: "person.badge.minus")) { [weak self] _ in
            guard let self else { return }; self.followAction(self.followBtn)
        }]) : nil
    }

    func setProfile(userId: String) {
        configureNotebookIdentity()
    }

    
    
    func getNotesAllCategories() {

        database.getData { (arrayOfNotes) in
            DispatchQueue.main.async {
                print(self.categoryTitle)
                let selectedKey = self.noteDictionary["CategoryKey"] as? String
                let obj_notes = arrayOfNotes.filter { notebook in
                    if let selectedKey, !selectedKey.isEmpty { return notebook.categoryKey == selectedKey }
                    return notebook.categoryName == self.categoryTitle
                }
                if let notebook = obj_notes.first {
                    self.noteDictionary["CategoryKey"] = notebook.categoryKey
                    self.noteDictionary["CategoryNoteName"] = notebook.categoryName
                    self.lblNavigationBarTitle.text = notebook.categoryName
                    self.configureNotebookIdentity()
                }
                
                self.notesBody = []
                for obj in obj_notes{
                    self.notesBody.append(contentsOf: obj.noteBody!)
                }
            
                print(self.notesBody.count)
                if self.notesBody.count > 0 {
                    self.tblViewNoteTitle.isHidden =  false
                    self.lblNotesNotFound.isHidden =  true
                    self.tblViewNoteTitle.reloadData()
                }
               
            }
        }
    }
    
    @IBAction func clickedOnUserName(_ sender: UIButton) {
        if !userId.isEmpty {
            let ref = SocialUserModel(userId).ref
            self.performSegue(withIdentifier: "show.profile", sender: ref)
        }
    }
    
    
    func invalidateComponents() {
        
        let defaults = UserDefaults.standard
        
        let colorIndex = defaults.integer(forKey: MYTHEMECOLORINDEX)
        
        print("selected ColorIndex")
        print(colorIndex)
        
      //  updateColor(view: navigationBarView1, index: colorIndex)
        //updateTableView()
        /*
         if colorIndex != 0 {
         
         updateColor(view: navigationBarView1, index: colorIndex)
         updateTableView()
         }
         */
        
        let fontIndex = defaults.integer(forKey: MYTHEMEFONTINDEX)
        
        print("selected FontIndex")
        print(fontIndex)
        
        updateFont(fontIndex: fontIndex)
        
        /*
        let defaults = UserDefaults.standard
        
        let colorIndex = defaults.integer(forKey: MYTHEMECOLORINDEX)
        
        print("selected ColorIndex")
        print(colorIndex)
        
        if colorIndex != 0 {
            
            updateColor(view: navigationBarView1, index: colorIndex)
            
        }
        
        let fontIndex = defaults.integer(forKey: MYTHEMEFONTINDEX)
        
        print("selected FontIndex")
        print(fontIndex)
        
        if fontIndex != 0 {
            
            updateFont(fontIndex: fontIndex)
            
        }
        */
    }
    
    func updateColor(view: UIView, index: Int) {
        
        var mythemecolor1 = mythemeColor0_1
        var mythemecolor2 = mythemeColor0_2
        
        switch index {
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
            mythemecolor1 = mythemeColor0_1
            mythemecolor2 = mythemeColor0_2
        }
        /*
        var firstColor = UIColor(rgb: mythemecolor1).withAlphaComponent(0.0)
        if index == 5 {
            firstColor = UIColor(rgb: mythemecolor1).withAlphaComponent(1.0)
        }
        let secondColor = UIColor(rgb: mythemecolor2).withAlphaComponent(1.0)
        */
        
        let layer = view.layer as! CAGradientLayer
        //layer.colors = [firstColor,secondColor].map({$0.cgColor})
        layer.colors = [mythemecolor1,mythemecolor2].map({$0.cgColor})
        layer.startPoint = CGPoint(x: 0, y: 1)
        layer.endPoint = CGPoint(x: 1, y: 0.0)
        
        
        /*
        var mythemecolor1 = mythemeColor1_1
        var mythemecolor2 = mythemeColor1_2
        
        switch index {
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
            mythemecolor1 = mythemeColor1_1
            mythemecolor2 = mythemeColor1_2
        }
        
        var firstColor = UIColor(rgb: mythemecolor1).withAlphaComponent(0.0)
        if index == 5 {
            firstColor = UIColor(rgb: mythemecolor1).withAlphaComponent(1.0)
        }
        let secondColor = UIColor(rgb: mythemecolor2).withAlphaComponent(1.0)
        
        
        let layer = view.layer as! CAGradientLayer
        layer.colors = [firstColor,secondColor].map({$0.cgColor})
        layer.startPoint = CGPoint(x: 0, y: 1)
        layer.endPoint = CGPoint(x: 1, y: 0.0)
        */
    }
    
    func updateFont(fontIndex: Int) {
        
        print("font change")
        print(fontIndex)
        
        let fontsize: CGFloat = 17
        
        switch fontIndex {
        case 1:
            lblNavigationBarTitle.font = UIFont(name: "SanFranciscoDisplay-Regular", size: fontsize)
        case 2:
            lblNavigationBarTitle.font = UIFont(name: "Comic Sans MS", size: fontsize)
        case 3:
            lblNavigationBarTitle.font = UIFont(name: "Helvetica", size: fontsize)
        case 4:
            lblNavigationBarTitle.font = UIFont(name: "Times New Roman", size: fontsize)
        case 5:
            lblNavigationBarTitle.font = UIFont(name: "Bodoni 72 Book", size: fontsize)
        default:
            lblNavigationBarTitle.font = ApplazAppearance.font(fontsize, weight: .medium)
        }
        /*
        print("font change")
        print(fontIndex)
        
        let fontsize: CGFloat = 17
        
        switch fontIndex {
        case 1:
            lblNavigationBarTitle.font = UIFont(name: "SanFranciscoDisplay-Regular", size: fontsize)
        case 2:
            lblNavigationBarTitle.font = UIFont(name: "Comic Sans MS", size: fontsize)
        case 3:
            lblNavigationBarTitle.font = UIFont(name: "Helvetica", size: fontsize)
        case 4:
            lblNavigationBarTitle.font = UIFont(name: "Times New Roman", size: fontsize)
        case 5:
            lblNavigationBarTitle.font = UIFont(name: "Bodoni 72 Book", size: fontsize)
        default:
            lblNavigationBarTitle.font = ApplazAppearance.font(fontsize, weight: .medium)
        }
        
        */
        
    }
    
    //MARK:- UITABLE VIEW DELEGATE & DATA SOURCE METHODS
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return IS_IPAD ? 35.0 : 15.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.tblViewNoteTitle.frame.size.width, height: IS_IPAD ? 35.0 : 15.0))
        headerView.backgroundColor = .clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return IS_IPAD ? 55.0 : 30.0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: IS_IPAD ? 50.0 : 35.0))
        footerView.backgroundColor = .clear
        return footerView
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IS_IPAD ? 114 : 70
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.notesBody.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = self.tblViewNoteTitle.dequeueReusableCell(withIdentifier: "NoteTitleBLViewCell") as! NoteTitleBLViewCell
        let noteBody = notesBody[indexPath.row]
        cell.lblNoteTitle.text = noteBody.titleName ?? ""
        
        cell.btnDelete.tag = indexPath.row
        cell.btnUpdate.tag = indexPath.row
        
        cell.btnDelete.isHidden = isFromProfile
        cell.btnUpdate.isHidden = isFromProfile
        
        cell.btnUpdate.addTarget(self, action: #selector(self.btnUpdatePressed(_:)), for: .touchUpInside)
        cell.btnDelete.removeTarget(self, action: #selector(self.btnDeletePressed(_:)), for: .touchUpInside)
        cell.btnDelete.setImage(UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 21, weight: .regular)), for: .normal)
        cell.btnDelete.tintColor = ApplazAppearance.accent
        cell.btnDelete.accessibilityLabel = "More note options"
        cell.btnDelete.showsMenuAsPrimaryAction = true
        cell.btnDelete.menu = UIMenu(children: [UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self, weak cell] _ in
            guard let self, let cell, let current = self.tblViewNoteTitle.indexPath(for: cell) else { return }
            cell.btnDelete.tag = current.row
            self.btnDeletePressed(cell.btnDelete)
        }])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let vc = NoteDetailViewController()
        if (userId.isEmpty) {
            vc.userId = Auth.auth().currentUser?.uid
            if let user  = SocialUserModel.current {
                if let key = user.ref.key {
                    vc.userId = key
                }
            }
        } else {
            vc.userId = userId
        }
        
        let body = notesBody[indexPath.row]
        var detail = NoteList()
        detail.user_id = vc.userId
        detail.parentCategoryKey = noteDictionary["CategoryKey"] as? String
        detail.parentCategoryName = notebookDisplayTitle
        detail.noteKey = body.noteKey
        detail.noteTitleName = body.titleName
        detail.noteDescriptionText = body.descriptionText
        detail.comments = body.comments
        detail.likeCount = body.likeCount
        detail.isLiked = body.isLiked
        detail.nameUser = user?.name ?? SocialUserModel.current?.name
        vc.note = detail
        vc.noteKey = body.noteKey
        self.navigationController?.pushViewController(vc, animated: true)
//        let noteDescriptionVC = self.storyboard?.instantiateViewController(withIdentifier: "NoteDescriptionListVC") as! NoteDescriptionListVC
//        let noteBody = notesBody[indexPath.row]
//        let dictBodyNote = ["Title": noteBody.titleName!, "Description" : "Description:  \( noteBody.descriptionText!)"] as [String : Any]
//        noteDescriptionVC.dictSelectedNote = dictBodyNote
//
//        self.navigationController?.pushViewController(noteDescriptionVC, animated: true)
    }
    
    
    //MARK:- BUTTON'S ACTIONS
    
    @IBAction func btnBackPressed(_ sender: UIButton) {
        competionHandler?(notesBody)
        if isAddedFlow{
            for controller in self.navigationController!.viewControllers as Array {
                    if controller.isKind(of: NoteCategoryListVC.self) {
                        _ =  self.navigationController!.popToViewController(controller, animated: true)
                        break
                    }
                }

        }else{
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    
    
    //MARK:- DELETE NOTE'S CATEGORIES
    
    func deleteNote() {
        if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
            let note = notesBody[self.selectedIndexForDelete!]
            guard let categoryKey = noteDictionary["CategoryKey"] as? String, !categoryKey.isEmpty,
                  let noteKey = note.noteKey, !noteKey.isEmpty else { return }
            database.deleteFromDatabase(category: categoryKey, title: noteKey)
            
            // Toast(text: kNOTE_DELETED).show()
            
            DispatchQueue.main.async {
                // Have to add observer for main data (notes in Note category controller)
                self.getNotes()
                self.tblViewNoteTitle.reloadData()
            }
        } else {
            notesBody.remove(at: self.selectedIndexForDelete!)
            competionHandler?(notesBody)
        }
      
        navigationController?.popViewController(animated: true)
    }
    
    
    //MARK:- GET CATEGORY WISE ALL NOTES
    
    func getNotes() {
        if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
            DispatchQueue.main.async {
                self.lblNotesNotFound.isHidden = self.notesBody.count > 0 ? true : false
                self.tblViewNoteTitle.isHidden = self.notesBody.count > 0 ? false : true
                self.tblViewNoteTitle.reloadData()
            }
        }else {
            
            DispatchQueue.main.async {
                self.lblNotesNotFound.isHidden = self.notesBody.count > 0 ? true : false
                self.tblViewNoteTitle.isHidden = self.notesBody.count > 0 ? false : true
                self.tblViewNoteTitle.reloadData()
            }
        }
    }
    
    

    
    
    //MARK:- BUTTON'S ACTIONS
    // handle testing and general modes of app
    @objc func btnUpdatePressed(_ sender : UIButton) {
        
          let addNoteVC = self.storyboard?.instantiateViewController(withIdentifier: "AddNoteVC") as! AddNoteVC
          guard let notesBody = noteDictionary["NotesBody"] as? [NoteBody] else{return}
        if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
            addNoteVC.isUpdate = true
            
            let noteBody = notesBody[sender.tag]
            let categoryNoteName = noteDictionary["CategoryNoteName"] as! String
            let categoryKey = noteDictionary["CategoryKey"] as? String
            let dictionaryNoteData = ["Title name" : noteBody.titleName as Any, "Note name" : noteBody.descriptionText as Any, "Category Key" : categoryKey as Any, "Note Key" : noteBody.noteKey as Any,"NoteImage":notes] as [String : Any]
            
            addNoteVC.dictSelectedNote = dictionaryNoteData
            addNoteVC.selectedCategoryNote = categoryNoteName
           
            
        } else {
            
            if (notesBody.count > 0) {
                
                addNoteVC.isUpdate = true
                addNoteVC.savingCompletionHandler = { [weak self] in
                    self?.notesBody.remove(at: sender.tag)
                    self?.notesBody.append(contentsOf: $0)
                    DispatchQueue.main.async {
                        self?.tblViewNoteTitle.reloadData()
                    }
                }
                let noteBody = self.notesBody[sender.tag]
                let categoryNoteName = noteDictionary["CategoryNoteName"] as! String
                let categoryKey = noteDictionary["CategoryKey"] as? String
                let dictionaryNoteData = ["Title name" : noteBody.titleName as Any, "Note name" : noteBody.descriptionText as Any, "Category Key" : categoryKey as Any, "Note Key" : noteBody.noteKey as Any] as [String : Any]
                
                addNoteVC.dictSelectedNote = dictionaryNoteData
                addNoteVC.selectedCategoryNote = categoryNoteName
                
        }
        
      

        }
        
      
        self.navigationController?.pushViewController(addNoteVC, animated: true)
    }
  
    @objc func btnDeletePressed(_ sender : UIButton) {

        alertView(nil, kDELETE_NOTE, ["No", "Yes"]) { (index) in
            if index == 1 {
                self.selectedIndexForDelete = sender.tag
                self.deleteNote()
            }
        }
    }
    
    @IBAction func btnAddNotePressed(_ sender: UIButton) {
           let addNoteVC = self.storyboard?.instantiateViewController(withIdentifier: "AddNoteVC") as! AddNoteVC
        addNoteVC.isFromNoteVC = true
        let categoryNoteName = noteDictionary["CategoryNoteName"] as! String
    
        
        if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
            let categoryKey = noteDictionary["CategoryKey"] as! String
            addNoteVC.selectedCategoryNote = categoryNoteName
            addNoteVC.categoryKey = categoryKey
            addNoteVC.notesBody = notesBody
        } else {
            addNoteVC.selectedCategoryNote = categoryNoteName
            addNoteVC.notesBody = notesBody
            addNoteVC.savingCompletionHandler = { [weak self] in
                self?.notesBody.append(contentsOf: $0)
                DispatchQueue.main.async {
                    self?.tblViewNoteTitle.reloadData()
                }
            }
        }
     
       
        self.navigationController?.pushViewController(addNoteVC, animated: true)
    }
}
