//
//  SecondViewController.swift
//  Mustage
//
//  Created by Oleg Baidalka on 13/03/2017.
//  Copyright © 2017 Oleg Baidalka. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuthUI
import FirebaseDatabaseUI

class RecentsViewController: UITableViewController {

    var dataSource: FUITableViewDataSource?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Messages"
        tableView.backgroundView = ApplazAlignedBackdropView(frame: tableView.bounds)
        tableView.backgroundColor = .clear
        tableView.rowHeight = 84
        tableView.separatorColor = ApplazAppearance.outline
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 74, bottom: 0, right: 20)
        
        if let current = Auth.currentID {
            let ref = Database.database().reference(withPath: kDataChatsKey).child(current)
            
            let array = FUISortedArray(query: ref, delegate: nil) { (snap1, snap2) -> ComparisonResult in
                let upd1 = snap1.intValue("updated") ?? 0
                let upd2 = snap2.intValue("updated") ?? 0
                
                if upd1 > upd2 {
                    return .orderedAscending
                } else if upd1 < upd2 {
                    return .orderedDescending
                } else {
                    return .orderedSame
                }
            }
            
            dataSource = FUITableViewDataSource(collection: array, populateCell: { (tableView, indexPath, chat) -> UITableViewCell in
                
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? ChatTableViewCell else {
                    return UITableViewCell()
                }
                
                cell.chat = chat.ref
                
                return cell
            })
            
            dataSource?.bind(to: self.tableView)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        SocialUserModel.current?.ref.child("unread").removeValue()
        // reset unread count
        self.navigationController?.tabBarItem.badgeValue = nil
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let chatController = segue.destination as? ChatViewController,
            let selectedIndex = self.tableView.indexPathForSelectedRow {
            let ref = self.dataSource?.items[selectedIndex.row].ref
            if let cell = self.tableView.cellForRow(at: selectedIndex) as? ChatTableViewCell {
                chatController.recipientName = cell.contactName?.text ?? "Conversation"
            }
            chatController.chatRef = ref
        }
    }

}
