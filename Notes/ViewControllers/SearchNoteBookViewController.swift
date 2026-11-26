//
//  SearchNotesViewController.swift
//  Notes
//
//  Created by Saeed Iqbal on 02/12/2023.
//  Copyright © 2023 Sevenstar Infotech. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import SDWebImage
import AVFoundation

class SearchNoteBookViewController: UIViewController, UISearchBarDelegate{
    
    var notebooks:[Note] = []
    
    @IBOutlet private weak var searchbar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    private var tapGesture: UITapGestureRecognizer!
    private var database = DatabaseService()
    private var activeSearch = UUID()
    let collectionCellMargin: CGFloat = 1
    var userHashing: [String : String] = [:]
    // MARK: - View cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchbar.delegate = self
        self.searchbar.placeholder = "Search notebooks"
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        collectionView.keyboardDismissMode = .interactive
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
                tapGesture.cancelsTouchesInView = false // Allow other gestures to proceed simultaneously
                tapGesture.delegate = self // Set the delegate to manage gesture conflicts
                view.addGestureRecognizer(tapGesture)
        
    }
    
    @objc func dismissKeyboard() {
        if searchbar.isFirstResponder {
            searchbar.resignFirstResponder()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
    }
    
    // MARK: - Data
    func getNotesForSearchText(_ searchText: String) {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let request = UUID()
        activeSearch = request
        notebooks = []; userHashing = [:]
        self.collectionView.reloadData()
        guard !query.isEmpty else { return }
        database.getAllUser { [weak self] users in
            guard let self, self.activeSearch == request else { return }
            for userID in users {
                self.database.getData(specificUserId: userID) { [weak self] fetchedNotes in
                    DispatchQueue.main.async {
                        guard let self, self.activeSearch == request else { return }
                    for note in fetchedNotes where note.isPrivateNote == false && (note.categoryName ?? "").lowercased().contains(query) {
                        guard let key = note.categoryKey, self.userHashing[key] == nil else { continue }
                        self.userHashing[key] = userID
                        self.notebooks.append(note)
                    }
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        getNotesForSearchText(searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        let searchText = searchBar.text ?? ""
        searchBar.resignFirstResponder()
        getNotesForSearchText(searchText)
    }
}

extension SearchNoteBookViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.notebooks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "RandomNotesCollectionCell", for: indexPath) as! RandomNotesCollectionCell
        cell.configureCell(itemData: self.notebooks[indexPath.row])
        return cell
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
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let noteTitleListVC = storyBoard.instantiateViewController(withIdentifier: "NoteTitleListVC") as! NoteTitleListVC
         var userNotes = notebooks[indexPath.row]
        noteTitleListVC.userId = userHashing[userNotes.categoryKey ?? ""] ?? ""
        noteTitleListVC.isFromProfile = true
        if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
             guard let noteBody = userNotes.noteBody else{return}
              noteTitleListVC.noteDictionary = ["NotesBody" : noteBody, "CategoryKey" : userNotes.categoryKey!, "CategoryNoteName" : userNotes.categoryName! ]
        } else {
            guard let noteBody = userNotes.noteBody else{return}
            noteTitleListVC.noteDictionary = ["NotesBody" : noteBody, "CategoryNoteName" : userNotes.categoryName!]
        }
        self.navigationController?.pushViewController(noteTitleListVC, animated: true)
    }
}
extension SearchNoteBookViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == tapGesture && touch.view is UICollectionView && !notebooks.isEmpty {
            return false
        }
        return true
    }
}
