//
//  ConversationRead.swift
//  ProtonMail
//
//
//  Copyright (c) 2020 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.
//

import Foundation
import PMCommon

/// Mark an array of conversations as read
///
/// Note that a maximum of 50 conversation IDs can be passed by request.
class ConversationReadRequest: Request {
    /// max for 50 ids
    private let conversationIDs: [String]

    init(conversationIDs: [String]) {
        self.conversationIDs = conversationIDs
    }

    var path: String {
        return ConversationsAPI.path + "/read"
    }

    var parameters: [String : Any]? {
        return ["IDs": conversationIDs]
    }
}

class ConversationReadResponse: Response {
    var responseDict: [String: Any]?
    var results: [ConversationReadData]?
    
    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        responseDict = response

        guard let data = try? JSONSerialization.data(withJSONObject: response["Responses"] as Any, options: .prettyPrinted) else {
            return false
        }

        guard let result = try? JSONDecoder().decode([ConversationReadData].self, from: data) else {
            return false
        }
        results = result
        return true
    }
}

struct ConversationReadData: Decodable {
    let id: String
    let response: ResponseCode

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case response = "Response"
    }

    struct ResponseCode: Decodable {
        let code: Int

        enum CodingKeys: String, CodingKey {
            case code = "Code"
        }
    }
}
