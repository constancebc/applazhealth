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
        backgroundColor = .clear
        setTitleColor(ApplazAppearance.ink, for: .normal)
        setTitleColor(ApplazAppearance.ink.withAlphaComponent(0.4), for: .disabled)
        titleLabel?.font = ApplazAppearance.font(18, weight: .medium)
        contentVerticalAlignment = .center
        accessibilityLabel = actionTitle
        actionSurface.cornerRadius = 28
        actionSurface.cornerCurve = .continuous
        actionSurface.borderWidth = 1
        actionSurface.borderColor = ApplazAppearance.accent.withAlphaComponent(0.16).cgColor
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
            UIColor.white.withAlphaComponent(0.66 * opacity).cgColor,
            UIColor(red: 0.91, green: 0.89, blue: 0.98, alpha: 0.40 * opacity).cgColor
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
    var onFinish: (() -> Void)?
    var existingNotebooks: [Note] = []
    var onSelectExisting: ((Note) -> Void)?
    var onSelectPrivateNotebook: ((String) -> Void)?
    private var selectedTemplate = WellnessTemplate.blank
    private let templateButton = UIButton(type: .system)
    private var templateMenuOverlay: UIControl?
    private let templateDescription = UILabel()
    private let checklistControl = UISegmentedControl(items: ["Notes", "Checklist"])
    let nameField = UITextField()
    let visibilityControl = UISegmentedControl(items: ["Public", "Private"])
    private let visibilityDescription = UILabel()
    private let createButton = UIButton(type: .system)
    private let inviteFriendsButton = UIButton(type: .system)
    private var selectedCollaborators: [CollaborationPerson] = []
    private var createdCollaborativeNotebookID: String?

    override func loadView() { view = ApplazSurfaceView(frame: .zero) }

    override func viewDidLoad() {
        super.viewDidLoad()
        let scroll = UIScrollView()
        scroll.keyboardDismissMode = .interactive
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
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
        subtitle.isHidden = true
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
        visibilityDescription.isHidden = true
        visibilityDescription.accessibilityIdentifier = "NotebookVisibilityExplanation"
        updateVisibilityDescription()
        createButton.setTitle("Create notebook", for: .normal)
        createButton.accessibilityIdentifier = "CreateNotebook"
        createButton.setTitleColor(ApplazAppearance.ink, for: .normal)
        createButton.setTitleColor(ApplazAppearance.ink.withAlphaComponent(0.45), for: .disabled)
        createButton.titleLabel?.font = ApplazAppearance.font(17, weight: .medium)
        createButton.backgroundColor = UIColor.white.withAlphaComponent(0.58)
        createButton.layer.cornerRadius = 23
        createButton.layer.borderWidth = 1
        createButton.layer.borderColor = ApplazAppearance.accent.withAlphaComponent(0.16).cgColor
        createButton.addTarget(self, action: #selector(createNotebook), for: .touchUpInside)
        let cancel = UIButton(type: .system)
        cancel.setTitle("Cancel", for: .normal)
        cancel.titleLabel?.font = ApplazAppearance.font(16)
        cancel.tintColor = ApplazAppearance.accent
        cancel.addTarget(self, action: #selector(cancelCreation), for: .touchUpInside)
        visibilityControl.accessibilityLabel = "Notebook visibility"
        cancel.setTitle(nil, for: .normal)
        cancel.setImage(UIImage(systemName: "xmark"), for: .normal)
        cancel.accessibilityLabel = "Cancel"
        cancel.widthAnchor.constraint(equalToConstant: 32).isActive = true
        let header = UIStackView(arrangedSubviews: [heading, cancel])
        header.alignment = .center
        let actions = UIStackView(arrangedSubviews: [createButton])
        templateButton.accessibilityIdentifier = "NotebookTemplate"
        templateButton.contentHorizontalAlignment = .leading
        templateButton.titleLabel?.font = ApplazAppearance.font(17)
        templateButton.tintColor = ApplazAppearance.ink
        templateButton.backgroundColor = ApplazAppearance.surface
        templateButton.layer.cornerRadius = 12
        templateButton.layer.borderWidth = 1
        templateButton.layer.borderColor = ApplazAppearance.accent.withAlphaComponent(0.18).cgColor
        templateButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 42)
        let templateChevron = UIImageView(image: UIImage(systemName: "chevron.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)))
        templateChevron.tintColor = ApplazAppearance.accent
        templateChevron.contentMode = .scaleAspectFit
        templateChevron.translatesAutoresizingMaskIntoConstraints = false
        templateButton.addSubview(templateChevron)
        NSLayoutConstraint.activate([
            templateChevron.trailingAnchor.constraint(equalTo: templateButton.trailingAnchor, constant: -14),
            templateChevron.centerYAnchor.constraint(equalTo: templateButton.centerYAnchor),
            templateChevron.widthAnchor.constraint(equalToConstant: 18),
            templateChevron.heightAnchor.constraint(equalToConstant: 18)
        ])
        templateButton.addTarget(self, action: #selector(showTemplateChoices), for: .touchUpInside)
        refreshTemplateMenu()
        checklistControl.selectedSegmentIndex = 0
        checklistControl.accessibilityIdentifier = "NotebookLayout"
        checklistControl.addTarget(self, action: #selector(updateChecklistPrivacy), for: .valueChanged)
        for control in [checklistControl, visibilityControl] {
            control.selectedSegmentTintColor = .white
            control.backgroundColor = ApplazAppearance.accent.withAlphaComponent(0.06)
            control.setTitleTextAttributes([.font: ApplazAppearance.font(15), .foregroundColor: ApplazAppearance.ink], for: .normal)
        }
        func row(_ title: String, _ control: UIView) -> UIStackView {
            let label = UILabel()
            label.text = title
            label.font = ApplazAppearance.font(15)
            label.textColor = ApplazAppearance.ink
            label.widthAnchor.constraint(equalToConstant: 66).isActive = true
            let row = UIStackView(arrangedSubviews: [label, control])
            row.spacing = 10
            row.alignment = .center
            control.heightAnchor.constraint(equalToConstant: 42).isActive = true
            return row
        }
        inviteFriendsButton.setTitle("Invite friends", for: .normal)
        inviteFriendsButton.setImage(UIImage(systemName: "person.badge.plus"), for: .normal)
        inviteFriendsButton.tintColor = ApplazAppearance.accent
        inviteFriendsButton.titleLabel?.font = ApplazAppearance.font(15)
        inviteFriendsButton.accessibilityIdentifier = "NewNotebookFriends"
        inviteFriendsButton.addTarget(self, action: #selector(chooseCollaborators), for: .touchUpInside)
        for element in [header, row("Name", nameField), row("Template", templateButton), row("Layout", checklistControl), row("Visibility", visibilityControl), row("Friends", inviteFriendsButton), actions] {
            stack.addArrangedSubview(element)
        }
        stack.setCustomSpacing(20, after: header)
        if onSelectExisting != nil {
            let divider = UILabel()
            divider.text = "Or add a note to an existing notebook"
            divider.font = ApplazAppearance.font(15, weight: .medium)
            divider.textColor = ApplazAppearance.ink
            divider.numberOfLines = 0
            let existing = UIButton(type: .system)
            var config = UIButton.Configuration.bordered()
            config.title = existingNotebooks.isEmpty && WellnessStore.shared.notebooks.isEmpty ? "No existing notebooks yet" : "Add to an existing notebook"
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
            stack.setCustomSpacing(8, after: actions)
            stack.addArrangedSubview(existing)
            existing.heightAnchor.constraint(equalToConstant: 44).isActive = true
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
            createButton.heightAnchor.constraint(equalToConstant: 46),
            cancel.heightAnchor.constraint(equalToConstant: 32)
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

    private func templateTitle(_ template: WellnessTemplate) -> String {
        switch template {
        case .blank: return "Blank notebook"
        case .goals: return "Goals"
        case .wellness: return "Routine checklist"
        case .workout: return "Workout checklist"
        case .food: return "Food diary"
        case .training: return "Fitness training"
        }
    }
    private func refreshTemplateMenu() {
        templateButton.setTitle(templateTitle(selectedTemplate), for: .normal)
        templateButton.accessibilityHint = selectedTemplate.summary
    }
    @objc private func hideTemplateChoices() {
        templateMenuOverlay?.removeFromSuperview()
        templateMenuOverlay = nil
    }
    @objc private func showTemplateChoices() {
        if templateMenuOverlay != nil { hideTemplateChoices(); return }
        guard let window = view.window else { return }
        if nameField.isFirstResponder {
            nameField.resignFirstResponder()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in self?.showTemplateChoices() }
            return
        }
        view.layoutIfNeeded()
        let anchor = templateButton.convert(templateButton.bounds, to: window)
        let width = min(300, max(260, anchor.width), window.bounds.width - 32)
        let rowHeight: CGFloat = 48
        let height = rowHeight * CGFloat(WellnessTemplate.allCases.count)
        let above = anchor.minY - height - 10 >= window.safeAreaInsets.top + 12
        let x = min(max(16, anchor.maxX - width), window.bounds.width - width - 16)
        let y = above ? anchor.minY - height - 10 : min(anchor.maxY + 10, window.bounds.height - window.safeAreaInsets.bottom - height - 12)
        let overlay = UIControl(frame: window.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.accessibilityIdentifier = "NotebookTemplateMenu"
        overlay.accessibilityViewIsModal = true
        overlay.addTarget(self, action: #selector(hideTemplateChoices), for: .touchUpInside)
        let surface = UIColor(red: 0.99, green: 0.98, blue: 1, alpha: 1)
        let outline = UIColor(red: 0.62, green: 0.58, blue: 0.80, alpha: 0.48)
        let arrowX = min(max(anchor.midX, x + 22), x + width - 22)
        let baseY = above ? y + height : y
        let pointer = UIBezierPath()
        pointer.move(to: CGPoint(x: arrowX - 9, y: baseY))
        pointer.addLine(to: CGPoint(x: arrowX, y: baseY + (above ? 9 : -9)))
        pointer.addLine(to: CGPoint(x: arrowX + 9, y: baseY))
        pointer.close()
        let arrow = CAShapeLayer()
        arrow.path = pointer.cgPath
        arrow.fillColor = surface.cgColor
        arrow.strokeColor = outline.cgColor
        arrow.lineWidth = 1
        overlay.layer.addSublayer(arrow)
        let shadow = UIView(frame: CGRect(x: x, y: y, width: width, height: height))
        shadow.layer.shadowColor = ApplazAppearance.accent.cgColor
        shadow.layer.shadowOpacity = 0.12
        shadow.layer.shadowRadius = 14
        shadow.layer.shadowOffset = CGSize(width: 0, height: 7)
        shadow.layer.shadowPath = UIBezierPath(roundedRect: shadow.bounds, cornerRadius: 14).cgPath
        overlay.addSubview(shadow)
        let card = UIView(frame: shadow.bounds)
        card.backgroundColor = surface
        card.layer.cornerRadius = 14
        card.layer.borderColor = outline.cgColor
        card.layer.borderWidth = 1
        card.clipsToBounds = true
        shadow.addSubview(card)
        var selectedButton: UIButton?
        for (index, template) in WellnessTemplate.allCases.enumerated() {
            let selected = template == selectedTemplate
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: 0, y: CGFloat(index) * rowHeight, width: width, height: rowHeight)
            button.backgroundColor = selected ? UIColor(red: 0.89, green: 0.86, blue: 0.95, alpha: 1) : .clear
            button.accessibilityIdentifier = "NotebookTemplateChoice." + template.id
            button.accessibilityLabel = templateTitle(template)
            button.accessibilityHint = template.summary
            button.isAccessibilityElement = true
            button.isSelected = selected
            if selected { button.accessibilityTraits.insert(.selected); selectedButton = button }
            let label = UILabel(frame: CGRect(x: 18, y: 0, width: width - 66, height: rowHeight))
            label.text = templateTitle(template)
            label.textColor = ApplazAppearance.ink
            label.font = ApplazAppearance.font(17, weight: selected ? .medium : .regular)
            label.lineBreakMode = .byTruncatingTail
            label.isAccessibilityElement = false
            button.addSubview(label)
            if selected {
                let checkmark = UIImageView(image: UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)))
                checkmark.frame = CGRect(x: width - 38, y: 14, width: 20, height: 20)
                checkmark.contentMode = .scaleAspectFit
                checkmark.tintColor = ApplazAppearance.accent
                button.addSubview(checkmark)
            }
            if index < WellnessTemplate.allCases.count - 1 {
                let divider = UIView(frame: CGRect(x: 0, y: rowHeight - 1, width: width, height: 1))
                divider.backgroundColor = ApplazAppearance.accent.withAlphaComponent(0.08)
                divider.isUserInteractionEnabled = false
                button.addSubview(divider)
            }
            button.addAction(UIAction { [weak self] _ in
                self?.hideTemplateChoices()
                self?.selectTemplate(template)
                UIAccessibility.post(notification: .layoutChanged, argument: self?.templateButton)
            }, for: .touchUpInside)
            card.addSubview(button)
        }
        templateMenuOverlay = overlay
        window.addSubview(overlay)
        UIAccessibility.post(notification: .screenChanged, argument: selectedButton)
    }
    override func viewWillDisappear(_ animated: Bool) {
        hideTemplateChoices()
        super.viewWillDisappear(animated)
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        hideTemplateChoices()
        super.viewWillTransition(to: size, with: coordinator)
    }
    override func accessibilityPerformEscape() -> Bool {
        guard templateMenuOverlay != nil else { return false }
        hideTemplateChoices()
        UIAccessibility.post(notification: .layoutChanged, argument: templateButton)
        return true
    }
    func selectTemplate(_ template: WellnessTemplate) {
        selectedTemplate = template
        checklistControl.isEnabled = template == .blank
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

    @objc private func chooseCollaborators() {
        CollaborationPresentation.choose(from: self, selected: selectedCollaborators) { [weak self] people in
            self?.selectedCollaborators = people
            self?.inviteFriendsButton.setTitle(people.isEmpty ? "Invite friends" : people.map { "@" + $0.name }.joined(separator: ", "), for: .normal)
        }
    }
    @objc private func createNotebook() {
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let isPrivate = visibilityControl.selectedSegmentIndex == 1
        if !selectedCollaborators.isEmpty {
            createButton.isEnabled = false
            let id = createdCollaborativeNotebookID ?? WellnessStore.shared.create(selectedTemplate, name: name)
            createdCollaborativeNotebookID = id
            if var notebook = WellnessStore.shared.notebooks.first(where: { $0.id == id }) {
                notebook.isPrivate = isPrivate
                if selectedTemplate == .blank && checklistControl.selectedSegmentIndex == 1 { notebook.kind = "checklist"; notebook.notes = [WellnessTextNote(title: "My checklist", body: "", isChecklist: true)] }
                WellnessStore.shared.update(notebook)
            }
            Task { do {
                _ = try await CollaborationStore.shared.invite(kind: "health", sourceID: id, people: selectedCollaborators)
                await WellnessStore.shared.sync()
                if let onFinish { onFinish() } else { dismiss(animated: true) }
            } catch {
                createButton.isEnabled = true
                let alert = UIAlertController(title: "Couldn’t send invitations", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default)); present(alert, animated: true)
            } }
            return
        }
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
        if let onFinish { onFinish() } else { dismiss(animated: true) }
    }

    @objc private func cancelCreation() { if let onFinish { onFinish() } else { dismiss(animated: true) } }
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
