//
//  ContactsTableViewCell.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import UIKit
import MCSwipeTableViewCell
import ProtonCore_Foundations
import ProtonCore_UIFoundations

/// Custom cell for Contact list, Group list and composer autocomplete
final class ContactsTableViewCell: MCSwipeTableViewCell, AccessibleCell {

    /// easiler to access
    static let cellID = "ContactCell"
    static var nib: UINib {
        return UINib(nibName: "ContactsTableViewCell", bundle: Bundle.main)
    }

    /// contact name, fill email if name is nil
    @IBOutlet weak var nameLabel: UILabel!
    /// contact email address
    @IBOutlet weak var emailLabel: UILabel!
    /// cell reused in contact groups. if the cell in the group list. show group icon and hides the shortNam label.
    @IBOutlet weak var groupImage: UIImageView!
    /// short name label, use the first char from name/email
    @IBOutlet weak var shortName: UILabel!

    override func awakeFromNib() {
        // 20 because the width is 40 hard coded
        self.shortName.layer.cornerRadius = 20
        self.shortName.backgroundColor = ColorProvider.InteractionWeak
        self.backgroundColor = ColorProvider.BackgroundNorm
    }

    /// config cell when cellForRowAt
    ///
    /// - Parameters:
    ///   - name: contact name.
    ///   - email: contact email.
    ///   - highlight: hightlight string. autocomplete in composer
    ///   - color: contact group color -- String type and optional
    func config(name: String, email: String, highlight: String, color: String? = nil) {
        self.nameLabel.attributedText =
            .highlightedString(text: name,
                               search: highlight,
                               font: .highlightSearchTextForTitle)

        let emailAttributes = FontManager.DefaultSmallWeak.addTruncatingTail()
        self.emailLabel.attributedText =
            .highlightedString(text: email,
                               textAttributes: emailAttributes,
                               search: highlight,
                               font: .highlightSearchTextForSubtitle)

        // will be show the image
        if let color = color {
            groupImage.setupImage(tintColor: UIColor.white,
                                  backgroundColor: UIColor(hexColorCode: color),
                                  borderWidth: 0,
                                  borderColor: UIColor.white.cgColor)
            self.groupImage.isHidden = false
        } else {
            self.groupImage.isHidden = true
        }

        let attr = FontManager.body3RegularNorm.alignment(.center)
        shortName.attributedText = name.initials().apply(style: attr)
        generateCellAccessibilityIdentifiers(name)
    }
}