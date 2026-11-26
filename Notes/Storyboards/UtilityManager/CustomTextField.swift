import UIKit

@IBDesignable
class CustomTextField: UITextField {

    //MARK:- OBJECTS
    @IBInspectable var isPasteEnabled: Bool = true
    @IBInspectable var isSelectEnabled: Bool = true
    @IBInspectable var isSelectAllEnabled: Bool = true
    @IBInspectable var isCopyEnabled: Bool = true
    @IBInspectable var isCutEnabled: Bool = true
    @IBInspectable var isDeleteEnabled: Bool = true
    
    //MARK:- METHODS
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        UIMenuController.shared.isMenuVisible = false
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(UIResponderStandardEditActions.paste(_:)) where !isPasteEnabled,
             #selector(UIResponderStandardEditActions.select(_:)) where !isSelectEnabled,
             #selector(UIResponderStandardEditActions.selectAll(_:)) where !isSelectAllEnabled,
             #selector(UIResponderStandardEditActions.copy(_:)) where !isCopyEnabled,
             #selector(UIResponderStandardEditActions.cut(_:)) where !isCutEnabled,
             #selector(UIResponderStandardEditActions.delete(_:)) where !isDeleteEnabled:
            return false
        default:
            return super.canPerformAction(action, withSender: sender)
        }
    }
    
    override func caretRect(for position: UITextPosition) -> CGRect {
        return .zero
    }
}
