//
//  CommentsViewController.swift
//  Notes
//
//  Created by Ghullam Abbas on 01/11/2024.
//  Copyright © 2024 Sevenstar Infotech. All rights reserved.
//

protocol CommentViewControllerDelegate: AnyObject {
    func didSelectComment(note: NoteList)
}

class CommentsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let tableView = UITableView()
    private var comments: [NoteComment]
    private var note: NoteList
    weak var delegate: CommentViewControllerDelegate?
    init(comments: [NoteComment], note: NoteList) {
        self.comments = comments
        self.note = note
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        
        self.title = "Comments"
        
        // Customize navigation bar appearance
        
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
    
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.register(CommentCell.self, forCellReuseIdentifier: "CommentCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    // TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
        let comment = comments[indexPath.row]
        cell.note = note
        cell.comment = comment
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.navigateToProfile(note: note)
    }
    
    private func navigateToProfile(note: NoteList) {
        self.dismiss(animated: true) {
            if let delegate = self.delegate {
                delegate.didSelectComment(note: note)
            }
        }
    }
}
