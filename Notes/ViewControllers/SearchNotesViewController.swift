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

class SearchNotesViewController: UIViewController, UISearchBarDelegate{
    
    var notesBody:[NoteBody] = []
    var notebooks:[Note] = []
    var userids:[String] = []
    @IBOutlet weak var tblViewNoteTitle: UITableView!
    @IBOutlet private weak var searchbar: UISearchBar!
    private var database = DatabaseService()
    private var activeSearch = UUID()
    var userHashing: [String : String] = [:]
    private var tapGesture: UITapGestureRecognizer!
    // MARK: - View cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchbar.delegate = self
        self.searchbar.placeholder = "Search note titles"
        
        self.tblViewNoteTitle.dataSource = self
        self.tblViewNoteTitle.delegate = self
        
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
        notesBody = []; notebooks = []; userHashing = [:]
        self.tblViewNoteTitle.reloadData()
        guard !query.isEmpty else { return }
        database.getAllUser { [weak self] users in
            guard let self, self.activeSearch == request else { return }
            for userID in users {
                self.database.getData(specificUserId: userID) { [weak self] fetchedNotes in
                    DispatchQueue.main.async {
                        guard let self, self.activeSearch == request else { return }
                    for note in fetchedNotes where note.isPrivateNote == false {
                        for body in note.noteBody ?? [] where (body.titleName ?? "").lowercased().contains(query) {
                            self.notesBody.append(body)
                            self.notebooks.append(note)
                            self.userHashing[note.categoryKey ?? ""] = userID
                        }
                    }
                        self.tblViewNoteTitle.reloadData()
                    }
                }
            }
        }
    }

    func getNoteForNoteBody(_ noteBodyToFind: NoteBody, from note: Note) -> Note? {
        guard let noteBodies = note.noteBody else { return nil }
        
        for body in noteBodies {
            if body.titleName == noteBodyToFind.titleName && body.descriptionText == noteBodyToFind.descriptionText && body.noteKey == noteBodyToFind.noteKey {
                return note
            }
        }
        
        return nil
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

extension SearchNotesViewController: UITableViewDelegate,UITableViewDataSource  {
    
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
        return IS_IPAD ? 114 : 54
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("self.notesBody.count\(self.notesBody.count)")
        return self.notesBody.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tblViewNoteTitle.dequeueReusableCell(withIdentifier: "NoteTitleBLViewCell") as! NoteTitleBLViewCell
        
        let noteBody = notesBody[indexPath.row]
        print("noteBody = \(noteBody.titleName!)")
        cell.lblNoteTitle.text = noteBody.titleName!
        
        cell.btnDelete.tag = indexPath.row
        cell.btnUpdate.tag = indexPath.row
        
        let arrowIcon = UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate)
        cell.btnDelete.setImage(arrowIcon, for: .normal)
        cell.btnDelete.tintColor = ApplazAppearance.accent
        cell.btnDelete.isUserInteractionEnabled = false
        //cell.btnDelete.isHidden = true
        cell.btnUpdate.isHidden = true
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard notesBody.indices.contains(indexPath.row), notebooks.indices.contains(indexPath.row) else { return }
        let detail = NoteDetailViewController()
        detail.userId = userHashing[notebooks[indexPath.row].categoryKey ?? ""]
        detail.noteKey = notesBody[indexPath.row].noteKey
        navigationController?.pushViewController(detail, animated: true)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
extension SearchNotesViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == tapGesture && touch.view is UICollectionView && !notesBody.isEmpty{
            return false
        }
        return true
    }
}
