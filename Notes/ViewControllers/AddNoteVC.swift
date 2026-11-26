//
//  AddNoteVC.swift
//  Notes
//
//  Created by Sevenstar Infotech on 07/02/18.
//  Copyright © 2018 Sevenstar Infotech. All rights reserved.
//

import UIKit
import RichEditorView
import AudioUnit
import Toast_Swift
import FirebaseAuth
import CryptoKit
import FirebaseStorage
import Photos
import GoogleMobileAds

enum Vibration : UInt {
    case weak = 1519
    case threeBooms = 1107
}

//class AddNoteVC: UIViewController {

//    
//    //MARK:- OBJECTS & OUTLETS
//    
//    @IBOutlet weak var categorySeparatorView: UIView!
//    @IBOutlet weak var noteTitleSeparatorView: UIView!
//    @IBOutlet weak var btnBack: UIButton!
//    @IBOutlet weak var lblNavigationBarTitle: UILabel!
//    @IBOutlet weak var btnAddCategory: UIButton!
//    @IBOutlet weak var txtSelectNoteCategory: CustomTextField!
//    @IBOutlet weak var txtNoteTitle: UITextField!
//    @IBOutlet weak var txtNoteDescription: UITextView!
//    @IBOutlet weak var btnSaveNote: UIButton!
//    @IBOutlet weak var navigationBarView1: UIView!
//    @IBOutlet weak var navigationBarView2: UIView!
//    
//    @IBOutlet weak var mainScrollView: UIScrollView!
//    
//    var isUpdate = false
//    var dictSelectedNote = [String : Any]()
//    var categoryPickerView = UIPickerView()
//    var arrNoteCategories = [Any]()
//    var selectedCategoryNote = ""
//    var selectedNoteCategoryID = ""
//    var isNoteCategoryTextField = false
//    var isFromNoteVC = false
//    var strSelectedCategoryID = ""
//    var strDescription = ""
//    var categoryKey = ""
//    var notesBody = [NoteBody]()
//    var imageUrl = ""
//    var notes = [Note](){
//        didSet{
//            
//            print("Update")
//        }
//    }
//    
//    var completionHandler:(([Note])->Void)?
//    var savingCompletionHandler:(([NoteBody])->Void)?
//    private var rewardedInterstitialAd: GADRewardedInterstitialAd?
//    
//    
//    var imageNumber : Int = 0
//    
//    
//    /// Firebase
//    private var database = DatabaseService()
//}

class AddNoteVC: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UINavigationControllerDelegate {
    private let backSwipeGuard = ApplazBackSwipeGuard()
    
    //MARK:- OBJECTS & OUTLETS
    
    @IBOutlet weak var categorySeparatorView: UIView!
    @IBOutlet weak var noteTitleSeparatorView: UIView!
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var lblNavigationBarTitle: UILabel!
    @IBOutlet weak var btnAddCategory: UIButton!
    @IBOutlet weak var txtSelectNoteCategory: CustomTextField!
    @IBOutlet weak var txtNoteTitle: UITextField!
    @IBOutlet weak var txtNoteDescription: UITextView!
    @IBOutlet weak var btnSaveNote: UIButton!
    @IBOutlet weak var editorView: RichEditorView!
    @IBOutlet weak var navigationBarView1: UIView!
    @IBOutlet weak var navigationBarView2: UIView!
    
    @IBOutlet weak var mainScrollView: UIScrollView!
    private var inlineAI: AIInlinePanelController?
    private var inlineAIHeight: NSLayoutConstraint?
    private let aiDraftScopeID = UUID().uuidString
    private let addChecklistButton = UIButton(type: .system)
    private let noteLayoutControl = UISegmentedControl(items: ["Text", "Checklist"])

    var isUpdate = false
    var dictSelectedNote = [String : Any]()
    var categoryPickerView = UIPickerView()
    var arrNoteCategories = [Any]()
    private var newNotebookIsPrivate = false
    private var draftTimer: Timer?
    private var draftURL: URL?
    private var lastDraftData: Data?
    private var didPrepareDraft = false
    private var didSubmitNote = false

    deinit {
        draftTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    // Local recovery only: unfinished public notes must never be published by a timer.
    private func prepareDraft() {
        guard !didPrepareDraft else { return }
        didPrepareDraft = true
        let account = UserDefaults.standard.bool(forKey: Guest_Key) ? "guest" : (Auth.auth().currentUser?.uid ?? "signed-out")
        let scope = "\(account)|\(isUpdate)|\(dictSelectedNote["Category Key"] ?? categoryKey)|\(dictSelectedNote["Note Key"] ?? selectedCategoryNote)"
        let filename = SHA256.hash(data: Data(scope.utf8)).map { String(format: "%02x", $0) }.joined()
        if let folder = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("NoteDrafts", isDirectory: true) {
            do {
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                var excludedFolder = folder
                var values = URLResourceValues()
                values.isExcludedFromBackup = true
                try excludedFolder.setResourceValues(values)
                draftURL = folder.appendingPathComponent(filename + ".json")
                if let data = try? Data(contentsOf: draftURL!), let draft = try? JSONDecoder().decode([String: String].self, from: data) {
                    txtNoteTitle.text = draft["title"]
                    txtSelectNoteCategory.text = draft["notebook"]
                    categoryKey = draft["categoryKey"] ?? categoryKey
                    newNotebookIsPrivate = draft["private"] == "true"
                    strDescription = draft["html"] ?? ""
                    editorView.html = strDescription
                    lastDraftData = data
                }
            } catch { print("Could not prepare note draft: \(error.localizedDescription)") }
        }
        draftTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in self?.autosaveDraft() }
        NotificationCenter.default.addObserver(self, selector: #selector(autosaveDraft), name: UIApplication.willResignActiveNotification, object: nil)
    }

    @objc private func autosaveDraft() {
        guard !didSubmitNote, let draftURL else { return }
        let draft = ["title": txtNoteTitle.text ?? "", "notebook": txtSelectNoteCategory.text ?? "", "categoryKey": categoryKey, "private": String(newNotebookIsPrivate), "html": strDescription]
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(draft), data != lastDraftData else { return }
        do {
            try data.write(to: draftURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            lastDraftData = data
        } catch { print("Could not autosave note draft: \(error.localizedDescription)") }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        autosaveDraft()
    }

    var selectedCategoryNote = ""
    var selectedNoteCategoryID = ""
    var isNoteCategoryTextField = false
    var isFromNoteVC = false
    var strSelectedCategoryID = ""
    var strDescription = ""
    var categoryKey = ""
    var notesBody = [NoteBody]()
    var camereBtn : RichEditorOptionItem!
    var imageUrl = ""
    var notes = [Note](){
        didSet{
            self.updatePickerView()
            print("Update")
        }
    }
    
    var completionHandler:(([Note])->Void)?
    var savingCompletionHandler:(([NoteBody])->Void)?
    private var rewardedInterstitialAd: GADRewardedInterstitialAd?
    lazy var toolbar: RichEditorToolbar = {
        let toolbar = RichEditorToolbar(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 44))
        //toolbar.options = RichEditorDefaultOption.all
        
        toolbar.options = [//RichEditorDefaultOption.clear,
            //RichEditorDefaultOption.undo,
            //RichEditorDefaultOption.redo,
            RichEditorDefaultOption.bold,
            RichEditorDefaultOption.italic,
            //RichEditorDefaultOption.subscript,
            //RichEditorDefaultOption.superscript,
            //RichEditorDefaultOption.strike,
            //RichEditorDefaultOption.underline,
            //RichEditorDefaultOption.textColor,
            //RichEditorDefaultOption.textBackgroundColor,
            //RichEditorDefaultOption.indent,
            //RichEditorDefaultOption.outdent,
            RichEditorDefaultOption.orderedList,
            RichEditorDefaultOption.unorderedList,
            //RichEditorDefaultOption.alignLeft,
            //RichEditorDefaultOption.alignCenter,
            //RichEditorDefaultOption.alignRight,
            //RichEditorDefaultOption.image
        ]
        return toolbar
    }()
    
    var imageNumber : Int = 0
    
    
    /// Firebase
    private var database = DatabaseService()
    
    //MARK:- VIEW LIFE CYCLE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        txtNoteTitle.accessibilityIdentifier = "NoteTitle"
        installInlineAIEditor()
        btnAddCategory.accessibilityIdentifier = "NameNewNotebook"
        txtSelectNoteCategory.accessibilityIdentifier = "NotebookCategory"
        self.categoryPickerView.delegate = self
        self.categoryPickerView.dataSource = self
        
        //self.categorySeparatorView.backgroundColor  = kBORDER_COLOR
//        self.txtNoteTitle.layer.borderWidth  = 1.0
//        self.txtNoteTitle.layer.borderColor  =  kBORDER_COLOR.cgColor
//        self.txtNoteTitle.layer.cornerRadius = 4.0
        
//        self.categorySeparatorView.layer.borderWidth  = 1.0
//        self.categorySeparatorView.layer.borderColor =  kBORDER_COLOR.cgColor
        
        self.categorySeparatorView.backgroundColor = UIColor.white.withAlphaComponent(0.35)
        self.categorySeparatorView.layer.cornerRadius = 14
        self.categorySeparatorView.layer.borderWidth = 1
        self.categorySeparatorView.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
        self.categorySeparatorView.clipsToBounds = true
        self.btnSaveNote.setImage(nil, for: .normal)
        var saveStyle = UIButton.Configuration.plain()
        saveStyle.image = UIImage(systemName: "square.and.arrow.down")
        saveStyle.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        saveStyle.baseForegroundColor = ApplazAppearance.ink
        saveStyle.background = .clear()
        saveStyle.contentInsets = .zero
        self.btnSaveNote.configuration = saveStyle
        self.btnSaveNote.tintColor = ApplazAppearance.accent
        self.btnSaveNote.accessibilityLabel = "Save Note"
        camereBtn = RichEditorOptionItem(image: UIImage(systemName: "camera"), title: "") { [weak self] toolbar in
            self?.openPhotos()
            return
        }
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(handleKeyboard(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(handleKeyboard(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(handleKeyboard(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        DispatchQueue.main.async { [self] in
            

            self.editorView.layer.cornerRadius = 16
            self.editorView.backgroundColor = ApplazAppearance.surface
            self.editorView.layer.borderWidth = 1
            self.editorView.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
            self.editorView.webView.isOpaque = false
            self.editorView.webView.backgroundColor = .clear
            self.editorView.clipsToBounds = true

            self.editorView.delegate = self
            self.editorView.inputAccessoryView = self.toolbar
            self.editorView.placeholder = "Journal Entry"
            self.editorView.setFontSize(Int((self.txtNoteTitle.font?.pointSize)!))
            
           self.toolbar.delegate = self
           self.toolbar.editor = self.editorView
            var options = self.toolbar.options
             options.append(camereBtn)
             options.append(RichEditorOptionItem(image: UIImage(systemName: "sparkles"), title: "Ask") { [weak self] _ in
                 guard let self else { return }
                 self.view.endEditing(true)
                 self.editorView.runJS("document.getElementById('editor').blur()")
                 if let panel = self.inlineAI { self.mainScrollView.scrollRectToVisible(panel.view.convert(panel.view.bounds, to: self.mainScrollView), animated: true) }
             })
            
            self.toolbar.options = options
            
           self.editorView.clipsToBounds = true
        }
        
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = BLUE_COLOR
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.donePicker(_:)))
        doneButton.setTitleTextAttributes([NSAttributedString.Key.font : UIFont(name: "HelveticaNeue-Medium", size: 17)!, NSAttributedString.Key.foregroundColor : BLUE_COLOR], for: .normal)
        
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.cancelPicker(_:)))
        cancelButton.setTitleTextAttributes([NSAttributedString.Key.font : UIFont(name: "HelveticaNeue-Medium", size: 17)!, NSAttributedString.Key.foregroundColor : BLUE_COLOR], for: .normal)
        
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        self.txtSelectNoteCategory.inputView = self.categoryPickerView
        self.txtSelectNoteCategory.inputAccessoryView = toolBar
    }
    private func installInlineAIEditor() {
        guard let container = editorView.superview else { return }
        txtNoteDescription.isHidden = true
        // Replace only the old editor/content height relationships, preserving the header and notebook fields.
        var node: UIView? = container
        while let current = node {
            for constraint in current.constraints {
                if (constraint.firstItem as AnyObject?) === editorView || (constraint.secondItem as AnyObject?) === editorView || (constraint.firstItem as AnyObject?) === txtNoteDescription || (constraint.secondItem as AnyObject?) === txtNoteDescription || ((constraint.firstItem as AnyObject?) === container && constraint.firstAttribute == .height) {
                    constraint.isActive = false
                }
            }
            if current === view { break }; node = current.superview
        }
        noteLayoutControl.selectedSegmentIndex = 0
        addChecklistButton.setTitle("+ Add item", for: .normal)
        addChecklistButton.titleLabel?.font = ApplazAppearance.font(13)
        addChecklistButton.tintColor = ApplazAppearance.accent
        addChecklistButton.isHidden = true
        addChecklistButton.addTarget(self, action: #selector(addChecklistRow), for: .touchUpInside)
        container.addSubview(addChecklistButton); addChecklistButton.translatesAutoresizingMaskIntoConstraints = false
        noteLayoutControl.addTarget(self, action: #selector(changeNoteLayout), for: .valueChanged)
        container.addSubview(noteLayoutControl); noteLayoutControl.translatesAutoresizingMaskIntoConstraints = false
        let panel = AIInlinePanelController(title: "Ask about this note", scope: { [weak self] in
            guard let self else { return .note("") }
            let key = self.dictSelectedNote["Note Key"] as? String ?? self.aiDraftScopeID
            return .note((self.txtNoteTitle.text ?? "") + "\n" + self.editorView.html, key: "regular-note:" + key)
        })
        inlineAI = panel; addChild(panel); container.addSubview(panel.view); panel.view.translatesAutoresizingMaskIntoConstraints = false; panel.didMove(toParent: self)
        let height = panel.view.heightAnchor.constraint(equalToConstant: 240); inlineAIHeight = height
        panel.heightChanged = { [weak self] value in self?.inlineAIHeight?.constant = value }
        NSLayoutConstraint.activate([
            addChecklistButton.leadingAnchor.constraint(equalTo: noteLayoutControl.trailingAnchor, constant: 8), addChecklistButton.centerYAnchor.constraint(equalTo: noteLayoutControl.centerYAnchor), addChecklistButton.heightAnchor.constraint(equalToConstant: 36),
            noteLayoutControl.topAnchor.constraint(equalTo: txtNoteTitle.bottomAnchor, constant: 12), noteLayoutControl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18), noteLayoutControl.widthAnchor.constraint(equalToConstant: 195), noteLayoutControl.heightAnchor.constraint(equalToConstant: 36),
            editorView.topAnchor.constraint(equalTo: noteLayoutControl.bottomAnchor, constant: 12), editorView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18), editorView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -18), editorView.heightAnchor.constraint(equalToConstant: 300),
            panel.view.topAnchor.constraint(equalTo: editorView.bottomAnchor, constant: 16), panel.view.leadingAnchor.constraint(equalTo: container.leadingAnchor), panel.view.trailingAnchor.constraint(equalTo: container.trailingAnchor), height, panel.view.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -18)
        ])
    }
    @objc private func changeNoteLayout() {
        let checklist = noteLayoutControl.selectedSegmentIndex == 1
        addChecklistButton.isHidden = !checklist
        let flag = checklist ? "true" : "false"
        editorView.runJS("""
        (function() {
            var active = \(flag), root = document.getElementById('editor');
            var list = root.querySelector('ul.applaz-checklist');
            if (active && !list) {
                list = document.createElement('ul'); list.className = 'applaz-checklist'; list.style.listStyle = 'none'; list.style.paddingLeft = '0';
                var row = document.createElement('li'); var check = document.createElement('input'); check.type = 'checkbox'; check.setAttribute('contenteditable', 'false');
                var label = document.createElement('span'); label.textContent = ' New item'; row.appendChild(check); row.appendChild(label); list.appendChild(row); root.appendChild(list);
            }
            if (list) { list.setAttribute('data-layout', active ? 'checklist' : 'text'); list.querySelectorAll('input[type=checkbox]').forEach(function(box) { box.style.display = active ? 'inline' : 'none'; }); }
            RE.callback('input');
        })();
        """)
    }

    @objc private func addChecklistRow() {
        editorView.runJS("""
        (function() {
            var list = document.getElementById('editor').querySelector('ul.applaz-checklist'); if (!list) return;
            var row = document.createElement('li'), check = document.createElement('input'), label = document.createElement('span');
            check.type = 'checkbox'; check.setAttribute('contenteditable', 'false'); label.textContent = ' New item'; row.appendChild(check); row.appendChild(label); list.appendChild(row);
            var range = document.createRange(); range.selectNodeContents(label); var selection = window.getSelection(); selection.removeAllRanges(); selection.addRange(range); label.parentNode.focus(); RE.callback('input');
        })();
        """)
    }

    @objc func handleKeyboard(notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        if notification.name == UIResponder.keyboardWillHideNotification {
            editorView.webView.scrollView.contentInset = .zero
            mainScrollView.contentInset.bottom = 0
            mainScrollView.verticalScrollIndicatorInsets.bottom = 0
            return
        }
        let keyboard = view.convert(frame, from: view.window)
        let overlap = max(0, view.bounds.maxY - keyboard.minY)
        mainScrollView.contentInset.bottom = overlap
        mainScrollView.verticalScrollIndicatorInsets.bottom = overlap
        func responder(_ root: UIView) -> UIView? {
            if root.isFirstResponder { return root }
            for child in root.subviews { if let found = responder(child) { return found } }
            return nil
        }
        if let focused = responder(view) {
            let target = focused.isDescendant(of: editorView) ? editorView! : focused
            mainScrollView.scrollRectToVisible(target.convert(target.bounds, to: mainScrollView).insetBy(dx: 0, dy: -12), animated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = true
        
        if !isFromNoteVC && self.notes.count > 0 && !(UserDefaults.standard.bool(forKey: Guest_Key)) && (txtSelectNoteCategory.text ?? "").isEmpty {
            
            self.txtSelectNoteCategory.text = self.notes[0].categoryName
            self.categoryKey = self.notes[0].categoryKey!
            
        } else if !isFromNoteVC && self.notes.count > 0 && (txtSelectNoteCategory.text ?? "").isEmpty {
            self.txtSelectNoteCategory.text = self.notes[0].categoryName
        }
        
        if self.isFromNoteVC {
            self.txtSelectNoteCategory.isUserInteractionEnabled = false
            self.btnAddCategory.isHidden = true
            self.txtSelectNoteCategory.text = selectedCategoryNote
        }
        
        if isUpdate && !didPrepareDraft {
            self.lblNavigationBarTitle.text = "Edit Note"
            self.txtSelectNoteCategory.text = selectedCategoryNote
            self.txtNoteTitle.text = self.dictSelectedNote["Title name"] as? String
            self.txtNoteDescription.attributedText = stringFromHtml(string: self.dictSelectedNote["Note name"] as! String)
            //self.editorView.contentHTML = self.dictSelectedNote["Note name"] as! String
            self.editorView.html = self.dictSelectedNote["Note name"] as! String
            self.btnAddCategory.isHidden = true
        }
        
        invalidateComponents()
        lblNavigationBarTitle.font = ApplazAppearance.headerFont
        prepareDraft()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        backSwipeGuard.install(on: navigationController)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    private func openPhotos() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            // User has authorized access to the photo library
            showImagePicker()
        case .notDetermined:
            // Request authorization
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        // Access granted
                        self.showImagePicker()
                    } else {
                        // Access denied
                        // Handle denial case
                    }
                }
            }
        case .denied, .restricted:
            showPermissionDeniedAlert()
            break
        @unknown default:
            break
        }
    }

    private func showImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }
    
    func showAd() {
      guard let rewardedInterstitialAd = rewardedInterstitialAd else {
          print("Ad wasn't ready.")
          DispatchQueue.main.async {
              let picker = UIImagePickerController()
              picker.delegate = self
              picker.allowsEditing = true
              self.present(picker, animated: true, completion: nil)
          }
          return
      }

      rewardedInterstitialAd.present(fromRootViewController: self) {
          return print("granted")
      }
    }
    
    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Permission Denied",
            message: "Please grant access to the photo library in Settings to use this feature.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .cancel) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        self.present(alert, animated: true, completion: nil)
    }
    func invalidateComponents() {
        
        let defaults = UserDefaults.standard
        
        let colorIndex = defaults.integer(forKey: MYTHEMECOLORINDEX)
        
        print("selected ColorIndex")
        print(colorIndex)
        
        //updateColor(view: navigationBarView1, index: colorIndex)
        
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
    }
    
    //MARK:_ UPDATE NOTES FOR PICKER VIEW
    private func updatePickerView() {
        DispatchQueue.main.async {
            self.categoryPickerView.reloadAllComponents()
        }
    }
    
    //MARK:- BUTTON'S ACTIONS
    
    @IBAction func btnBackPressed(_ sender: UIButton) {
       // self.navigationController?.popViewController(animated: true)
        
        if self.txtSelectNoteCategory.text!.count  == 0 && self.txtSelectNoteCategory.text!.count == 0{
            self.navigationController?.popViewController(animated: true)
        }else{
            self.saveNote()
        }
        
      
    }
    
    @objc func donePicker(_ sender : UIBarButtonItem) {
        
        let strSelectedvalue = self.categoryPickerView.selectedRow(inComponent: 0)
        
        self.txtSelectNoteCategory.text = self.notes[strSelectedvalue].categoryName!
        if  !(UserDefaults.standard.bool(forKey: Guest_Key)) {
            self.categoryKey = self.notes[strSelectedvalue].categoryKey!
        } else {print("TEST MODE")}
        
        self.view.endEditing(true)
    }
    
    @objc func cancelPicker(_ sender : UIBarButtonItem) {
        print("cancel")
        self.view.endEditing(true)
    }
    
    @IBAction func btnSaveNotePressed(_ sender: UIButton) {
        
        self.saveNote()
        /*
         if self.isEmpty(self.txtSelectNoteCategory.text!){
         self.txtSelectNoteCategory.shake()
         self.vibrate(with: .weak)
         self.showToast(string: "Please select notebook category", view: self.view)
         return
         }
         
         
         
         if self.isEmpty(self.editorView.text){
         self.editorView.shake()
         self.vibrate(with: .weak)
         self.showToast(string: "Please enter Journal entry", view: self.view)
         return
         }
         
         
         /* if self.txtSelectNoteCategory.text!.removeNull() == "" {
          // Toast(text: kSELECT_NOTE_CATEGORY).show()
          }
          else if self.txtNoteTitle.text!.removeNull() == "" {
          // Toast(text: kENTER_NOTE_TITLE).show()
          }
          else if self.strDescription.removeNull() == "" || self.strDescription.removeNull() == "<br>" {
          // Toast(text: kENTER_NOTE_DESCRIPTION).show()
          }
          else {*/
         var isSaved = false
         // this block responsible for update NOTES
         if isUpdate {
         
         let strNotTitle        = self.txtNoteTitle.text!.removeNull()
         let strNoteDescription = self.strDescription.removeNull() != "" ? self.strDescription.removeNull() : ""
         
         if !(strNotTitle.isEmpty && strNoteDescription.isEmpty) {
         self.editNote()
         
         isSaved = true
         
         } else{
         isUpdate = false
         }
         
         } else if isFromNoteVC {
         self.addNoteBody()
         isSaved = true
         
         } else {
         if (categoryKey.isEmpty) {
         self.addNote()
         isSaved = true
         } else {
         self.addNoteBody()
         isSaved = true
         }
         }
         
         if isSaved {
         // self.toolbar.options = []
         completionHandler?(notes)
         savingCompletionHandler?(notesBody)
         //FIXME:- FIX THIS AND ADD ANOTHER LOGIC
         guard let  controllers = self.navigationController?.viewControllers else {return}
         for vc in controllers {
         if vc is NoteCategoryListVC {
         if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
         self.displayAlert(title: "Save", messageText: "Successfully saved", delegate: self)
         // self.navigationController?.popToViewController(vc as! NoteCategoryListVC, animated: true)
         } else {
         self.displayAlert(title: "Save", messageText: "Successfully saved", delegate: self)
         
         //  self.navigationController?.popViewController(animated: true)
         }
         
         }
         }
         }
         let strMSG = isUpdate ? "\(isSaved ? kNOTE_UPDATED : kNOTE_NOT_UPDATED)" : "\(isSaved ? kNOTE_ADDED : kNOTE_NOT_ADDED)"
         // Toast(text: strMSG).show()
         /*}*/*/
    }
    
    @IBAction func btnAddCategoryPressed(_ sender: UIButton) {
        self.addCategory()
    }
    
    //MARK:- ADD NOTE
    
    private func addNote() {
        if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
            database.writeDataToDatabase(category: self.txtSelectNoteCategory.text!.removeNull(), title: self.txtNoteTitle.text!.removeNull(), note: self.strDescription.removeNull(), isPrivateNote: newNotebookIsPrivate)
            
        } else {
            
            let note = DefaultSavingLogicNote.shared.savingNote(categoryName: self.txtSelectNoteCategory.text!.removeNull(), titleName: self.txtNoteTitle.text!.removeNull(), descriptionText: self.strDescription.removeNull(), isPrivateNote: newNotebookIsPrivate)
            notes.append(note)
            completionHandler?(notes)
        }
        
    }
    
    
    func saveNote(){
        if self.isEmpty(self.txtSelectNoteCategory.text!){
            self.txtSelectNoteCategory.shake()
            self.vibrate(with: .weak)
            self.showToast(string: "Please select notebook category", view: self.view)
            return
        }
        
        
        
        
        /* if self.txtSelectNoteCategory.text!.removeNull() == "" {
         // Toast(text: kSELECT_NOTE_CATEGORY).show()
         }
         else if self.txtNoteTitle.text!.removeNull() == "" {
         // Toast(text: kENTER_NOTE_TITLE).show()
         }
         else if self.strDescription.removeNull() == "" || self.strDescription.removeNull() == "<br>" {
         // Toast(text: kENTER_NOTE_DESCRIPTION).show()
         }
         else {*/
        var isSaved = false
        // this block responsible for update NOTES
        if isUpdate {
            
            let strNotTitle = self.txtNoteTitle.text!.removeNull()
            let strNoteDescription = self.strDescription.removeNull() != "" ? self.strDescription.removeNull() : ""
            
            if !(strNotTitle.isEmpty && strNoteDescription.isEmpty) {
                self.editNote()
                
                isSaved = true
                
            } else{
                isUpdate = false
            }
            
        } else if isFromNoteVC {
            self.addNoteBody()
            isSaved = true
            
        } else {
            if (categoryKey.isEmpty) {
                self.addNote()
                isSaved = true
            } else {
                self.addNoteBody()
                isSaved = true
            }
        }
        
        if isSaved {
            didSubmitNote = true
            draftTimer?.invalidate()
            if let draftURL { try? FileManager.default.removeItem(at: draftURL) }

            // self.toolbar.options = []
            completionHandler?(notes)
            savingCompletionHandler?(notesBody)
            //FIXME:- FIX THIS AND ADD ANOTHER LOGIC
            guard let  controllers = self.navigationController?.viewControllers else {return}
            for vc in controllers {
                if vc is NoteCategoryListVC {
                    if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
                        self.displayAlert(title: "Save", messageText: "Successfully saved", delegate: self)
                        // self.navigationController?.popToViewController(vc as! NoteCategoryListVC, animated: true)
                    } else {
                        self.displayAlert(title: "Save", messageText: "Successfully saved", delegate: self)
                        
                        //  self.navigationController?.popViewController(animated: true)
                    }
                    
                }
            }
        }
        let strMSG = isUpdate ? "\(isSaved ? kNOTE_UPDATED : kNOTE_NOT_UPDATED)" : "\(isSaved ? kNOTE_ADDED : kNOTE_NOT_ADDED)"
    }
    
    //MARK:- UIPICKER VIEW DELEGATE & DATA SOURCE METHODS
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.notes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return  self.notes[row].categoryName
    }
    
    
    //MARK:- GET NOTE'S ALL CATEGORIES
    
    func getNotesAllCategories() -> [Any]  {
        var categoryArray = [Any]()
        notes.forEach{ [weak self] in
            
            categoryArray.append($0.categoryName ?? "")
        }
        
        return categoryArray
    }
    
    
    //MARK:- UITEXTFIELD DELEGATE METHODS
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        self.isNoteCategoryTextField = false
        
        if self.txtSelectNoteCategory == textField {
            self.isNoteCategoryTextField = true
            
            if self.notes.count == 0 {
                self.txtSelectNoteCategory.resignFirstResponder()
                // Toast(text: kCATEGORY_NOT_AVALALBE).show()
                
                //  self.addCategory()
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField.tag  == 999 {
            textField.text?.capitalizeFirstLetter()
        }
        return true
    }
    
    
    // MARK:- ADD NOTEBODY
    
    private func addNoteBody() {
        if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
            let categoryKey = self.categoryKey
            
            _ = self.txtNoteTitle.text?.removeNull()
            let note = self.strDescription
            
            
           // print("Text from txtNoteDescription: \(self.editorView.text.removeNull())")
            var noteTitle = ""
            if self.isEmpty(self.txtNoteTitle.text){
                noteTitle = "Untitled Note"
            }else{
                noteTitle = self.txtNoteTitle.text ?? "Untitled Note".removeNull()
            }
            self.database.writeNoteTitle(categoryKey: categoryKey, titleNote: noteTitle, noteDescription: note)
            let noteBodyL = DefaultSavingLogicNote.shared.savingNoteBody(titleName: noteTitle, descriptionText: note)
            self.notesBody.removeAll()
            self.notesBody.append(noteBodyL)
            
        }else{
            
            var noteTitle = ""
            if self.isEmpty(self.txtNoteTitle.text){
                noteTitle = "Untitled Note"
            }else{
                noteTitle = self.txtNoteTitle.text ?? "Untitled Note".removeNull()
            }
            
            let titleNote = noteTitle
            let note = self.strDescription
            let noteEntity = DefaultSavingLogicNote.shared.savingNote(categoryName: "empty", titleName: titleNote, descriptionText: note)
            self.notesBody.removeAll()
            self.notesBody.append(contentsOf: noteEntity.noteBody!)
            
        }
    }
    
    // MARK:- EDIT NOTE
    
    private func editNote() {
        if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
            let categoryKey = self.dictSelectedNote["Category Key"] as! String
            let titleKey = self.dictSelectedNote["Note Key"] as! String
            
            let titleNote = self.txtNoteTitle.text?.removeNull()
            let note = self.strDescription
            
            self.database.editDatabaseRecords(categoryNote: nil, titleNote: titleNote, categoryKey: categoryKey, titleKey: titleKey, note: note, isPrivateNote: nil, completionHandler: { (err) in
                if let error = err {
                    print("Error editDatabaseRecord: \(error.localizedDescription)")
                }
            })
            
        } else {
            let note = DefaultSavingLogicNote.shared.savingNote(categoryName: self.txtSelectNoteCategory.text!.removeNull(), titleName: self.txtNoteTitle.text!.removeNull(), descriptionText: self.strDescription.removeNull())
            self.notes.removeAll()
            self.notesBody.append(contentsOf: note.noteBody!)
            
        }
        
    }
    
    //MARK:- ADD CATEGORY
    
    private func addCategory() {
        view.endEditing(true)
        let dialog = NewNotebookViewController()
        dialog.modalPresentationStyle = .pageSheet
        dialog.onCreate = { [weak self] name, isPrivate in
            guard let self else { return }
            self.txtSelectNoteCategory.text = name
            self.categoryKey = ""
            self.newNotebookIsPrivate = isPrivate
            self.arrNoteCategories = self.getNotesAllCategories()
        }
        present(dialog, animated: true)
    }

}


extension AddNoteVC: RichEditorDelegate {
    func richEditorDidLoad(_ editor: RichEditorView) {
        // A stylesheet in the document head changes only presentation, not the
        // editor HTML payload returned for saving existing or new note content.
        let styling = """
        (function() {
            var style = document.getElementById('applaz-editor-appearance');
            if (!style) {
                style = document.createElement('style');
                style.id = 'applaz-editor-appearance';
                document.head.appendChild(style);
            }
            style.textContent = 'html, body { background: transparent; } #editor { box-sizing: border-box; position: relative; padding: 16px; line-height: 1.5; } #editor.placeholder[placeholder]:after { top: 16px; left: 16px; right: 16px; }';
        })();
        """
        editor.webView.evaluateJavaScript(styling, completionHandler: nil)
        editor.runJS("""
        (function() {
            var root = document.getElementById('editor');
            if (!root.dataset.applazCheckboxHandler) {
                root.dataset.applazCheckboxHandler = '1';
                root.addEventListener('change', function(event) {
                    if (event.target.type === 'checkbox') {
                        if (event.target.checked) event.target.setAttribute('checked', 'checked'); else event.target.removeAttribute('checked');
                        RE.callback('input');
                    }
                });
            }
        })();
        """)
        noteLayoutControl.selectedSegmentIndex = editor.html.contains("data-layout=\"checklist\"") ? 1 : 0
        addChecklistButton.isHidden = noteLayoutControl.selectedSegmentIndex != 1
    }
    
    func richEditor(_ editor: RichEditorView, contentDidChange content: String) {
        self.strDescription = content.removeNull()
    }
    func richEditorTookFocus(_ editor: RichEditorView) {
        let a =  editor.webView.scrollView.frame.origin.y
        print("scroll y: \(a)")
    }
    func richEditor(_ editor: RichEditorView, heightDidChange height: Int) {
        print("height is: \(height)")
        //  self.scrollView.contentOffset.y = CGFloat(height)
    }
}

extension AddNoteVC: RichEditorToolbarDelegate {
    
    fileprivate func randomColor() -> UIColor {
        let colors: [UIColor] = [.red, .orange, .yellow, .green, .blue, .purple ]
        let color = colors[Int(arc4random_uniform(UInt32(colors.count)))]
        
        return color
    }
    
    func richEditorToolbarChangeTextColor(_ toolbar: RichEditorToolbar) {
        toolbar.editor?.setTextColor(.red)
    }
    
    func richEditorToolbarChangeBackgroundColor(_ toolbar: RichEditorToolbar) {
        toolbar.editor?.setTextBackgroundColor(.blue)
    }
    
    //MARK: VIBRATION
    func vibrate(with vibration : Vibration) {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    //MARK: ALERT
    func displayAlert(title titleTxt:String, messageText msg:String, delegate controller:UIViewController) ->(){
        let alertController = UIAlertController(title: titleTxt, message: msg, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default,handler: { alert in
            let noteTitleListVC = self.storyboard?.instantiateViewController(withIdentifier: "NoteTitleListVC") as! NoteTitleListVC
            noteTitleListVC.categoryTitle = self.txtSelectNoteCategory.text ?? "Notebook"
            if UserDefaults.standard.bool(forKey: Guest_Key) {
                let notebook = self.notes.first { $0.categoryName == self.txtSelectNoteCategory.text }
                let bodies = self.isUpdate ? self.notesBody : (self.isFromNoteVC || !self.categoryKey.isEmpty ? (notebook?.noteBody ?? []) + self.notesBody : notebook?.noteBody ?? self.notesBody)
                noteTitleListVC.notesBody = bodies
                noteTitleListVC.noteDictionary = ["NotesBody": bodies, "CategoryNoteName": noteTitleListVC.categoryTitle]
            } else {
                noteTitleListVC.isAddedFlow = true
                if !self.categoryKey.isEmpty { noteTitleListVC.noteDictionary["CategoryKey"] = self.categoryKey }
            }
            self.navigationController?.pushViewController(noteTitleListVC, animated: true)
        }))
        controller.present(alertController, animated: true, completion: nil)
    }
    //MARK: - Validation Empty
    func isEmpty(_ thing : String? )->Bool {
        
        if (thing?.count == 0) {
            return true
        }
        return false;
    }
    //MARK: - Toast
    func showToast(string:String,view:UIView) {
        view.makeToast(string, duration: 1.0, position: .top)
    }
}

//MARK: SHAKE
extension UIView{
    func shake(){
        
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 4
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - 10, y: self.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + 10, y: self.center.y))
        self.layer.add(animation, forKey: "position")
    }
    
}
extension AddNoteVC:UIImagePickerControllerDelegate{
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage else {
            picker.dismiss(animated: true)
            return
        }
        picker.dismiss(animated: true) { self.upload(photo: image) { _ in } }
    }

    func upload(photo: UIImage, with complete: @escaping (Bool) -> Void) {
        let uploadAccount = Auth.auth().currentUser?.uid
        let indicator = Indicator()
        indicator.showProgressView(view)
        func finish(_ error: Error?) {
            indicator.hideProgressView()
            if let error {
                let alert = UIAlertController(title: "Image wasn't saved", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
            complete(error == nil)
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let data = ApplazImagePayload.jpeg(from: photo)
            DispatchQueue.main.async {
                guard let data else {
                    finish(NSError(domain: "ApplazImage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Couldn't prepare this image under 20 KB."]))
                    return
                }
                guard let uploadAccount, Auth.auth().currentUser?.uid == uploadAccount else {
                    finish(NSError(domain: "ApplazImage", code: 2, userInfo: [NSLocalizedDescriptionKey: "Sign in to upload an image."]))
                    return
                }
                ApplazImageUploader.upload(data, path: "\(Date().timeIntervalSince1970).jpg") { result in
                    switch result {
                    case .failure(let error): finish(error)
                    case .success(let url):
                        guard Auth.auth().currentUser?.uid == uploadAccount else {
                            finish(NSError(domain: "ApplazImage", code: 2, userInfo: [NSLocalizedDescriptionKey: "Your sign-in changed. Reopen the note before uploading an image."]))
                            return
                        }
                        self.editorView.insertImage(url.absoluteString, alt: "Image")
                        self.imageUrl = url.absoluteString
                        self.editorView.webView.evaluateJavaScript("RE.getHtml()") { value, _ in
                            if let html = value as? String { self.strDescription = html }
                            self.autosaveDraft()
                            finish(nil)
                        }
                    }
                }
            }
        }
    }

}
extension AddNoteVC: GADFullScreenContentDelegate {

  /// Tells the delegate that the ad failed to present full screen content.
  func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
    print("Ad did fail to present full screen content.")
  }

  /// Tells the delegate that the ad will present full screen content.
  func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
    print("Ad will present full screen content.")
  }

  /// Tells the delegate that the ad dismissed full screen content.
  func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
    print("Ad did dismiss full screen content.")
      DispatchQueue.main.async {
          let picker = UIImagePickerController()
          picker.delegate = self
          picker.allowsEditing = true
          self.present(picker, animated: true, completion: nil)
      }
  }
}
