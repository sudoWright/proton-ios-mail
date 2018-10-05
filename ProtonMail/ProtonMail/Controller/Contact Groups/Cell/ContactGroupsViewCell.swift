//
//  ContactGroupsViewCell.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/9/5.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

protocol ContactGroupsViewCellDelegate {
    func isMultiSelect() -> Bool
    func sendEmailToGroup(ID: String, name: String)
}

class ContactGroupsViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var groupImage: UIImageView!
    @IBOutlet weak var sendButton: UIButton!
    
    let highlightedColor = "#BFBFBF"
    let normalColor = "#9497CE"
    
    private var labelID = ""
    private var name = ""
    private var count = 0
    private var color = ColorManager.defaultColor
    private var delegate: ContactGroupsViewCellDelegate!
    
    // the count of emails in a contact group
    // the assumption of this variable to work properly is that the contact group data won't be updated
    // mid-way through the contact editing process, e.g. we will sort of use the snapshot of the contact group
    // status for the entire duration of contact editing
    private var origCount: Int = 0
    
    // at the time that we started editing the contact, if the email is in this contact group
    // this variable should be set to true
    private var wasSelected: Bool = false
    
    @IBAction func sendEmailButtonTapped(_ sender: UIButton) {
        delegate.sendEmailToGroup(ID: labelID, name: name)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setCount(_ count: Int) {
        self.count = count
        self.setDetailString()
    }
    
    private func setDetailString() {
        self.detailLabel.text = "\(self.count) Member\(self.count > 1 ? "s" : "")"
    }

    func config(labelID: String,
                name: String,
                count: Int,
                color: String?,
                wasSelected: Bool,
                delegate: ContactGroupsViewCellDelegate) {
        // setup and save
        self.count = count
        self.origCount = count
        self.labelID = labelID
        self.name = name
        self.color = color ?? ColorManager.defaultColor
        self.delegate = delegate
        self.wasSelected = wasSelected
        
        // set cell data
        if let image = sendButton.imageView?.image {
            sendButton.imageView?.contentMode = .center
            sendButton.imageView?.image = UIImage.resize(image: image, targetSize: CGSize.init(width: 20, height: 20))
        }
        
        self.nameLabel.text = name
        self.setDetailString()
        groupImage.setupImage(tintColor: UIColor.white,
                              backgroundColor: color != nil ? color! : ColorManager.defaultColor,
                              borderWidth: 0,
                              borderColor: UIColor.white.cgColor)
    }
    
    private func reset() {
        self.selectionStyle = .default
        
        groupImage.image = UIImage(named: "contact_groups_icon")
        groupImage.setupImage(contentMode: .center,
                              renderingMode: .alwaysTemplate,
                              scale: 0.5,
                              makeCircleBorder: true,
                              tintColor: UIColor.white,
                              backgroundColor: color,
                              borderWidth: 0,
                              borderColor: UIColor.white.cgColor)
    }
    
    func getLabelID() -> String {
        return labelID
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if delegate.isMultiSelect() && selected {
            // in multi-selection
            self.selectionStyle = .none
            
            groupImage.image = UIImage(named: "contact_groups_check")
            groupImage.setupImage(contentMode: .center,
                                  renderingMode: .alwaysOriginal,
                                  scale: 0.5,
                                  makeCircleBorder: true,
                                  tintColor: UIColor.white,
                                  backgroundColor: ColorManager.white,
                                  borderWidth: 1.0,
                                  borderColor: UIColor.gray.cgColor)
        } else if delegate.isMultiSelect() == false && selected {
            // normal selection
            groupImage.backgroundColor = UIColor(hexColorCode: highlightedColor)
        } else {
            reset()
        }
    }
}
