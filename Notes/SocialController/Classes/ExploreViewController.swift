//
//  ExploreViewController.swift
//  Mustage
//
//  Created by Oleg Baidalka on 15/03/2018.
//  Copyright © 2018 Bossly. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import SDWebImage
import AVFoundation

class RandomNotesCollectionCell: UICollectionViewCell {
    @IBOutlet private weak var imageView: UIImageView?
    @IBOutlet private weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        self.imageView?.addCornerRadius(radius: 5)
    }
    
    func configureCell(itemData: Note) {
        self.titleLabel.text = itemData.categoryName
    }
    
}

class ExploreViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var ranked:NSMutableArray = []
    var searchResults:NSMutableArray = []
    var randomNotes:[Note] = []
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var searchbar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    
    let collectionCellMargin: CGFloat = 1
    
    // MARK: - View cycle
    
    override func viewDidLoad() {
//        self.clearsSelectionOnViewWillAppear = true
        self.tableView.estimatedRowHeight = 350
        self.tableView.rowHeight = UITableView.automaticDimension
        
        self.tableView.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: UIControl.Event.valueChanged)
        
        // add searchbar to find users to follow
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.searchbar.delegate = self
        self.searchbar.placeholder = "Search profiles"
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        self.loadData()
      //  self.getRandomUserPost()
        self.initialSetUp()
        
        tableView.keyboardDismissMode = .interactive
        collectionView.keyboardDismissMode = .interactive
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ExploreViewController.dismissKeyboard))
        

       tap.cancelsTouchesInView = false
       view.addGestureRecognizer(tap)

    }
    
    @objc func dismissKeyboard() {
        if searchbar.isFirstResponder {
            searchbar.resignFirstResponder()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.tableView.startObserveScrollingTop()
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tableView.stopObserveScrollingTop()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let profileCtrl = segue.destination as? ProfileViewController {
            if let user = sender as? DatabaseReference, let key = user.key {
                profileCtrl.currentUser = SocialUserModel(key)
                profileCtrl.isFromSearch = true
            }
        }
    }
    
    // MARK: - Data
    
    func loadData() {
        SocialUserModel.collection
            .queryOrdered(byChild:"liked") // by likes count
            .queryLimited(toLast: 10) // only first 10 users
            .observeSingleEvent(of: .value, with: { (snapshot) in
                
                let results:NSMutableArray = []
                if let children = snapshot.children.allObjects as? [DataSnapshot] {
                    // reverse order of the items
                    for child in children {
                        results.insert(SocialUserModel(child), at: 0)
                    }
                }

                self.ranked = results
                self.searchResults = results
                self.tableView.reloadData()
                self.tableView.refreshControl?.endRefreshing()
            })
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        SocialUserModel.collection.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            
            let results:NSMutableArray = []
            if let children = snapshot.children.allObjects as? [DataSnapshot] {
                
                for child in children {
                    if let value = child.value as? [String: Any], let name = value["User Name"] as? String {
                        if name.lowercased().contains(searchText.lowercased()) {
                            results.add(SocialUserModel(child))
                        }
                    }
                }
            }
            
            if searchText.isEmpty {
                self.searchResults = self.ranked
            } else {
                self.searchResults = results
            }
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.tableView.reloadData()
            self.setUpTableCollectionView(showTable: !searchText.isEmpty)
        })
    }
    
    @objc func handleRefresh(refreshControl: UIRefreshControl) {
        // reload data
        loadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        let searchText = searchBar.text ?? ""
        searchBar.resignFirstResponder()
        
        SocialUserModel.collection.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            
            let results:NSMutableArray = []
            if let children = snapshot.children.allObjects as? [DataSnapshot] {
                
                for child in children {
                    if let value = child.value as? [String: Any], let name = value["User Name"] as? String {
                        if name.lowercased().contains(searchText.lowercased()) {
                            results.add(SocialUserModel(child))
                        }
                    }
                }
            }
            
            if searchText.isEmpty {
                self.searchResults = self.ranked
            } else {
                self.searchResults = results
            }
            
            self.tableView.reloadData()
            self.setUpTableCollectionView(showTable: !searchText.isEmpty)
        })
        
    }
    
    // MARK: - TableView Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "User") as? UserTableViewCell
        cell?.profileRecognizer?.isEnabled = true // not allow to select profile

        if let userInfo = self.searchResults[indexPath.row] as? SocialUserModel {
            cell?.userRef = userInfo.ref
        }
        cell?.delegate = self
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if let userInfo = self.searchResults[indexPath.row] as? SocialUserModel {
//            self.performSegue(withIdentifier: "show.profile", sender: userInfo.ref)
//        }
    }
}

extension ExploreViewController: UserTableViewCellDelegate {
    
    func didSelected(ref: DatabaseReference) {
        self.performSegue(withIdentifier: "show.profile", sender: ref)
    }
    
    func didAction(ref: DatabaseReference?, position: NSInteger) {
        
    }
    
}

extension ExploreViewController {
    func initialSetUp() {
        self.setUpTableCollectionView(showTable: !(searchbar.text?.isEmpty ?? false))
        
        guard let collectionView = collectionView, let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        
        flowLayout.minimumInteritemSpacing = collectionCellMargin
        flowLayout.minimumLineSpacing = collectionCellMargin
        flowLayout.sectionInset = UIEdgeInsets(top: collectionCellMargin,
                                               left: collectionCellMargin,
                                               bottom: collectionCellMargin,
                                               right: collectionCellMargin)
    }
    
    func setUpTableCollectionView(showTable: Bool) {
        self.tableView.isHidden = !showTable
        self.collectionView.isHidden = showTable
    }
}

extension ExploreViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.randomNotes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "RandomNotesCollectionCell", for: indexPath) as! RandomNotesCollectionCell
        cell.configureCell(itemData: self.randomNotes[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
                if let userInfo = self.searchResults[indexPath.row] as? SocialUserModel {
                    self.performSegue(withIdentifier: "show.profile", sender: userInfo.ref)
                }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let collectionWidth = self.collectionView?.bounds.size.width ?? 124
//        let cellWidth = collectionWidth/kFavoritesColumns - 50
//        debugPrint("The width", cellWidth)
////        return CGSize(width: cellWidth, height: 124)
//        return CGSize(width: 90, height: 90)
        
        let noOfCellsInRow = 2   //number of column you want
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let totalSpace = flowLayout.sectionInset.left
        + flowLayout.sectionInset.right
        + (flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))
        
        let size = Int((collectionView.bounds.width - 16) / CGFloat(noOfCellsInRow))
        return CGSize(width: size, height: 70)
    }
}
extension ExploreViewController {
    
    func getRandomUserPost() {
        SocialUserModel.collection
            .queryOrdered(byChild:"liked") // by likes count
            .queryLimited(toLast: 10) // only first 10 users
            .observeSingleEvent(of: .value, with: { (snapshot) in
                
                let results:NSMutableArray = []
                if let children = snapshot.children.allObjects as? [DataSnapshot] {
                    // reverse order of the items
                    for child in children {
                        results.insert(SocialUserModel(child), at: 0)
                    }
                }
                
                for i  in 0..<results.count {
                    if let userInfo = self.ranked[i] as? SocialUserModel {
                        if !userInfo.isCurrent() {
//                            debugPrint("The notes", userInfo.notes)
                            let usersPublicNotes = userInfo.notes.filter { $0.isPrivateNote == false }
                            
                            if let oneNotePerUser = usersPublicNotes.first {
                                // In case if we needs to redirect make a struct model with two object one of users key ref and another this below random notes so that when we tap we could have the ref of user to redirect to his profile.
                                self.randomNotes.append(oneNotePerUser)
                            }
                        }
                    }
                }
                
                self.collectionView.reloadData()
            })
    }
    
    
}
