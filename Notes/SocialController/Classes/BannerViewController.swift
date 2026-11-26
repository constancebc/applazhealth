//
//  BannerViewController.swift
//  Project
//
//  Created by Bossly on 10/8/16.
//  Copyright © 2016 Bossly. All rights reserved.
//

import UIKit
import GoogleMobileAds
import Firebase

enum FeedType {
    case whirld
    case following
}
class BannerViewController: UIViewController,GADBannerViewDelegate{

    @IBOutlet weak var followingMenu: UIBarButtonItem!
    @IBOutlet weak var whirldMenu: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bannerView:GADBannerView?
    @IBOutlet weak var bannerHeightConstraints: NSLayoutConstraint!
    
    var notes = [Any]()
    var followingNotes = [Note]()
    var userHashing: [String : String] = [:]
    // Admob variables
      var adiPath = 2 // Nth item for ads
      var adReq = 0
      var adToShow = 0 // Nuber of ads to show
      var adRetCnt = 0 // Number of items returned

      /// The native ads.
      var nativeAds = [GADNativeAd]()

      /// The ad loader that loads the native ads.
      var adLoader: GADAdLoader!
    
    //Database
    private var database = DatabaseService()
    var currentFeed: FeedType = .whirld
    
    override func viewDidLoad() {
        navigationController?.navigationBar.tintColor = .black // Sets tint color for all items
        collectionView.register(UINib(nibName: "BannerCategoryCell", bundle: .main), forCellWithReuseIdentifier: "BannerCategoryCell")
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .vertical
        collectionView.collectionViewLayout = layout
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.delegate = self
        collectionView.dataSource = self
        bannerHeightConstraints.constant = 0
//loadNativeAd()
        
        if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
             self.getNotesAllCategories()
             self.getNotesAllFollowing()
        } else {
            collectionView.isHidden = true
        }
        setMenu()
    }
    
    func loadNativeAd() {
        
        let multipleAdsOptions = GADMultipleAdsAdLoaderOptions()
        multipleAdsOptions.numberOfAds = 1
        self.adLoader = GADAdLoader(adUnitID: kNativeAdID, rootViewController: self,
                                    adTypes: [.native],
                                    options: [multipleAdsOptions])
        self.adLoader.delegate = self
        self.adLoader.load(GADRequest())
    }
    
    private func setMenu() {
        if currentFeed == .whirld {
            followingMenu.tintColor = .black
            whirldMenu.tintColor = .black
        } else {
            followingMenu.tintColor = .black
            whirldMenu.tintColor = .black
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground() // or configureWithDefaultBackground()
            
            // Set the background color (optional)
            appearance.backgroundColor = .white
            
            // Set the separator (shadow) color
            appearance.shadowColor = .lightGray // Set to your desired color
            appearance.shadowImage = UIImage() // Ensures a solid separator line
            // Set the tint color for bar button items
            appearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.black] // Normal state color
            appearance.buttonAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.black] // Highlighted state color
            // Apply appearance to navigation bar
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            
            navigationController?.navigationBar.tintColor = .black // This sets the tint color for all items

        } else {
            
        }
        
        self.navigationController?.navigationBar.isHidden = false
    }
    
    func setUpConnectionView() {
        collectionView.isHidden = false
        collectionView.reloadData()
        //loadNativeAd()
    }
    
    //MARK:- GET NOTE'S ALL CATEGORIES
    func getNotesAllFollowing() {
        followingNotes = []
        let currentUser: SocialUserModel? = SocialUserModel.current
        let query: DatabaseQuery? = currentUser?.followings.queryOrderedByKey()
        query?.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let children = snapshot.children.allObjects as? [DataSnapshot] else { return }
            // reverse order of the items
            for child in children {
                self.database.getData(specificUserId: child.key, completionHandler: { notes in
                    DispatchQueue.main.async {
                        let newNotes = notes.filter({$0.isPrivateNote == false})
                        for each in newNotes {
                            self.userHashing[each.categoryKey ?? ""] = child.key
                        }
                        if newNotes.count > 0 {
                            self.followingNotes.append(contentsOf: newNotes)
                        }
                        if self.currentFeed == .following {
                            self.setUpConnectionView()
                        }
                    }
                })
            }
        })
    }
    
    //MARK:- GET NOTE'S ALL CATEGORIES
    func getNotesAllCategories() {
        notes = []
        database.getAllUser { allUsers in
            for userId in allUsers {
                self.database.getData(specificUserId: userId, completionHandler: { notes in
                    DispatchQueue.main.async { [self] in
                        let newNotes = notes.filter({$0.isPrivateNote == false})
                        for each in newNotes {
                            self.userHashing[each.categoryKey ?? ""] = userId
                        }
                        if newNotes.count > 0 {
                            self.notes.append(contentsOf: newNotes)
                        }
                        if self.currentFeed == .whirld {
                            self.setUpConnectionView()
                            loadNativeAd()
                        }
                    }
                })
            }
        }
    }
    
    @IBAction func whirldMenuClicked(_ sender: Any) {
        currentFeed = .whirld
        setUpConnectionView()
        setMenu()
    }
    
    @IBAction func followingMenuClicked(_ sender: Any) {
        currentFeed = .following
        setUpConnectionView()
        setMenu()
    }
    @IBAction func noteBookMenu(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // instantiate viewController (NoteCategoryListVC) from that storyboard, safely not force unwrapping
        if let noteCategoryVC = storyboard.instantiateViewController(withIdentifier: "NoteCategoryListVC") as? NoteCategoryListVC {
            noteCategoryVC.hidesBottomBarWhenPushed = true
            // push or present the view controller
            // since we're using navigation controllers, we use pushViewController else we woulda used present
            self.navigationController?.pushViewController(noteCategoryVC, animated: true)
        }
        Coordinator.rootViewContoller(isFirstTime: false)
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
      Coordinator.rootViewContoller(isFirstTime: false)
    }
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) { }
}
extension BannerViewController: GADNativeAdLoaderDelegate, GADNativeAdDelegate  {
    
  func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
     print("Failed to receive ads")
      print(error.localizedDescription)
  }

  func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
     // A native ad has loaded, and can be displayed.
     self.nativeAds.append(nativeAd)
  }
 
    func adLoaderDidFinishLoading(_ adLoader: GADAdLoader) {
        
        // The adLoader has finished loading ads, and a new request can be sent.
        print("ad did finish loading.....")
        let adInterval = 10 // Display ad every 10 items
        let adRepeatLimit = 10 // Repeat ad display 10 times
        
        let numberOfNotes = notes.count
        
        var adRepeatCount = 0
        var adPosition = 2 // Start displaying ad after the second notebook
        
        while adRepeatCount < adRepeatLimit && adPosition < numberOfNotes {
            if let nativeAd = self.nativeAds.first {
                self.notes.insert(nativeAd, at: adPosition)
                print("Native ad inserted at:\(adPosition)")
                adPosition += adInterval + 1 // Move to the next ad position
                adRepeatCount += 1
            }else{
                print("Ad did not loaded..")
                break
            }
        }
        self.collectionView.reloadData()
    }

// This for debugging
func nativeAdDidRecordImpression(_ nativeAd: GADNativeAd) {
   print("The native ad was shown.")
}

func nativeAdDidRecordClick(_ nativeAd: GADNativeAd) {
    print("The native ad was clicked on.")
}

func nativeAdWillPresentScreen(_ nativeAd: GADNativeAd) {
    print("The native ad will present a full screen view.")
}

func nativeAdWillDismissScreen(_ nativeAd: GADNativeAd) {
   print("The native ad will dismiss a full screen view.")
}

func nativeAdDidDismissScreen(_ nativeAd: GADNativeAd) {
   print("The native ad did dismiss a full screen view.")
}

func nativeAdWillLeaveApplication(_ nativeAd: GADNativeAd) {
   print("The native ad will cause the application to become inactive and open a new application.")
 }
}
extension BannerViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let noteTitleListVC = storyBoard.instantiateViewController(withIdentifier: "NoteTitleListVC") as! NoteTitleListVC
        noteTitleListVC.hidesBottomBarWhenPushed = true
        if currentFeed == .following {
            let userNotes = followingNotes[indexPath.row]
            if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
                guard let noteBody = userNotes.noteBody else{return}
                noteTitleListVC.noteDictionary = ["NotesBody" : noteBody, "CategoryKey" : userNotes.categoryKey!, "CategoryNoteName" : userNotes.categoryName! ]
            } else {
                guard let noteBody = userNotes.noteBody else{return}
                noteTitleListVC.noteDictionary = ["NotesBody" : noteBody, "CategoryNoteName" : userNotes.categoryName!]
            }
            noteTitleListVC.userId = userHashing[followingNotes[indexPath.row].categoryKey ?? ""] ?? ""
            noteTitleListVC.isFromProfile = true
            self.navigationController?.pushViewController(noteTitleListVC, animated: true)
        } else {
            if notes[indexPath.item] is Note{
                let userNotes = notes[indexPath.row] as! Note
                if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
                    guard let noteBody = userNotes.noteBody else{return}
                    noteTitleListVC.noteDictionary = ["NotesBody" : noteBody, "CategoryKey" : userNotes.categoryKey!, "CategoryNoteName" : userNotes.categoryName! ]
                } else {
                    guard let noteBody = userNotes.noteBody else{return}
                    noteTitleListVC.noteDictionary = ["NotesBody" : noteBody, "CategoryNoteName" : userNotes.categoryName!]
                }
                noteTitleListVC.userId = userHashing[userNotes.categoryKey ?? ""] ?? ""
                noteTitleListVC.isFromProfile = true
                self.navigationController?.pushViewController(noteTitleListVC, animated: true)
            }
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width - 16
        let height = collectionView.frame.width - 40
        return CGSize(width: width, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if currentFeed == .following {
            return followingNotes.count
        }else{
            return notes.count
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BannerCategoryCell", for: indexPath) as! BannerCategoryCell
        for subview in cell.containerView.subviews {
            if subview is GADNativeAdView {
                subview.removeFromSuperview()
            }
        }
        
        if currentFeed == .following {
            cell.titleMessage.text = followingNotes[indexPath.row].categoryName
            cell.setProfile(userId: userHashing[followingNotes[indexPath.row].categoryKey ?? ""] ?? "")
        } else {
            if let Note = notes[indexPath.item] as? Note{
                print("print IndexPath.row==\(indexPath.row)")
                
                cell.titleMessage.text = Note.categoryName
                cell.setProfile(userId: userHashing[Note.categoryKey ?? ""] ?? "")
            }else if let nAd = notes[indexPath.item] as? GADNativeAd{
                cell.userName.text = "Sponsored"
                cell.profilePick?.image = UIImage(named: kDefaultProfilePhoto)
                nAd.delegate = self
                nAd.rootViewController = self
                let nibView = Bundle.main.loadNibNamed("UnifiedNativeAdView", owner: nil, options: nil)?.first
                let nativeAdView = nibView as! GADNativeAdView
                nativeAdView.frame.size.width = cell.containerView.frame.size.width
                nativeAdView.frame.size.height = cell.containerView.frame.size.height
                //cell.containerView.subviews.first?.removeFromSuperview()
                cell.containerView.addSubview(nativeAdView)
                let nativeAd = nAd
                nativeAdView.nativeAd = nativeAd
                
                // Add content to native view
                (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
                nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
                
                (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
                nativeAdView.bodyView?.isHidden = nativeAd.body == nil
                
                (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
                nativeAdView.iconView?.isHidden = nativeAd.icon == nil
                
                (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
                nativeAdView.advertiserView?.isHidden = nativeAd.advertiser == nil
                
                nativeAdView.callToActionView?.isUserInteractionEnabled = false
            }
            
        }
        cell.profilePick.layer.cornerRadius = cell.profilePick.frame.height/2
        cell.profilePick.clipsToBounds = true
        cell.containerView.addCornerRadius(radius: 6)
        
        return cell
        
    }
    
}
