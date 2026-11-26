//
//  ThemeSettingTableViewCell.swift
//  Notes
//
//  Created by Ghullam Abbas on 29/10/2024.
//  Copyright © 2024 Sevenstar Infotech. All rights reserved.
//

import UIKit

class ThemeSettingTableViewCell: UITableViewCell {

    @IBOutlet weak var themeContainerView: UIView!
    @IBOutlet weak var titleLable: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    private let hairline = CALayer()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLable.font = ApplazAppearance.font(17)
        titleLable.textColor = ApplazAppearance.ink
        iconImageView.tintColor = ApplazAppearance.accent
        themeContainerView.backgroundColor = .clear
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        themeContainerView.layer.cornerRadius = 14
        themeContainerView.layer.cornerCurve = .continuous
        themeContainerView.layer.borderWidth = 0
        hairline.backgroundColor = ApplazAppearance.outline.cgColor
        themeContainerView.layer.addSublayer(hairline)
        
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        hairline.frame = CGRect(x: 48, y: themeContainerView.bounds.height - 0.5, width: max(0, themeContainerView.bounds.width - 60), height: 0.5)
        CATransaction.commit()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
