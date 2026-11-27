//
//  NoteCategoryListVC.swift
//  Notes
//
//  Created by Sevenstar Infotech on 07/02/18.
//  Copyright © 2018 Sevenstar Infotech. All rights reserved.
//

import UIKit
import Combine
//import Toaster
import Firebase
import GoogleMobileAds

class NoteCategoryListVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITabBarDelegate {
    private var standaloneTabBar: UITabBar?
    private var aiPanel: AIInlinePanelController?
    private var collaborationSubscription: AnyCancellable?
    
    var sharedObj: Shared?
    let iapObj = IAPHelper()
    
    //MARK:- OBJECTS & OUTLETS
    
    @IBOutlet weak var btnSetting: UIButton!
    @IBOutlet weak var lblNavigationBarTitle: UILabel!
    @IBOutlet weak var btnAdd: UIButton!
    @IBOutlet weak var tblViewNoteCateoryTitle: UITableView!
    @IBOutlet weak var lblNotesCategoryNotFound: UILabel!
    @IBOutlet weak var navigationBarView1: UIView!
    @IBOutlet weak var navigationBarView2: UIView!
    @IBOutlet weak var temporaryBanner: UIView!
    @IBOutlet weak var textBodyLabel: UILabel!
    
   // @IBOutlet weak var viewBanner: ISBannerView!
    //var viewBanner: ISBannerView?
    var bannerView: GADBannerView!
    
    static var parentViewController: UIViewController!
    
    var arrNotesAllCateogries = [Any]()
    var selectedIndexForDelete : Int?
    var isConformPasscode = false
    var strPasscode = ""
    var notes = [Note]()
    
    //Database
    private var database = DatabaseService()
    
    //MARK:- VIEW LIFE CYCLE
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        lblNavigationBarTitle.font = ApplazAppearance.headerFont
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard tabBarController == nil, standaloneTabBar == nil else { return }
        let bar = UITabBar()
        bar.delegate = self
        bar.items = (0..<5).map { UITabBarItem(title: nil, image: nil, tag: $0) }
        DashboardController.styleTabBar(bar)
        bar.selectedItem = bar.items?[2]
        bar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bar)
        let bottom = max(view.safeAreaInsets.bottom, view.window?.safeAreaInsets.bottom ?? 0)
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bar.heightAnchor.constraint(equalToConstant: 49 + bottom)
        ])
        standaloneTabBar = bar
        tblViewNoteCateoryTitle.contentInset.bottom = max(tblViewNoteCateoryTitle.contentInset.bottom, 49 + bottom)
        tblViewNoteCateoryTitle.verticalScrollIndicatorInsets.bottom = 49 + bottom
    }

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        openSocialTab(item.tag)
    }

    func openSocialTab(_ index: Int) {
        guard (0...4).contains(index), index != 2 else { return }
        standaloneTabBar?.selectedItem = standaloneTabBar?.items?[2]
        guard Auth.auth().currentUser != nil else { btn_SocialAppPressed(self); return }
        let dashboard = UIStoryboard(name: "SocialMain", bundle: nil).instantiateViewController(withIdentifier: "DashboardController") as! DashboardController
        dashboard.loadViewIfNeeded(); dashboard.setupCenterButton(); dashboard.selectedIndex = index
        navigationController?.pushViewController(dashboard, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        installPrivateNotebooks()
        collaborationSubscription = CollaborationStore.shared.$notebooks.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.refreshPrivateNotebooks(); self?.tblViewNoteCateoryTitle.reloadData() }
        Task { await CollaborationStore.shared.refresh() }
        aiPanel = AIInlinePanelController.footer(in: self, table: tblViewNoteCateoryTitle, title: "Ask my notebooks", scope: { .all })
        func matchSocialIcon(in view: UIView) {
            for child in view.subviews {
                if let button = child as? UIButton,
                   button.actions(forTarget: self, forControlEvent: .touchUpInside)?.contains("btn_SocialAppPressed:") == true {
                    button.configuration = nil
                    button.setImage(ApplazAppearance.socialIcon, for: .normal)
                    button.imageView?.contentMode = .scaleAspectFit
                    button.clipsToBounds = false
                    button.tintColor = ApplazAppearance.accent
                    button.accessibilityLabel = "Newsfeed"
                }
                matchSocialIcon(in: child)
            }
        }
        matchSocialIcon(in: view)
        btnAdd.accessibilityIdentifier = "NotebookActions"
        btnAdd.accessibilityLabel = "Create notebook or add note"
        btnAdd.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 21, weight: .regular)), for: .normal)
        btnAdd.tintColor = ApplazAppearance.accent
        prepareUILabel()
        temporaryBanner.backgroundColor = .clear
        temporaryBanner.layer.borderWidth = 0
        tblViewNoteCateoryTitle.rowHeight = UITableView.automaticDimension
        tblViewNoteCateoryTitle.estimatedRowHeight = 85
        sharedObj = Shared.sharedInstance
        
        bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = "ca-app-pub-7924860604327441/1147720780"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        bannerView.delegate = self
        
        /*
        if sharedObj!.isProductPurchased == false {
            //ISIntegrationHelper.validateIntegration()
            //IronSource.setBannerDelegate(self)
            //IronSource.initWithAppKey("9389b715", adUnits: [IS_BANNER])
            
            // In this case, we instantiate the banner with desired ad size.
            
            bannerView = GADBannerView(adSize: kGADAdSizeBanner)
            bannerView.adUnitID = "ca-app-pub-7924860604327441/1147720780"
            bannerView.rootViewController = self
            bannerView.load(GADRequest())
            bannerView.delegate = self
            addBannerViewToView(bannerView)
        }
        */
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapText(gesture:)))
       textBodyLabel.addGestureRecognizer(tap)
        UIApplication.shared.statusBarStyle = .darkContent
        self.lblNavigationBarTitle.text = "Notebooks"
        self.lblNotesCategoryNotFound.text = kNO_CATEGORY_FOUND
        self.tblViewNoteCateoryTitle.rowHeight = UITableView.automaticDimension
        
        if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
             self.getNotesAllCategories()
        } else {
            self.temporaryBanner.isHidden = true
        }
        

        if UserDefaults.standard.integer(forKey: MYTHEMECOLORINDEX) == 0{
            UserDefaults.standard.set(5, forKey: MYTHEMECOLORINDEX)
        }
        
        //hier i will show welcome pop-up if first time on main screen after registration
       
        let isWelcomePopupshow = UserDefaults.standard.object(forKey: "isNeedToShowWelcomePopUp") as? Bool ?? false
        
        if !isWelcomePopupshow {
            UserDefaults.standard.set(true, forKey: "isNeedToShowWelcomePopUp")
            performSegue(withIdentifier: "showWelcomePopUp", sender: self)
        }
        
        /*
        if UserDefaults.standard.bool(forKey: "isNeedToShowWelcomePopUp") {
            UserDefaults.standard.removeObject(forKey: "isNeedToShowWelcomePopUp")
            performSegue(withIdentifier: "showWelcomePopUp", sender: self)
        }
        */
        
        NoteCategoryListVC.parentViewController = self
        
    }
   
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // iapObj.verifyReceipt()>>>>>>
        
        self.updateTableView()
        self.navigationController?.navigationBar.isHidden = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(displayAdmob(notfication:)), name: .verifiySubscription, object: nil)
        
       /*
        if sharedObj!.isProductPurchased == false {
           // loadBanner()
            bannerView.load(GADRequest())
        }
       */
         invalidateComponents()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func displayAdmob(notfication: NSNotification) {
        
        if sharedObj!.isProductPurchased == false {
            //ISIntegrationHelper.validateIntegration()
            //IronSource.setBannerDelegate(self)
            //IronSource.initWithAppKey("9389b715", adUnits: [IS_BANNER])
            
            // In this case, we instantiate the banner with desired ad size.
            /*
            bannerView = GADBannerView(adSize: kGADAdSizeBanner)
            bannerView.adUnitID = "ca-app-pub-7924860604327441/1147720780"
            bannerView.rootViewController = self
            bannerView.load(GADRequest())
            bannerView.delegate = self
            */
            addBannerViewToView(bannerView)
            bannerView.load(GADRequest())
            
        } else {
            if bannerView != nil {
                removeBannerView(bannerView)
            }
        }
    }
    
   /*
    func loadBanner() {
        
        if (viewBanner != nil) {
           // destroyBanner()
            
        }
        
        // You can pick any banner size : IS_AD_SIZE_BANNER, IS_AD_SIZE_LARGE_BANNER, IS_AD_SIZE_RECTANGLE_BANNER
        //IronSource.loadBanner(with: self, size: .init())
        IronSource.loadBanner(with: self, size: .init(width: 320, andHeight: 50))
    }
    
    func destroyBanner() {
        
        if (self.viewBanner != nil) {
            IronSource.destroyBanner(self.viewBanner!)
            self.viewBanner = nil
        }
    }
    */
    
    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints(
            [NSLayoutConstraint(item: bannerView,
                                attribute: .bottom,
                                relatedBy: .equal,
                                toItem: bottomLayoutGuide,
                                attribute: .top,
                                multiplier: 1,
                                constant: 0),
             NSLayoutConstraint(item: bannerView,
                                attribute: .centerX,
                                relatedBy: .equal,
                                toItem: view,
                                attribute: .centerX,
                                multiplier: 1,
                                constant: 0)
            ])
    }
    
    func removeBannerView(_ bannerView: GADBannerView) {
     
        bannerView.removeFromSuperview()
    }
    
    //MARK:- UITABLE VIEW DELEGATE & DATA SOURCE METHODS
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if notes.isEmpty { return CGFloat.leastNormalMagnitude }
        return IS_IPAD ? 35.0 : 15.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
       
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.tblViewNoteCateoryTitle.frame.size.width, height: IS_IPAD ? 35.0 : 15.0))
        headerView.backgroundColor = .clear
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if notes.isEmpty { return CGFloat.leastNormalMagnitude }
        return IS_IPAD ? 35.0 : 15.0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: IS_IPAD ? 35.0 : 15.0))
        footerView.backgroundColor = .clear
        return footerView
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // 74.0 : 54.0
        return IS_IPAD ? 320 : 85
        //return IS_IPAD ? 280 : 250.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = self.tblViewNoteCateoryTitle.dequeueReusableCell(withIdentifier: "NoteCategoryTBLViewCell") as! NoteCategoryTBLViewCell
        
        let note = self.notes[indexPath.row]
        cell.lblNoteCategoryTitle.text = note.categoryName
        
        cell.btnDelete.tag = indexPath.row
        cell.btnUpdate.tag = indexPath.row
        cell.btnShare.tag = indexPath.row
        
        cell.btnDelete.removeTarget(self, action: #selector(self.btnDeletePressed(_:)), for: .touchUpInside)
        cell.btnUpdate.removeTarget(self, action: #selector(self.btnUpdatePressed(_:)), for: .touchUpInside)
        cell.btnUpdate.setImage(CollaborationStore.shared.image(kind: "legacy", sourceID: note.categoryKey ?? ""), for: .normal)
        cell.btnUpdate.tintColor = ApplazAppearance.accent
        cell.btnUpdate.accessibilityLabel = !CollaborationStore.shared.hasEditors(kind: "legacy", sourceID: note.categoryKey ?? "") ? "Invite friends to notebook" : "Friends in this notebook"
        cell.btnUpdate.removeAction(identifiedBy: UIAction.Identifier("InviteNotebookFriends"), for: .touchUpInside)
        cell.btnUpdate.addAction(UIAction(identifier: UIAction.Identifier("InviteNotebookFriends")) { [weak self, weak cell] _ in
            guard let self, let cell, let row = self.tblViewNoteCateoryTitle.indexPath(for: cell)?.row, let id = self.notes[row].categoryKey else { return }
            CollaborationPresentation.invite(kind: "legacy", sourceID: id, from: self)
        }, for: .touchUpInside)
        cell.btnShare.removeTarget(self, action: #selector(self.btnSharedPressed(_:)), for: .touchUpInside)
        cell.btnShare.addTarget(self, action: #selector(self.btnSharedPressed(_:)), for: .touchUpInside)
        cell.btnShare.accessibilityLabel = (note.isPrivateNote == true ? "Private notebook. Make public" : "Public notebook. Make private")
        
        let moreIcon = UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
        cell.btnDelete.setImage(moreIcon, for: .normal)
        cell.btnDelete.tintColor = ApplazAppearance.accent
        cell.btnDelete.accessibilityLabel = "More notebook options"
        cell.btnDelete.showsMenuAsPrimaryAction = true
        cell.btnDelete.menu = UIMenu(children: [
            UIAction(title: "Rename", image: UIImage(systemName: "pencil")) { [weak self, weak cell] _ in
                guard let self, let cell, let row = self.tblViewNoteCateoryTitle.indexPath(for: cell)?.row else { return }
                cell.btnUpdate.tag = row; self.btnUpdatePressed(cell.btnUpdate)
            },
            UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self, weak cell] _ in
                guard let self, let cell,
                      let currentIndexPath = self.tblViewNoteCateoryTitle.indexPath(for: cell) else { return }
                cell.btnDelete.tag = currentIndexPath.row
                self.btnDeletePressed(cell.btnDelete)
            }
        ])
        //cell.contentView.backgroundColor = .clear
        
        if self.notes[indexPath.row].isPrivateNote ?? false {
           // cell.btnShare.setTitle("Private", for: .normal)
            let lockIcon = UIImage(systemName: "lock", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular))?.withRenderingMode(.alwaysTemplate)
            cell.btnShare.setImage(lockIcon, for: .normal)
            cell.btnShare.tintColor = ApplazAppearance.accent
        } else {
            //cell.btnShare.setTitle("Shared", for: .normal)
            let globeIcon = UIImage(systemName: "globe.americas", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular))?.withRenderingMode(.alwaysTemplate)
            cell.btnShare.setImage(globeIcon, for: .normal)
            cell.btnShare.tintColor = ApplazAppearance.accent
        }
        cell.backGroundView.layer.cornerRadius = 12
        cell.backGroundView.clipsToBounds = true
       // self.updateTableViewColor(cell: cell)
       // self.updateTableViewFont(cell: cell)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let key = notes[indexPath.row].categoryKey, let shared = CollaborationStore.shared.match(kind: "legacy", sourceID: key) {
            CollaborationPresentation.open(shared.id, from: self); return
        }
 
        
        let noteTitleListVC = self.storyboard?.instantiateViewController(withIdentifier: "NoteTitleListVC") as! NoteTitleListVC
         var userNotes = notes[indexPath.row]
        
        if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
             guard let noteBody = userNotes.noteBody else{return}
              noteTitleListVC.noteDictionary = ["NotesBody" : noteBody, "CategoryKey" : userNotes.categoryKey!, "CategoryNoteName" : userNotes.categoryName! ]
        } else {
            guard let noteBody = userNotes.noteBody else{return}
            noteTitleListVC.noteDictionary = ["NotesBody" : noteBody, "CategoryNoteName" : userNotes.categoryName!]
            noteTitleListVC.competionHandler = {[weak self] in
                self?.notes.remove(at: indexPath.row)
                userNotes.noteBody?.removeAll()
                userNotes.noteBody?.append(contentsOf: $0)
                self?.notes.append(userNotes)
                self?.updateTableView()
            }
        }
        self.navigationController?.pushViewController(noteTitleListVC, animated: true)
    }
    
    //MARK:- ANIMATING TABLE_VIEW_CELL
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.alpha =  0.3
        UIView.animate(withDuration: 1.0) {
            cell.alpha = 1.0
        }
    }
    //MARK:- GET CATEGORY NAME AND KEY
    
    func getNotedCategoryData() -> [String:Any] {
        
        var dictionary = [String:Any]()
        
        notes.forEach{
            
            dictionary[$0.categoryName! ] = $0.categoryKey as Any
        }
        return dictionary
    }
    
    
    //MARK:- GET NOTE'S ALL CATEGORIES
    
    func getNotesAllCategories() {

        database.getData { (arrayOfNotes) in
            DispatchQueue.main.async {
                self.notes = arrayOfNotes.filter { !($0.categoryKey?.hasPrefix("wellness-") ?? false) }
                self.updateTableView()
            }
        }
    }
    
    func updateTableView() {
            self.lblNotesCategoryNotFound.isHidden = true
            self.tblViewNoteCateoryTitle.isHidden = false
            self.tblViewNoteCateoryTitle.reloadData()
    }
    
    //MARK:- DELETE NOTE'S CATEGORIES
    
    func deleteNotesCategories() {
        if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
            let note = notes[self.selectedIndexForDelete!]
            database.deleteFromDatabase(category: note.categoryKey, title: nil)
            self.getNotesAllCategories()
        } else {
            notes.remove(at: self.selectedIndexForDelete!)
            self.updateTableView()
        }
        
    }
    
    
    //MARK:- BUTTON'S ACTIONS
    
    private var wellnessSubscription: AnyCancellable?
    private func installPrivateNotebooks() {
        wellnessSubscription = WellnessStore.shared.$document.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.refreshPrivateNotebooks() }
        refreshPrivateNotebooks()
    }
    private func refreshPrivateNotebooks() {
        let notebooks = WellnessStore.shared.notebooks
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: CGFloat((notebooks.count + CollaborationStore.shared.sharedWithMe.count) * 64 + 62)))
        let stack = UIStackView(); stack.axis = .vertical; stack.spacing = 8
        stack.frame = header.bounds.insetBy(dx: 16, dy: 6); stack.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let explore = UIButton(type: .system)
        explore.setTitle("Goals, meals & insights  ✧", for: .normal)
        explore.tintColor = ApplazAppearance.accent
        explore.titleLabel?.font = ApplazAppearance.font(15, weight: .medium)
        explore.addTarget(self, action: #selector(openPrivateNotebooks), for: .touchUpInside)
        explore.heightAnchor.constraint(equalToConstant: 42).isActive = true
        stack.addArrangedSubview(explore)
        for notebook in notebooks {
            let button = UIButton(type: .system)
            var config = UIButton.Configuration.plain()
            config.title = notebook.name
            config.subtitle = (notebook.isPrivate == false ? "Public · " : "Private · ") + String(notebook.notes.count) + " notes"
            if let count = CollaborationStore.shared.match(kind: "health", sourceID: notebook.id)?.editorCount, count > 0 { config.subtitle = String(notebook.notes.count) + " notes · " + String(count) + (count == 1 ? " friend" : " friends") }
            config.image = nil
            config.imagePadding = 12; config.baseForegroundColor = .black
            config.background.backgroundColor = .clear
            config.background.cornerRadius = 14
            config.background.strokeColor = ApplazAppearance.outline
            config.background.strokeWidth = 0
            button.configuration = config
            button.contentHorizontalAlignment = .leading
            button.addAction(UIAction { [weak self] _ in guard let self else { return }; if let shared = CollaborationStore.shared.match(kind: "health", sourceID: notebook.id) { CollaborationPresentation.open(shared.id, from: self) } else { WellnessPresentation.notebook(notebook.id, from: self) } }, for: .touchUpInside)
            let more = UIButton(type: .system)
            more.setImage(UIImage(systemName: "ellipsis"), for: .normal); more.tintColor = ApplazAppearance.accent
            more.accessibilityLabel = "More notebook options"
            more.showsMenuAsPrimaryAction = true
            var options: [UIAction] = [UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                let alert = UIAlertController(title: "Delete notebook?", message: notebook.name, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel)); alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in WellnessStore.shared.deleteNotebook(notebook.id) }); self?.present(alert, animated: true)
            }]
            if notebook.id != "start-here-v1" {
                options.insert(UIAction(title: notebook.isPrivate == false ? "Make private" : "Make public", image: UIImage(systemName: notebook.isPrivate == false ? "lock" : "globe.americas")) { [weak self] _ in
                    let alert = UIAlertController(title: notebook.isPrivate == false ? "Make notebook private?" : "Make notebook public?", message: "Public notes can appear in Newsfeed. Meal logs, dated health reflections and AI chats stay private.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel)); alert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
                        guard let latest = WellnessStore.shared.notebooks.first(where: { $0.id == notebook.id }) else { return }; WellnessStore.shared.setVisibility(latest.id, isPrivate: latest.isPrivate == false)
                    }); self?.present(alert, animated: true)
                }, at: 0)
            }
            more.menu = UIMenu(children: options)
            more.widthAnchor.constraint(equalToConstant: 44).isActive = true
            let invite = UIButton(type: .system)
            invite.setImage(CollaborationStore.shared.image(kind: "health", sourceID: notebook.id), for: .normal); invite.tintColor = ApplazAppearance.accent
            invite.accessibilityLabel = !CollaborationStore.shared.hasEditors(kind: "health", sourceID: notebook.id) ? "Invite friends to " + notebook.name : "Friends in " + notebook.name
            invite.widthAnchor.constraint(equalToConstant: 36).isActive = true
            invite.addAction(UIAction { [weak self] _ in guard let self else { return }; CollaborationPresentation.invite(kind: "health", sourceID: notebook.id, from: self) }, for: .touchUpInside)
            let visibility = UIButton(type: .system)
            visibility.setImage(UIImage(systemName: notebook.isPrivate == false ? "globe.americas" : "lock", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)), for: .normal)
            visibility.tintColor = ApplazAppearance.accent
            visibility.accessibilityLabel = "Visibility of " + notebook.name
            visibility.accessibilityValue = notebook.isPrivate == false ? "Public" : "Private"
            visibility.widthAnchor.constraint(equalToConstant: 42).isActive = true
            visibility.isEnabled = notebook.id != "start-here-v1"
            visibility.addAction(UIAction { [weak self] _ in self?.changeWellnessVisibility(notebook.id) }, for: .touchUpInside)
            let content = UIStackView(arrangedSubviews: [visibility, button]); content.spacing = 0
            content.backgroundColor = ApplazAppearance.surface; content.layer.cornerRadius = 14; content.layer.borderWidth = 1; content.layer.borderColor = ApplazAppearance.outline.cgColor
            let row = UIStackView(arrangedSubviews: [content, invite, more]); row.spacing = 2
            row.heightAnchor.constraint(equalToConstant: 56).isActive = true
            stack.addArrangedSubview(row)
        }
        header.addSubview(stack)
        for shared in CollaborationStore.shared.sharedWithMe {
            let button = UIButton(type: .system)
            var config = UIButton.Configuration.plain(); config.title = shared.name; config.subtitle = "Shared with you"; config.image = UIImage(systemName: "person.2"); config.imagePadding = 12; config.baseForegroundColor = .black; config.background.backgroundColor = ApplazAppearance.surface; config.background.cornerRadius = 14
            button.configuration = config; button.contentHorizontalAlignment = .leading
            button.addAction(UIAction { [weak self] _ in guard let self else { return }; CollaborationPresentation.open(shared.id, from: self) }, for: .touchUpInside)
            button.heightAnchor.constraint(equalToConstant: 56).isActive = true; stack.addArrangedSubview(button)
        }
        tblViewNoteCateoryTitle.tableHeaderView = header
        tblViewNoteCateoryTitle.isHidden = false
        lblNotesCategoryNotFound.isHidden = true
    }
    private func changeWellnessVisibility(_ id: String) {
        guard let notebook = WellnessStore.shared.notebooks.first(where: { $0.id == id }), id != "start-here-v1" else { return }
        let makePrivate = notebook.isPrivate == false
        let alert = UIAlertController(title: makePrivate ? "Make notebook private?" : "Share notebook to Newsfeed?", message: makePrivate ? "Your notebook will no longer appear in Newsfeed. Your collaborators can still edit it." : "Public notes can appear in Newsfeed. Meal logs, dated health reflections and AI chats stay private.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: makePrivate ? "Make private" : "Make public", style: .default) { _ in WellnessStore.shared.setVisibility(id, isPrivate: makePrivate) })
        present(alert, animated: true)
    }
    @objc private func openPrivateNotebooks() { WellnessPresentation.library(from: self) }

    @IBAction func btnAddPressed(_ sender: UIButton) {
        let dialog = NewNotebookViewController()
        dialog.modalPresentationStyle = .pageSheet
        dialog.existingNotebooks = notes
        dialog.onSelectPrivateNotebook = { [weak self] id in guard let self else { return }; WellnessPresentation.addNote(to: id, from: self) }
        dialog.onSelectExisting = { [weak self] notebook in self?.openNoteEditor(in: notebook) }
        dialog.onCreate = { [weak self] name, isPrivate in
            guard let self else { return }
            if UserDefaults.standard.bool(forKey: Guest_Key) {
                self.notes.append(Note(categoryName: name, categoryKey: nil, isPrivateNote: isPrivate, noteBody: []))
                self.updateTableView()
            } else {
                self.database.createEmptyNotebook(name: name, isPrivate: isPrivate) { [weak self] result in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        switch result {
                        case .success(let notebook):
                            if !self.notes.contains(where: { $0.categoryKey == notebook.categoryKey }) { self.notes.append(notebook) }
                            self.updateTableView()
                        case .failure(let error):
                            let alert = UIAlertController(title: "Couldn’t create notebook", message: error.localizedDescription, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default))
                            self.present(alert, animated: true)
                        }
                    }
                }
            }
        }
        present(dialog, animated: true)
    }

    private func openNoteEditor(in notebook: Note) {
        guard let editor = storyboard?.instantiateViewController(withIdentifier: "AddNoteVC") as? AddNoteVC else { return }
        editor.hidesBottomBarWhenPushed = true
        editor.notes = notes
        editor.isFromNoteVC = true
        editor.selectedCategoryNote = notebook.categoryName ?? ""
        editor.categoryKey = notebook.categoryKey ?? ""
        editor.savingCompletionHandler = { [weak self] bodies in
            guard let self, let index = self.notes.firstIndex(where: {
                notebook.categoryKey != nil ? $0.categoryKey == notebook.categoryKey : $0.categoryName == notebook.categoryName
            }) else { return }
            self.notes[index].noteBody = (self.notes[index].noteBody ?? []) + bodies
            self.updateTableView()
        }
        navigationController?.pushViewController(editor, animated: true)
    }

    @IBAction func btn_SocialAppPressed(_ sender: Any) {
        if let dashboard = tabBarController as? DashboardController {
            dashboard.selectedIndex = 0
            return
        }
//        let storyboard = UIStoryboard(name: "SocialMain", bundle: Bundle.main)
//        let tabbar = storyboard.instantiateViewController(withIdentifier: "DashboardController") as! DashboardController
//        self.navigationController?.pushViewController(tabbar, animated: true)
        let storyboard = UIStoryboard(name: "SocialMain", bundle: Bundle.main)
        let tabbar = storyboard.instantiateViewController(withIdentifier: "WelcomeViewController") as! WelcomeViewController
        let client = FirebaseClient().setup() // initialize client
        tabbar.client = client // set the client to use        
        self.navigationController?.pushViewController(tabbar, animated: true)
    }
    
    
    @objc func btnDeletePressed(_ sender : UIButton) {

        alertView(nil, kDELETE_CATEGORY, ["No", "Yes"]) { (index) in
            if index == 1 {
                self.selectedIndexForDelete = sender.tag
                self.deleteNotesCategories()
            }
        }
    }
    
    @objc func btnUpdatePressed(_ sender : UIButton) {
        
        var note = self.notes[sender.tag]
        
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
                        self.notes.remove(at: sender.tag)
                        self.notes.append(note)
                        self.updateTableView()
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
    
    private func updateDataBase() {
        
    }
    @objc func btnSharedPressed(_ sender: UIButton) {
        guard notes.indices.contains(sender.tag) else { return }
        let original = notes[sender.tag]
        let makePrivate = original.isPrivateNote != true
        alertPermissionMessage(message: makePrivate ? "Make this notebook private?" : "Share this notebook to Newsfeed?") { [weak self] proceed in
            guard proceed, let self else { return }
            if UserDefaults.standard.bool(forKey: Guest_Key) {
                guard self.notes.indices.contains(sender.tag) else { return }
                self.notes[sender.tag].isPrivateNote = makePrivate
                self.updateTableView()
            } else {
                self.database.editDatabaseRecords(categoryNote: original.categoryName, titleNote: nil, categoryKey: original.categoryKey, titleKey: nil, note: nil, isPrivateNote: makePrivate) { [weak self] error in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        if error == nil { self.getNotesAllCategories() }
                        else { let alert = UIAlertController(title: "Couldn’t update visibility", message: "Please try again.", preferredStyle: .alert); alert.addAction(UIAlertAction(title: "OK", style: .default)); self.present(alert, animated: true) }
                    }
                }
            }
        }
    }

    @IBAction func btnSettingPressed(_ sender: UIButton) {
        let settingsVC = self.storyboard?.instantiateViewController(withIdentifier: "SettingsVC") as! SettingsVC
        self.navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    func invalidateComponents() {
        
        let defaults = UserDefaults.standard
        
        let colorIndex = defaults.integer(forKey: MYTHEMECOLORINDEX)
        
        print("selected ColorIndex")
        print(colorIndex)
        
        //updateColor(view: navigationBarView1, index: colorIndex)
        updateTableView()
        
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
        if fontIndex != 0 {
            updateFont(fontIndex: fontIndex)
        }
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
    
    func updateTableViewFont(cell: NoteCategoryTBLViewCell) {
        
        let defaults = UserDefaults.standard
        let fontIndex = defaults.integer(forKey: MYTHEMEFONTINDEX)
        
        var fontsize: CGFloat = 0
        
        if sharedObj!.isProductPurchased == false {
            fontsize = 17
        } else {
            fontsize = 22
        }
        
        switch fontIndex {
        case 1:
            cell.lblNoteCategoryTitle.font = UIFont(name: "SanFranciscoDisplay-Regular", size: fontsize)
        case 2:
            cell.lblNoteCategoryTitle.font = UIFont(name: "Comic Sans MS", size: fontsize)
        case 3:
            cell.lblNoteCategoryTitle.font = UIFont(name: "Helvetica", size: fontsize)
        case 4:
            cell.lblNoteCategoryTitle.font = UIFont(name: "Times New Roman", size: fontsize)
        case 5:
            cell.lblNoteCategoryTitle.font = UIFont(name: "Bodoni 72 Book", size: fontsize)
        default:
            cell.lblNoteCategoryTitle.font = ApplazAppearance.font(fontsize, weight: .medium)
        }
        
    }
    
    func updateTableViewColor(cell: NoteCategoryTBLViewCell) {
        
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
        
        print(colorindex)
        
        /*
        var myfirstColor = UIColor(rgb: mythemecolor1).withAlphaComponent(0.0)
        if colorindex == 5 {
            myfirstColor = UIColor(rgb: mythemecolor1).withAlphaComponent(1.0)
        }
        let mysecondColor = UIColor(rgb: mythemecolor2).withAlphaComponent(1.0)
        */
        
        let view = cell.backGroundView
        //        layer.frame = (view?.bounds ?? nil) ?? CGRect(x:0,y:0,width:0,height:0)
        //        layer.colors = [firstColor,secondColor].map({$0.cgColor})
        //
        //        layer.startPoint = CGPoint(x: 0, y: 1)
        //        layer.endPoint = CGPoint(x: 1, y: 0.0)
        //        view?.layer.addSublayer(layer)
        
        let layer = view?.layer as! CAGradientLayer
        layer.colors = [mythemecolor1,mythemecolor2].map({$0.cgColor})
        
        layer.startPoint = CGPoint(x: 0, y: 1)
        layer.endPoint = CGPoint(x: 1, y: 0.0)
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
        layer.colors = [mythemecolor1,mythemecolor2].map({($0 as AnyObject).cgColor})
        layer.startPoint = CGPoint(x: 0, y: 1)
        layer.endPoint = CGPoint(x: 1, y: 0.0)
        
    }
}

// Handle tapping on the text snippet
extension NoteCategoryListVC {

    @objc func tapText(gesture:UITapGestureRecognizer) {
     
        let text = textBodyLabel.text!
        let textSignInRange = (text as NSString).range(of: " Back to Registration")
        if gesture.didTapText(label: textBodyLabel, inRange: textSignInRange) {
            self.navigationController?.popViewController(animated: true)
            
        }
        
    }
    
    func prepareUILabel() {
         let bodyText = "Guest mode\nYour notes won’t be saved to your account.\n Back to Registration"
        textBodyLabel.text = bodyText
        textBodyLabel.isUserInteractionEnabled = true
        let textAttriString = NSMutableAttributedString(string: bodyText)
        let range = (bodyText as NSString).range(of: " Back to Registration")
        let generalRange = (bodyText as NSString).range(of: bodyText)
        textAttriString.addAttribute(NSAttributedString.Key.font, value: ApplazAppearance.font(14), range: generalRange)
        textAttriString.addAttribute(NSAttributedString.Key.foregroundColor, value: ApplazAppearance.ink.withAlphaComponent(0.75), range: generalRange)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 4
        textAttriString.addAttribute(.paragraphStyle, value: paragraph, range: generalRange)
        let headingRange = (bodyText as NSString).range(of: "Guest mode")
        textAttriString.addAttribute(.font, value: ApplazAppearance.font(15, weight: .medium), range: headingRange)
        textAttriString.addAttribute(.foregroundColor, value: ApplazAppearance.ink, range: headingRange)
        textAttriString.addAttribute(.font, value: ApplazAppearance.font(14, weight: .medium), range: range)
         textAttriString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.darkBlue, range: range)
        
        textBodyLabel.attributedText = textAttriString
    }
}

extension UITapGestureRecognizer {
    func didTapText(label: UILabel, inRange targetRange: NSRange) -> Bool {
        
        let layoutManager = NSLayoutManager()
         let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize
        
        let locationOfTouchInLabel = self.location(in: label)
        
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(x:(labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,y:
                                              (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)
        let locationOfTouchInTextContainer = CGPoint(x:locationOfTouchInLabel.x - textContainerOffset.x, y:
                                                         locationOfTouchInLabel.y - textContainerOffset.y);
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        return NSLocationInRange(indexOfCharacter, targetRange)
    }
}

extension NoteCategoryListVC : GADBannerViewDelegate {
    
        /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("adViewDidReceiveAd")
        addBannerViewToView(bannerView)
    }
    
    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
                didFailToReceiveAdWithError error: Error) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("adViewWillPresentScreen")
    }
    
    /// Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("adViewWillDismissScreen")
    }
    
    /// Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("adViewDidDismissScreen")
    }
    
    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("adViewWillLeaveApplication")
    }
}

/*
extension NoteCategoryListVC : ISBannerDelegate {
    
    func bannerDidLoad(_ bannerView: ISBannerView!) {
        print("bannerDidLoad")
        
        self.viewBanner = bannerView
        
        var y: CGFloat = view.frame.size.height - (bannerView.frame.size.height / 2)
            if #available(iOS 11.0, *) {
                y -= view.safeAreaInsets.bottom
            } else {
                // Fallback on earlier versions
            }
    
        viewBanner?.center = CGPoint(x: view.frame.size.width / 2, y: y)
        view.addSubview(viewBanner!)
      
    }
    
    func bannerDidFailToLoadWithError(_ error: Error!) {
        print("bannerDidFailToLoadWithError")
    }
    
    func didClickBanner() {
        print("didClickBanner")
    }
    
    func bannerWillPresentScreen() {
        print("bannerWillPresentScreen")
    }
    
    func bannerDidDismissScreen() {
        print("bannerDidDismissScreen")
    }
    
    func bannerWillLeaveApplication() {
        print("bannerWillLeaveApplication")
    }
}
*/
