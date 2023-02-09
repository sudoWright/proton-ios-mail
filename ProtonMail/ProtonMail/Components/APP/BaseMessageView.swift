// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_UIFoundations

class BaseMessageView: UIView {
    let attachmentImageView = SubviewsFactory.attachmentImageView
    let forwardImageView = SubviewsFactory.forwardImageView
    let replyAllImageView = SubviewsFactory.replyAllImageView
    let replyImageView = SubviewsFactory.replyImageView
    let starImageView = SubviewsFactory.starImageView
    let tagsView = SingleRowTagsView()
    let timeLabel = UILabel()
}

extension BaseMessageView {
    class SubviewsFactory {
        class var attachmentImageView: UIImageView {
            .make(icon: \.paperClip, tintColor: \.IconNorm)
        }

        class var draftImageView: UIImageView {
            .make(icon: \.pencil, tintColor: \.IconNorm)
        }

        class var forwardImageView: UIImageView {
            .make(icon: \.arrowRight, tintColor: \.IconNorm)
        }

        class var replyImageView: UIImageView {
            .make(icon: \.arrowUpAndLeft, tintColor: \.IconNorm)
        }

        class var replyAllImageView: UIImageView {
            .make(icon: \.arrowsUpAndLeft, tintColor: \.IconNorm)
        }

        class var starImageView: UIImageView {
            .make(icon: \.starFilled, tintColor: \.NotificationWarning)
        }
    }
}