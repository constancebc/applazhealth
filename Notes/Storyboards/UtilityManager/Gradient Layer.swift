//
//  Gradient Layer.swift
//  Whirlpost
//
//  Created by Andrei Yarash on 12/30/18.
//  Copyright © 2018 Sevenstar Infotech. All rights reserved.
//

import UIKit

/// Visual tokens only; saved appearance preferences and content are unchanged.
enum ApplazAppearance {
    static let headerFont = font(17, weight: .medium)
    static let socialIcon = UIImage(systemName: "person.2", withConfiguration: UIImage.SymbolConfiguration(pointSize: 21, weight: .regular))
    static let ink = UIColor.black
    static let accent = UIColor(red: 0.02, green: 0.06, blue: 0.26, alpha: 1)
    static let surface = UIColor(red: 0.97, green: 0.97, blue: 1.00, alpha: 0.62)
    static let outline = UIColor(red: 0.35, green: 0.40, blue: 0.61, alpha: 0.20)
    static let canvas = UIColor(red: 0.92, green: 0.94, blue: 0.99, alpha: 1)

    static func font(_ size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let face: String
        switch weight {
        case .bold, .heavy, .black, .semibold: face = "AvenirNext-DemiBold"
        case .medium: face = "AvenirNext-Medium"
        default: face = "AvenirNext-Regular"
        }
        return UIFont(name: face, size: size) ?? UIFont.systemFont(ofSize: size, weight: weight)
    }

    static func install() {
        let navigation = UINavigationBarAppearance()
        navigation.configureWithDefaultBackground()
        navigation.backgroundColor = surface
        navigation.titleTextAttributes = [.font: headerFont, .foregroundColor: ink]
        navigation.largeTitleTextAttributes = [.font: font(32, weight: .semibold), .foregroundColor: ink]
        UINavigationBar.appearance().standardAppearance = navigation
        UINavigationBar.appearance().scrollEdgeAppearance = navigation
        UINavigationBar.appearance().compactAppearance = navigation
        UIBarButtonItem.appearance().setTitleTextAttributes([.font: font(16, weight: .medium)], for: .normal)

        let tabs = UITabBarAppearance()
        tabs.configureWithDefaultBackground()
        tabs.backgroundColor = surface
        for item in [tabs.stackedLayoutAppearance, tabs.inlineLayoutAppearance, tabs.compactInlineLayoutAppearance] {
            item.normal.titleTextAttributes = [.font: font(11)]
            item.selected.titleTextAttributes = [.font: font(11, weight: .medium)]
        }
        UITabBar.appearance().standardAppearance = tabs
        if #available(iOS 15.0, *) { UITabBar.appearance().scrollEdgeAppearance = tabs }
    }
}

/// A quiet background behind existing screen content. No added views or hit regions.
class ApplazSurfaceView: UIView {
    override class var layerClass: AnyClass { return CAGradientLayer.self }
    private let light = CAGradientLayer()
    private let atmosphere = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLight()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureLight()
    }

    private func configureLight() {
        guard let gradient = layer as? CAGradientLayer else { return }
        gradient.colors = [
            UIColor(red: 0.83, green: 0.89, blue: 0.99, alpha: 1).cgColor,
            UIColor(red: 1.00, green: 0.87, blue: 0.77, alpha: 1).cgColor,
            UIColor(red: 0.89, green: 0.88, blue: 0.98, alpha: 1).cgColor
        ]
        gradient.locations = [0, 0.52, 1]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0.95, y: 1)

        light.type = .radial
        light.colors = [UIColor.white.withAlphaComponent(0.85).cgColor, UIColor.white.withAlphaComponent(0).cgColor]
        light.locations = [0, 1]
        light.startPoint = CGPoint(x: 0.5, y: 0.5)
        light.endPoint = CGPoint(x: 1, y: 1)
        atmosphere.type = .radial
        atmosphere.colors = [UIColor(red: 0.56, green: 0.64, blue: 0.91, alpha: 0.22).cgColor, UIColor.clear.cgColor]
        atmosphere.startPoint = CGPoint(x: 0.5, y: 0.5)
        atmosphere.endPoint = CGPoint(x: 1, y: 1)
        gradient.insertSublayer(atmosphere, at: 0)
        gradient.insertSublayer(light, at: 1)
        layer.masksToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        light.frame = CGRect(x: -bounds.width * 0.4, y: bounds.height * 0.03, width: bounds.width * 1.8, height: bounds.height * 0.78)
        atmosphere.frame = CGRect(x: bounds.width * 0.05, y: bounds.height * 0.53, width: bounds.width * 1.6, height: bounds.height * 0.65)
        CATransaction.commit()
    }
}

/// Keeps the existing field, delegate, security traits, and keyboard behavior.
/// Keeps the color field continuous behind an existing opaque table surface.
class ApplazAlignedBackdropView: UIView {
    private let canvas = ApplazSurfaceView(frame: .zero)

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        clipsToBounds = true
        addSubview(canvas)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isUserInteractionEnabled = false
        clipsToBounds = true
        addSubview(canvas)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let reference = (window as UIView?) ?? superview else { return }
        let origin = convert(CGPoint.zero, to: reference)
        canvas.frame = CGRect(x: -origin.x, y: -origin.y, width: reference.bounds.width, height: reference.bounds.height)
    }
}

class ApplazSymbolView: UIImageView {
    @IBInspectable var symbolName: String = ""

    override func awakeFromNib() {
        super.awakeFromNib()
        image = UIImage(systemName: symbolName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)) ?? image
        tintColor = ApplazAppearance.accent.withAlphaComponent(0.75)
        contentMode = .scaleAspectFit
    }
}

class ApplazIconButton: UIButton {
    @IBInspectable var symbolName: String = ""

    override func awakeFromNib() {
        super.awakeFromNib()
        let configuration = UIImage.SymbolConfiguration(pointSize: 21, weight: .regular)
        if let symbol = UIImage(systemName: symbolName, withConfiguration: configuration) {
            setImage(symbol, for: .normal)
        }
        imageView?.contentMode = .scaleAspectFit
        tintColor = ApplazAppearance.accent
    }
}

class ApplazTextField: UITextField {
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.white.withAlphaComponent(0.38)
        textColor = ApplazAppearance.ink
        tintColor = ApplazAppearance.accent
        layer.cornerRadius = 12
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.9).cgColor
        if let placeholder = placeholder {
            attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [
                .foregroundColor: ApplazAppearance.ink.withAlphaComponent(0.55),
                .font: font ?? ApplazAppearance.font(16)
            ])
        }
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return super.textRect(forBounds: bounds.insetBy(dx: 12, dy: 0))
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return super.editingRect(forBounds: bounds.insetBy(dx: 12, dy: 0))
    }
}

/// Draws a native action surface inside the original, unchanged touch target.
class ApplazPrimaryButton: UIButton {
    @IBInspectable var actionTitle: String = "" {
        didSet { setTitle(actionTitle, for: .normal) }
    }
    private let actionSurface = CAGradientLayer()

    override func awakeFromNib() {
        super.awakeFromNib()
        setBackgroundImage(nil, for: .normal)
        setBackgroundImage(nil, for: .highlighted)
        setTitle(actionTitle, for: .normal)
        setTitleColor(.white, for: .normal)
        setTitleColor(UIColor.white.withAlphaComponent(0.85), for: .disabled)
        titleLabel?.font = ApplazAppearance.font(18, weight: .medium)
        contentVerticalAlignment = .center
        accessibilityLabel = actionTitle
        actionSurface.cornerRadius = 16
        actionSurface.cornerCurve = .continuous
        actionSurface.borderWidth = 1
        actionSurface.borderColor = UIColor.white.withAlphaComponent(0.55).cgColor
        actionSurface.startPoint = CGPoint(x: 0, y: 0)
        actionSurface.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(actionSurface, at: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let verticalInset = max(0, (bounds.height - 56) / 2)
        actionSurface.frame = bounds.insetBy(dx: 0, dy: verticalInset)
        let opacity: CGFloat = isEnabled ? 1 : 0.60
        actionSurface.colors = [
            UIColor(red: 0.11, green: 0.18, blue: 0.39, alpha: opacity).cgColor,
            UIColor(red: 0.28, green: 0.26, blue: 0.46, alpha: opacity).cgColor
        ]
        CATransaction.commit()
    }

    override var isEnabled: Bool { didSet { setNeedsLayout() } }
    override var isHighlighted: Bool { didSet { actionSurface.opacity = isHighlighted ? 0.8 : 1 } }
}
@IBDesignable
class Gradient:UIView {
    
    @IBInspectable var firstColor:UIColor = UIColor.clear{
        didSet {
            updateView()
        }
    }
    
    
    @IBInspectable var secondColor:UIColor = UIColor.clear{
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var isHorizontal:Bool = true {
        didSet {
            updateView()
        }
    }
    
    override class var layerClass: AnyClass {
        get {
            return CAGradientLayer.self
        }
    }
    
    
    func updateView() {
        
        updateColor()
    }
    
    func updateColor() {
        
        let defaults = UserDefaults.standard
        
        let colorIndex = defaults.integer(forKey: MYTHEMECOLORINDEX)
        
        print(colorIndex)
//        
        var mythemecolor1 = mythemeColor0_1
        var mythemecolor2 = mythemeColor0_2
        
        switch (colorIndex) {
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
        var myfirstColor = UIColor(rgb: mythemecolor1).withAlphaComponent(0.0)
        if colorIndex == 5 {
            myfirstColor = UIColor(rgb: mythemecolor1).withAlphaComponent(1.0)
        }
        let mysecondColor = UIColor(rgb: mythemecolor2).withAlphaComponent(1.0)
        */
        //let layer = self.layer as! CAGradientLayer
        //layer.colors = [myfirstColor,mysecondColor].map({$0.cgColor})
        
        if (self.isHorizontal) {
            //layer.startPoint = CGPoint(x: 0, y: 1)
            //layer.endPoint = CGPoint(x: 1, y: 0.0)
        } else {
            // handler this part if we want vertically
        }
        
        
    }
    
    /*
    func updateView() {
        let layer = self.layer as! CAGradientLayer
        layer.colors = [firstColor,secondColor].map({$0.cgColor})
        
        if (self.isHorizontal) {
            layer.startPoint = CGPoint(x: 0, y: 1)
            layer.endPoint = CGPoint(x: 1, y: 0.5)
        } else {
            // handler this part if we want vertically
        }
    }*/
}

// Shared spacing and typography for the existing authentication controls.
enum ApplazAuthLayout {
    static func install(in root: UIView, fields: [UITextField], primary: UIButton, terms: UILabel, signingUp: Bool) {
        func descendants(_ view: UIView) -> [UIView] { view.subviews.flatMap { [$0] + descendants($0) } }
        let original = descendants(root)
        guard let scroll = original.compactMap({ $0 as? UIScrollView }).first,
              let logo = original.compactMap({ $0 as? UIImageView }).first(where: { $0.bounds.width > 100 && $0.bounds.height < 150 && !$0.isHidden }) else { return }
        let buttons = original.compactMap { $0 as? UIButton }
        let secondary = buttons.first { $0 != primary && (($0.title(for: .normal) ?? $0.attributedTitle(for: .normal)?.string ?? "").lowercased().contains(signingUp ? "sign in" : "sign up")) }
        let guest = buttons.first { ($0.title(for: .normal) ?? "").contains("Guest") }
        let forgot = buttons.first { ($0.title(for: .normal) ?? "").contains("Forgot") }
        let prompt = original.compactMap { $0 as? UILabel }.first { ($0.text ?? "").contains("account?") }
        let kept: [UIView] = [logo, primary, terms] + fields + [secondary, guest, forgot, prompt].compactMap { $0 }
        let oldViews = Set(original.map(ObjectIdentifier.init))
        NSLayoutConstraint.deactivate(root.constraints.filter { constraint in
            [constraint.firstItem, constraint.secondItem].contains { item in
                guard let view = item as? UIView else { return false }
                return oldViews.contains(ObjectIdentifier(view))
            }
        })
        for view in original { NSLayoutConstraint.deactivate(view.constraints) }
        kept.forEach { $0.removeFromSuperview() }
        scroll.subviews.forEach { $0.removeFromSuperview() }
        root.subviews.filter { $0 != scroll }.forEach { $0.removeFromSuperview() }
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.isScrollEnabled = true
        scroll.alwaysBounceHorizontal = false
        scroll.alwaysBounceVertical = false
        scroll.showsHorizontalScrollIndicator = false
        let column = UIStackView()
        column.axis = .vertical
        column.spacing = 20
        column.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(column)
        let logoBox = UIView()
        logo.translatesAutoresizingMaskIntoConstraints = false
        logoBox.addSubview(logo)
        logo.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            logoBox.heightAnchor.constraint(equalToConstant: 88),
            logo.centerXAnchor.constraint(equalTo: logoBox.centerXAnchor),
            logo.centerYAnchor.constraint(equalTo: logoBox.centerYAnchor),
            logo.widthAnchor.constraint(equalTo: logoBox.widthAnchor, multiplier: 0.72),
            logo.heightAnchor.constraint(equalToConstant: 68)
        ])
        column.addArrangedSubview(logoBox)
        let heading = UILabel()
        heading.text = signingUp ? "Create your account" : "Welcome back"
        heading.font = ApplazAppearance.font(24, weight: .medium)
        heading.textColor = ApplazAppearance.ink
        heading.textAlignment = .center
        column.addArrangedSubview(heading)
        column.setCustomSpacing(32, after: heading)
        let form = UIStackView()
        form.axis = .vertical
        form.spacing = 16
        for (index, field) in fields.enumerated() {
            field.translatesAutoresizingMaskIntoConstraints = false
            field.font = ApplazAppearance.font(16)
            field.textColor = ApplazAppearance.ink
            let title = signingUp && index == 0 ? "Username" : (field.isSecureTextEntry ? "Password" : "Email address")
            field.attributedPlaceholder = NSAttributedString(string: title, attributes: [.font: ApplazAppearance.font(16), .foregroundColor: ApplazAppearance.ink.withAlphaComponent(0.5)])
            form.addArrangedSubview(field)
            field.heightAnchor.constraint(equalToConstant: 52).isActive = true
        }
        column.addArrangedSubview(form)
        func styleLink(_ button: UIButton, title: String? = nil) {
            let text = title ?? button.title(for: .normal) ?? button.attributedTitle(for: .normal)?.string ?? ""
            button.setAttributedTitle(nil, for: .normal)
            button.setTitle(text, for: .normal)
            button.titleLabel?.font = ApplazAppearance.font(16, weight: .medium)
            button.contentHorizontalAlignment = .center
            button.setTitleColor(ApplazAppearance.ink, for: .normal)
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
        if let forgot {
            styleLink(forgot)
            forgot.contentHorizontalAlignment = .trailing
            column.addArrangedSubview(forgot)
            column.setCustomSpacing(12, after: form)
            column.setCustomSpacing(12, after: forgot)
        }
        primary.setAttributedTitle(nil, for: .normal)
        primary.setTitle(signingUp ? "Sign Up" : "Sign In", for: .normal)
        primary.titleLabel?.font = ApplazAppearance.font(18, weight: .medium)
        primary.heightAnchor.constraint(equalToConstant: 56).isActive = true
        column.addArrangedSubview(primary)
        if let guest { styleLink(guest, title: "Continue as guest"); column.addArrangedSubview(guest) }
        let footer = UIStackView()
        footer.axis = .vertical
        footer.spacing = 0
        if let prompt {
            prompt.font = ApplazAppearance.font(15)
            prompt.textColor = ApplazAppearance.ink.withAlphaComponent(0.72)
            prompt.textAlignment = .center
            prompt.numberOfLines = 0
            footer.addArrangedSubview(prompt)
        }
        if let secondary { styleLink(secondary, title: signingUp ? "Sign In" : "Sign Up"); footer.addArrangedSubview(secondary) }
        column.addArrangedSubview(footer)
        let text = "By continuing, you agree to our Terms"
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 4
        let attributed = NSMutableAttributedString(string: text, attributes: [.font: ApplazAppearance.font(13), .foregroundColor: ApplazAppearance.ink.withAlphaComponent(0.65), .paragraphStyle: paragraph])
        attributed.addAttributes([.underlineStyle: NSUnderlineStyle.single.rawValue, .foregroundColor: ApplazAppearance.ink], range: (text as NSString).range(of: "Terms"))
        terms.attributedText = attributed
        terms.numberOfLines = 0
        column.addArrangedSubview(terms)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: root.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: root.safeAreaLayoutGuide.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            column.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 32),
            column.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -32),
            column.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 24),
            column.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -24),
            column.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -48)
        ])
    }
}

final class NewNotebookViewController: UIViewController {
    var onCreate: ((String, Bool) -> Void)?
    var existingNotebooks: [Note] = []
    var onSelectExisting: ((Note) -> Void)?
    var onSelectPrivateNotebook: ((String) -> Void)?
    private var selectedTemplate = WellnessTemplate.blank
    private let templateButton = UIButton(type: .system)
    private let templateDescription = UILabel()
    private let checklistControl = UISegmentedControl(items: ["Text", "Checklist"])
    let nameField = UITextField()
    let visibilityControl = UISegmentedControl(items: ["Public", "Private"])
    private let visibilityDescription = UILabel()
    private let createButton = UIButton(type: .system)

    override func loadView() { view = ApplazSurfaceView(frame: .zero) }

    override func viewDidLoad() {
        super.viewDidLoad()
        let scroll = UIScrollView()
        scroll.keyboardDismissMode = .interactive
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        scroll.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(stack)
        let heading = UILabel()
        heading.text = "New notebook"
        heading.font = ApplazAppearance.headerFont
        heading.textColor = ApplazAppearance.ink
        let subtitle = templateDescription
        subtitle.text = "Name it. Choose a template and who can see it."
        subtitle.font = ApplazAppearance.font(15)
        subtitle.textColor = ApplazAppearance.ink.withAlphaComponent(0.75)
        subtitle.numberOfLines = 0
        nameField.placeholder = "Notebook name"
        nameField.accessibilityIdentifier = "NewNotebookName"
        nameField.font = ApplazAppearance.font(17)
        nameField.textColor = ApplazAppearance.ink
        nameField.backgroundColor = ApplazAppearance.surface
        nameField.layer.cornerRadius = 14
        nameField.layer.borderWidth = 1
        nameField.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
        nameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        nameField.leftViewMode = .always
        nameField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        nameField.rightViewMode = .always
        nameField.autocapitalizationType = .sentences
        nameField.returnKeyType = .done
        nameField.addTarget(self, action: #selector(updateCreateButton), for: .editingChanged)
        nameField.addTarget(self, action: #selector(createNotebook), for: .primaryActionTriggered)
        let visibilityLabel = UILabel()
        visibilityLabel.text = "Notebook visibility"
        visibilityLabel.font = ApplazAppearance.font(15, weight: .medium)
        visibilityLabel.textColor = ApplazAppearance.ink
        visibilityControl.accessibilityIdentifier = "NewNotebookVisibility"
        visibilityControl.selectedSegmentIndex = 0
        visibilityControl.selectedSegmentTintColor = UIColor.white.withAlphaComponent(0.9)
        visibilityControl.backgroundColor = ApplazAppearance.surface
        visibilityControl.setTitleTextAttributes([.font: ApplazAppearance.font(16, weight: .medium), .foregroundColor: ApplazAppearance.ink], for: .normal)
        visibilityControl.addTarget(self, action: #selector(updateVisibilityDescription), for: .valueChanged)
        visibilityDescription.font = ApplazAppearance.font(14)
        visibilityDescription.textColor = ApplazAppearance.ink.withAlphaComponent(0.75)
        visibilityDescription.numberOfLines = 0
        visibilityDescription.accessibilityIdentifier = "NotebookVisibilityExplanation"
        updateVisibilityDescription()
        createButton.setTitle("Create notebook", for: .normal)
        createButton.accessibilityIdentifier = "CreateNotebook"
        createButton.setTitleColor(.white, for: .normal)
        createButton.titleLabel?.font = ApplazAppearance.font(17, weight: .medium)
        createButton.backgroundColor = ApplazAppearance.ink
        createButton.layer.cornerRadius = 14
        createButton.addTarget(self, action: #selector(createNotebook), for: .touchUpInside)
        let cancel = UIButton(type: .system)
        cancel.setTitle("Cancel", for: .normal)
        cancel.titleLabel?.font = ApplazAppearance.font(16)
        cancel.tintColor = ApplazAppearance.accent
        cancel.addTarget(self, action: #selector(cancelCreation), for: .touchUpInside)
        visibilityControl.accessibilityLabel = "Notebook visibility"
        let actions = UIStackView(arrangedSubviews: [cancel, createButton])
        actions.spacing = 12
        cancel.widthAnchor.constraint(equalToConstant: 90).isActive = true
        for element in [heading, subtitle, nameField, visibilityControl, visibilityDescription, actions] { stack.addArrangedSubview(element) }
        templateButton.setTitle("Template · Blank notebook  ⌄", for: .normal)
        templateButton.tintColor = .black
        templateButton.showsMenuAsPrimaryAction = true
        refreshTemplateMenu()
        checklistControl.selectedSegmentIndex = 0
        checklistControl.addTarget(self, action: #selector(updateChecklistPrivacy), for: .valueChanged)
        stack.insertArrangedSubview(templateButton, at: 3)
        stack.insertArrangedSubview(checklistControl, at: 4)
        if onSelectExisting != nil {
            let divider = UILabel()
            divider.text = "Or add a note to an existing notebook"
            divider.font = ApplazAppearance.font(15, weight: .medium)
            divider.textColor = ApplazAppearance.ink
            divider.numberOfLines = 0
            let existing = UIButton(type: .system)
            var config = UIButton.Configuration.bordered()
            config.title = existingNotebooks.isEmpty && WellnessStore.shared.notebooks.isEmpty ? "No existing notebooks yet" : "Choose an existing notebook"
            config.image = UIImage(systemName: "chevron.down")
            config.imagePlacement = .trailing
            config.imagePadding = 12
            config.baseForegroundColor = ApplazAppearance.ink
            config.baseBackgroundColor = ApplazAppearance.surface
            config.cornerStyle = .medium
            existing.configuration = config
            existing.accessibilityIdentifier = "ChooseExistingNotebook"
            existing.showsMenuAsPrimaryAction = true
            existing.isEnabled = !existingNotebooks.isEmpty || !WellnessStore.shared.notebooks.isEmpty
            let regularActions = existingNotebooks.map { notebook in
                UIAction(title: notebook.categoryName ?? "Notebook", image: UIImage(systemName: notebook.isPrivateNote == true ? "lock" : "book.closed")) { [weak self] _ in
                    guard let self else { return }
                    self.dismiss(animated: true) { self.onSelectExisting?(notebook) }
                }
            }
            let privateActions = WellnessStore.shared.notebooks.map { notebook in
                UIAction(title: notebook.name + (notebook.isPrivate == false ? " · Public" : " · Private"), image: UIImage(systemName: notebook.isPrivate == false ? "globe" : "lock")) { [weak self] _ in
                    guard let self else { return }
                    self.dismiss(animated: true) { self.onSelectPrivateNotebook?(notebook.id) }
                }
            }
            existing.menu = UIMenu(children: regularActions + privateActions)
            stack.setCustomSpacing(24, after: actions)
            stack.addArrangedSubview(divider)
            stack.addArrangedSubview(existing)
            existing.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            scroll.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -48),
            nameField.heightAnchor.constraint(equalToConstant: 52),
            visibilityControl.heightAnchor.constraint(equalToConstant: 44),
            createButton.heightAnchor.constraint(equalToConstant: 50),
            cancel.heightAnchor.constraint(equalToConstant: 44)
        ])
        updateCreateButton()
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.selectedDetentIdentifier = .medium
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
    }

    private func refreshTemplateMenu() {
        templateButton.menu = UIMenu(children: WellnessTemplate.allCases.map { template in
            UIAction(title: template.rawValue, image: UIImage(systemName: template.symbol), state: selectedTemplate == template ? .on : .off) { [weak self] _ in
                self?.selectTemplate(template)
            }
        })
    }
    func selectTemplate(_ template: WellnessTemplate) {
        selectedTemplate = template
        checklistControl.isEnabled = template == .blank
        templateButton.setTitle("Template · " + template.rawValue + "  ⌄", for: .normal)
        templateDescription.text = template.summary
        templateDescription.accessibilityIdentifier = "TemplateDescription"
        checklistControl.selectedSegmentIndex = template == .blank ? 0 : 1
        visibilityControl.isEnabled = true
        updateVisibilityDescription()
        refreshTemplateMenu()
    }
    @objc private func updateChecklistPrivacy() {
        visibilityControl.isEnabled = true
        updateVisibilityDescription()
    }
    @objc private func updateVisibilityDescription() {
        nameField.resignFirstResponder()
        visibilityDescription.text = visibilityControl.selectedSegmentIndex == 0
            ? "Public notes can appear in Newsfeed. Meal logs, dated health reflections and AI chats stay private."
            : "Private notebooks are visible only to you."
    }

    @objc private func updateCreateButton() {
        createButton.isEnabled = !(nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        createButton.alpha = createButton.isEnabled ? 1 : 0.5
    }

    @objc private func createNotebook() {
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let isPrivate = visibilityControl.selectedSegmentIndex == 1
        if selectedTemplate != .blank || checklistControl.selectedSegmentIndex == 1 {
            let id = WellnessStore.shared.create(selectedTemplate, name: name)
            if var notebook = WellnessStore.shared.notebooks.first(where: { $0.id == id }) {
                notebook.isPrivate = isPrivate
                if selectedTemplate == .blank {
                    notebook.kind = "checklist"
                    notebook.notes = [WellnessTextNote(title: "My checklist", body: "", isChecklist: true)]
                }
                WellnessStore.shared.update(notebook)
            }
        } else { onCreate?(name, isPrivate) }
        dismiss(animated: true)
    }

    @objc private func cancelCreation() { dismiss(animated: true) }
}

/// Enables edge back with hidden bars while protecting navigation roots.
final class ApplazBackSwipeGuard: NSObject, UIGestureRecognizerDelegate {
    weak var navigation: UINavigationController?
    func install(on navigation: UINavigationController?) {
        self.navigation = navigation
        navigation?.interactivePopGestureRecognizer?.delegate = self
        navigation?.interactivePopGestureRecognizer?.isEnabled = true
        if #available(iOS 26.0, *) {
            navigation?.interactiveContentPopGestureRecognizer?.delegate = self
            navigation?.interactiveContentPopGestureRecognizer?.isEnabled = true
        }
    }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let navigation else { return false }
        guard navigation.viewControllers.count > 1, navigation.transitionCoordinator == nil,
              navigation.visibleViewController?.presentedViewController == nil else { return false }
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = pan.translation(in: navigation.view)
            let movement = abs(translation.x) + abs(translation.y) > 1 ? translation : pan.velocity(in: navigation.view)
            let rightToLeft = navigation.view.effectiveUserInterfaceLayoutDirection == .rightToLeft
            guard abs(movement.x) > abs(movement.y), rightToLeft ? movement.x < 0 : movement.x > 0 else { return false }
            if #available(iOS 26.0, *), gestureRecognizer === navigation.interactiveContentPopGestureRecognizer {
                let startX = pan.location(in: navigation.view).x - pan.translation(in: navigation.view).x
                guard rightToLeft ? startX >= navigation.view.bounds.width - 44 : startX <= 44 else { return false }
            }
        }
        return true
    }
}
