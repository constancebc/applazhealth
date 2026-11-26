import UIKit

class SearchCustomTabController: UIViewController {
    private let searchModes = UISegmentedControl(items: ["Profiles", "Notebooks", "Notes", "Pages"])
    private let resultsContainer = UIView()
    private var searchControllers: [UIViewController] = []
    private(set) var selectedIndex = 0
    private(set) var selectedViewController: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        let storyboard = UIStoryboard(name: "Explore", bundle: nil)
        searchControllers = ["ExploreViewController", "SearchNoteBookViewController", "SearchNotesViewController", "SearchPagesViewController"].map { storyboard.instantiateViewController(withIdentifier: $0) }
        searchModes.accessibilityIdentifier = "ApplazSearchModes"
        searchModes.selectedSegmentIndex = 0
        searchModes.setTitleTextAttributes([.font: ApplazAppearance.font(13, weight: .medium), .foregroundColor: ApplazAppearance.ink], for: .normal)
        searchModes.selectedSegmentTintColor = UIColor.white.withAlphaComponent(0.85)
        searchModes.backgroundColor = ApplazAppearance.surface
        searchModes.addTarget(self, action: #selector(changeSearchMode), for: .valueChanged)
        for element in [searchModes, resultsContainer] { element.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(element) }
        NSLayoutConstraint.activate([
            searchModes.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchModes.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            searchModes.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            searchModes.heightAnchor.constraint(equalToConstant: 44),
            resultsContainer.topAnchor.constraint(equalTo: searchModes.bottomAnchor, constant: 8),
            resultsContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            resultsContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            resultsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        showSearchMode(0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    @objc private func changeSearchMode() {
        view.endEditing(true)
        showSearchMode(searchModes.selectedSegmentIndex)
    }

    private func showSearchMode(_ index: Int) {
        guard searchControllers.indices.contains(index), selectedViewController !== searchControllers[index] else { return }
        let previous = selectedViewController
        let next = searchControllers[index]
        let visible = view.window != nil
        previous?.willMove(toParent: nil)
        if visible { previous?.beginAppearanceTransition(false, animated: false) }
        previous?.view.removeFromSuperview()
        previous?.removeFromParent()
        if visible { previous?.endAppearanceTransition() }
        addChild(next)
        if visible { next.beginAppearanceTransition(true, animated: false) }
        next.view.translatesAutoresizingMaskIntoConstraints = false
        resultsContainer.addSubview(next.view)
        NSLayoutConstraint.activate([
            next.view.topAnchor.constraint(equalTo: resultsContainer.topAnchor),
            next.view.bottomAnchor.constraint(equalTo: resultsContainer.bottomAnchor),
            next.view.leadingAnchor.constraint(equalTo: resultsContainer.leadingAnchor),
            next.view.trailingAnchor.constraint(equalTo: resultsContainer.trailingAnchor)
        ])
        next.didMove(toParent: self)
        if visible { next.endAppearanceTransition() }
        selectedIndex = index
        selectedViewController = next
    }
}
