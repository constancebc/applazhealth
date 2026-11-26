//
//  NotificationViewController.swift
//  Notes
//
//  Created by Ghullam Abbas on 02/11/2024.
//  Copyright © 2024 Sevenstar Infotech. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class NotificationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // Sample notifications array
    var notifications =  [NotificationList]()
    var currentUser: SocialUserModel? = SocialUserModel.current
    // Table view
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(NotificationCell.self, forCellReuseIdentifier: NotificationCell.identifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        return tableView
    }()

    private var database = DatabaseService()
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshInbox), name: ApplazActivityInbox.changed, object: nil)
        ApplazActivityInbox.shared.start()
        setupTableView()
        setupLayout()
        
        title = "Notifications"
        view.backgroundColor = ApplazAppearance.surface
        tableView.backgroundColor = .clear
        refreshInbox()
        
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupLayout() {
        view.addSubview(tableView)
        
        // Set table view constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    deinit { NotificationCenter.default.removeObserver(self) }
    @objc private func refreshInbox() {
        let uid = Auth.auth().currentUser?.uid
        notifications = ApplazActivityInbox.shared.notifications.filter { $0.recipientID == uid }
        tableView.reloadData()
        let empty = UILabel(); empty.text = "No notifications yet"; empty.textAlignment = .center; empty.textColor = .secondaryLabel
        tableView.backgroundView = notifications.isEmpty ? empty : nil
    }
    func getNotificationData() { refreshInbox() }

    // MARK: - UITableViewDelegate and UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NotificationCell.identifier, for: indexPath) as? NotificationCell else {
            return UITableViewCell()
        }
        
        let notification = notifications[indexPath.row]
        cell.configure(with: notification)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let notification = notifications[indexPath.row]
        guard let uid = Auth.auth().currentUser?.uid, notification.recipientID == uid else { return }
        let detail = NoteDetailViewController()
        detail.userId = uid
        detail.noteKey = notification.noteKey
        navigationController?.pushViewController(detail, animated: true)
    }

    func navigateToProfile(note: NoteList) {
        let storyBoard = UIStoryboard(name: "Profile", bundle: nil)
        
        let vc = storyBoard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        vc.noteListObject = note
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
