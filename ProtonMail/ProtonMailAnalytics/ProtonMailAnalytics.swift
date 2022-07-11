// Copyright (c) 2022 Proton AG
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

import Foundation
import Sentry

public protocol ProtonMailAnalyticsProtocol: AnyObject {
    init(endPoint: String)
    func setup(environment: String?, debug: Bool)
    func track(event: MailAnalyticsEvent, trace: String?)
    func track(error: MailAnalyticsErrorEvent, trace: String?)
}

public final class ProtonMailAnalytics: ProtonMailAnalyticsProtocol {
    private let endPoint: String
    private(set) var isEnabled = false

    required public init(endPoint: String) {
        self.endPoint = endPoint
    }

    public func setup(environment: String? = nil, debug: Bool = false) {
        SentrySDK.start { options in
            options.dsn = self.endPoint
            options.debug = debug
            options.environment = environment

            // Disabling some options to make the report work. Otherwise it does not show in Sentry,
            // probably because the size limit in Proton's backend is 65kb for each event.
            // See: https://jira.protontech.ch/browse/INFSUP-682
            options.enableAutoSessionTracking = false
            options.attachStacktrace = false
            options.maxBreadcrumbs = 10
        }
        isEnabled = true
    }

    public func track(event: MailAnalyticsEvent, trace: String?) {
        guard isEnabled else { return }
        let eventToSend = Sentry.Event(level: .info)
        eventToSend.message = SentryMessage(formatted: "\(event.name) - \(event.description)")
        // From the Sentry dashboard it is not possible to query using the `extra` field.
        eventToSend.extra = customTraceDictionary(for: trace)
        SentrySDK.capture(event: eventToSend)
    }

    public func track(error errorEvent: MailAnalyticsErrorEvent, trace: String?) {
        guard isEnabled else { return }
        let eventToSend = Sentry.Event(level: .error)
        eventToSend.message = SentryMessage(formatted: errorEvent.name)
        // From the Sentry dashboard it is not possible to query using the `extra` field.
        eventToSend.extra = customTraceDictionary(for: trace)?
            .merging(errorEvent.extraInfo ?? [:], uniquingKeysWith: { current, _ in current })
        SentrySDK.capture(event: eventToSend)
    }

    private func customTraceDictionary(for trace: String?) -> [String: Any]? {
        // replacing `auth` occurrences to avoid Sentry redacting our data for PII compliance policies
        guard let trace = trace?.replacingOccurrences(of: "auth", with: "autth") else { return nil }
        return ["Custom Trace": trace]
    }
}

// MARK: Events

public enum MailAnalyticsEvent {

    /// The user session has been terminated and the user has to authenticate again
    case userKickedOut(reason: UserKickedOutReason)
    case inconsistentBody
}

extension MailAnalyticsEvent: Equatable {

    public static func == (lhs: MailAnalyticsEvent, rhs: MailAnalyticsEvent) -> Bool {
        lhs.name == rhs.name && lhs.description == rhs.description
    }
}

private extension MailAnalyticsEvent {

    var name: String {
        let message: String
        switch self {
        case .userKickedOut:
            message = "User kicked out"
        case .inconsistentBody:
            message = "Inconsistent body"
        }
        return message
    }

    var description: String {
        switch self {
        case .userKickedOut(let reason):
            return "reason: \(reason.description)"
        case .inconsistentBody:
            return "Sent message body doesn't match with draft body"
        }
    }
}

public enum UserKickedOutReason {
    case apiAccessTokenInvalid
    case afterLockScreen(description: String)
    case noUsersFoundInUsersManager(action: String)
    case unexpected(description: String)

    var description: String {
        let description: String
        switch self {
        case .apiAccessTokenInvalid:
            description = "user access token is not valid anymore"
        case .afterLockScreen(let message):
            description = "after lock screen (\(message))"
        case .noUsersFoundInUsersManager(let action):
            description = "no users found for action (\(action))"
        case .unexpected(let message):
            description = "unexpected (\(message))"
        }
        return description
    }
}

// MARK: Error Events

public enum MailAnalyticsErrorEvent: Error {

    /// An error occurred during Core Data initial set up
    case coreDataInitialisation(error: String)

    /// used to track when the app sends a conversation reqeust without a conversation ID.
    case abortedConversationRequest

    var name: String {
        let message: String
        switch self {
        case .coreDataInitialisation:
            message = "Core Data initialisation error"
        case .abortedConversationRequest:
            message = "Aborted request without conversation ID"
        }
        return message
    }

    var extraInfo: [String: Any]? {
        let info: [String: Any]?
        switch self {
        case .coreDataInitialisation(let error):
            info = ["Custom Error": error]
        case .abortedConversationRequest:
            info = nil
        }
        return info
    }
}

extension MailAnalyticsErrorEvent: Equatable {

    public static func == (lhs: MailAnalyticsErrorEvent, rhs: MailAnalyticsErrorEvent) -> Bool {
        lhs.name == rhs.name
    }
}
