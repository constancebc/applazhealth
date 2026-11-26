//
//  SearchPagesViewController.swift
//  Notes
//
//  Created by Saeed Iqbal on 03/12/2023.
//  Copyright © 2023 Sevenstar Infotech. All rights reserved.
//

import UIKit

class SearchPagesViewController: UIViewController,UISearchBarDelegate {
    
    private var database = DatabaseService()
    private var activeSearch = UUID()
    
    @IBOutlet private weak var searchbar: UISearchBar!
    @IBOutlet weak var tblViewNoteDescription: UITableView!
    private var tapGesture: UITapGestureRecognizer!
    var notesBody:[NoteBody] = []
    var notebooks:[Note] = []
    var userHashing: [String : String] = [:]
    override func viewDidLoad() {
        super.viewDidLoad()
        searchbar.delegate = self
        searchbar.placeholder = "Search note text"
        self.tblViewNoteDescription.dataSource = self
        self.tblViewNoteDescription.delegate = self
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false // Allow other gestures to proceed simultaneously
        tapGesture.delegate = self // Set the delegate to manage gesture conflicts
        view.addGestureRecognizer(tapGesture)
        // Do any additional setup after loading the view.
    }
    
    @objc func dismissKeyboard() {
        if searchbar.isFirstResponder {
            searchbar.resignFirstResponder()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
    }
    
    func getNotesForSearchText(_ searchText: String) {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let request = UUID()
        activeSearch = request
        notesBody = []; notebooks = []; userHashing = [:]
        self.tblViewNoteDescription.reloadData()
        guard !query.isEmpty else { return }
        database.getAllUser { [weak self] users in
            guard let self, self.activeSearch == request else { return }
            for userID in users {
                self.database.getData(specificUserId: userID) { [weak self] fetchedNotes in
                    DispatchQueue.main.async {
                        guard let self, self.activeSearch == request else { return }
                    for note in fetchedNotes where note.isPrivateNote == false {
                        for body in note.noteBody ?? [] where (body.descriptionText ?? "").lowercased().contains(query) {
                            self.notesBody.append(body)
                            self.notebooks.append(note)
                            self.userHashing[note.categoryKey ?? ""] = userID
                        }
                    }
                        self.tblViewNoteDescription.reloadData()
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
    
    @objc func handleRefresh(refreshControl: UIRefreshControl) {
    
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        let searchText = searchBar.text ?? ""
        searchBar.resignFirstResponder()
        getNotesForSearchText(searchText)
    }
}
extension SearchPagesViewController : UITableViewDelegate,UITableViewDataSource{
    //MARK:- UITABLE VIEW DELEGATE & DATA SOURCE METHODS

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return IS_IPAD ? 35.0 : 15.0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: IS_IPAD ? 35.0 : 15.0))
        headerView.backgroundColor = .clear
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return IS_IPAD ? 35.0 : 15.0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: IS_IPAD ? 35.0 : 15.0))
        footerView.backgroundColor = .clear
        return footerView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("notesBody.count=\(notesBody.count)")
        return notesBody.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = self.tblViewNoteDescription.dequeueReusableCell(withIdentifier: "NoteDescriptionTBLViewCell") as! NoteDescriptionTBLViewCell
        let noteBody = notesBody[indexPath.row]
        cell.lblNoteTitle.text = noteBody.titleName
        cell.lblNoteDescription.attributedText = (noteBody.descriptionText!).setAttributetext(fontsize: Double(cell.lblNoteDescription.font.pointSize), fontName: "HelveticaNeue-Medium")
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard notesBody.indices.contains(indexPath.row), notebooks.indices.contains(indexPath.row) else { return }
        let detail = NoteDetailViewController()
        detail.userId = userHashing[notebooks[indexPath.row].categoryKey ?? ""]
        detail.noteKey = notesBody[indexPath.row].noteKey
        navigationController?.pushViewController(detail, animated: true)
    }
}
extension SearchPagesViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == tapGesture && touch.view is UICollectionView && !notesBody.isEmpty {
            return false
        }
        return true
    }
}
