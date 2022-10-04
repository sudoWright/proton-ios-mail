//
//  NonExpandedHeaderViewController.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
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

import ProtonCore_DataModel
import ProtonCore_UIFoundations
import UIKit

class NonExpandedHeaderViewController: UIViewController {

    private(set) lazy var customView = NonExpandedHeaderView()
    private let viewModel: NonExpandedHeaderViewModel
    private let tagsPresenter = TagsPresenter()
    private var showDetailsAction: (() -> Void)?
    var contactTapped: ((MessageHeaderContactContext) -> Void)?

    init(viewModel: NonExpandedHeaderViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpLockTapAction()
        setUpViewModelObservations()
        setUpView()
        setUpTimeLabelUpdate()
    }

    func observeShowDetails(action: @escaping (() -> Void)) {
        self.showDetailsAction = action
    }

    private func setUpView() {
        customView.initialsLabel.set(text: viewModel.infoProvider?.initials, preferredFont: .footnote)
        customView.initialsLabel.textAlignment = .center
        customView.originImageView.image = viewModel.infoProvider?.originImage(isExpanded: false)
        customView.originImageContainer.isHidden = viewModel.infoProvider?.originImage(isExpanded: false) == nil
        customView.sentImageView.isHidden = !viewModel.shouldShowSentImage

        // highlight keywords when searching
        if #available(iOS 12.0, *) {
            var senderAttributed: NSMutableAttributedString = NSMutableAttributedString(string: viewModel.infoProvider?.senderName ?? "")
            senderAttributed = EncryptedSearchService.shared.addKeywordHighlightingToAttributedString(stringToHighlight: senderAttributed)
            customView.senderLabel.setAttributed(text: senderAttributed,
                                                 preferredFont: .subheadline,
                                                 weight: .semibold)
        } else {
            customView.senderLabel.set(text: viewModel.infoProvider?.senderName,
                                       preferredFont: .subheadline,
                                       weight: .semibold)
        }

        // highlight keywords when searching
        if #available(iOS 12.0, *) {
            var senderAddressAttributed: NSMutableAttributedString = NSMutableAttributedString(string: viewModel.infoProvider?.senderEmail ?? "")
            senderAddressAttributed = EncryptedSearchService.shared.addKeywordHighlightingToAttributedString(stringToHighlight: senderAddressAttributed)
            customView.senderAddressLabel.label.setAttributed(text: senderAddressAttributed,
                                                              preferredFont: .footnote,
                                                              textColor: ColorProvider.InteractionNorm,
                                                              lineBreakMode: .byTruncatingMiddle)
        } else {
            customView.senderAddressLabel.label.set(text: viewModel.infoProvider?.senderEmail,
                                                    preferredFont: .footnote,
                                                    textColor: ColorProvider.InteractionNorm,
                                                    lineBreakMode: .byTruncatingMiddle)
        }
        customView.senderAddressLabel.tap = { [weak self] in
            guard let sender = self?.viewModel.infoProvider?.checkedSenderContact else { return }
            self?.contactTapped(sheetType: .sender, contact: sender)
        }
        customView.timeLabel.set(text: viewModel.infoProvider?.time,
                                 preferredFont: .footnote,
                                 textColor: ColorProvider.TextWeak)

        // highlight keywords when searching
        if #available(iOS 12.0, *) {
            var recipientAttributed: NSMutableAttributedString = NSMutableAttributedString(string: viewModel.infoProvider?.simpleRecipient ?? "")
            recipientAttributed = EncryptedSearchService.shared.addKeywordHighlightingToAttributedString(stringToHighlight: recipientAttributed)
            customView.recipientLabel.attributedText = recipientAttributed
        } else {
            customView.recipientLabel.text = viewModel.infoProvider?.simpleRecipient
        }
        customView.showDetailsControl.addTarget(self,
                                                action: #selector(self.clickShowDetailsButton),
                                                for: .touchUpInside)
        let isStarred = viewModel.infoProvider?.message.isStarred ?? false
        customView.starImageView.isHidden = !isStarred
        let tags = viewModel.infoProvider?.message.tagUIModels ?? []
        tagsPresenter.presentTags(tags: tags, in: customView.tagsView)
        let contact = viewModel.infoProvider?.checkedSenderContact
        update(senderContact: contact)
    }

    func update(senderContact: ContactVO?) {
        if let contact = senderContact {
            let icon = contact.encryptionIconStatus?.icon
            customView.lockImageView.image = icon
            customView.lockImageView.tintColor = contact.encryptionIconStatus?.iconColor.color ?? .black
            customView.lockContainer.isHidden = icon == nil
        } else {
            customView.lockContainer.isHidden = true
        }
    }

	private func setUpTimeLabelUpdate() {
        viewModel.setupTimerIfNeeded()
        viewModel.updateTimeLabel = { [weak self] in
            self?.customView.timeLabel.text = self?.viewModel.infoProvider?.time
        }
    }

    private func setUpLockTapAction() {
        customView.lockImageControl.addTarget(self, action: #selector(lockTapped), for: .touchUpInside)
    }

    @objc
    private func lockTapped() {
        viewModel.infoProvider?.checkedSenderContact?.encryptionIconStatus?.text.alertToastBottom()
    }

    @objc
    private func clickShowDetailsButton() {
        self.showDetailsAction?()
    }

    private func setUpViewModelObservations() {
        viewModel.reloadView = { [weak self] in
            self?.setUpView()
        }
    }

    private func contactTapped(sheetType: MessageDetailsContactActionSheetType, contact: ContactVO) {
        let context = MessageHeaderContactContext(type: sheetType, contact: contact)
        contactTapped?(context)
    }

    required init?(coder: NSCoder) {
        nil
    }

}
