//
//  AppDelegate.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
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


import UIKit
import AFNetworking
import PMKeymaker
import UserNotifications
import Intents
import PMCommon
import PMPayments
import SideMenuSwift

let sharedUserDataService = UserDataService(api: PMAPIService.unauthorized)

@UIApplicationMain
class AppDelegate: UIResponder {
    var window: UIWindow? { // this property is important for State Restoration of modally presented viewControllers
        return self.coordinator.currentWindow
    }
    lazy var coordinator: WindowsCoordinator = WindowsCoordinator(services: sharedServices)
    private var currentState: UIApplication.State = .active
}

// MARK: - this is workaround to track when the SideMenuController first time load
extension SideMenuController {
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segue = segue as? SideMenuSegue, let identifier = segue.identifier else {
            return
        }
        switch identifier {
        case contentSegueID:
            segue.contentType = .content
            if let navigation = segue.destination as? UINavigationController {
                if let mailboxViewController: MailboxViewController = navigation.firstViewController() as? MailboxViewController {
                    sharedVMService.mailbox(fromMenu: mailboxViewController)
                    let usersManager = sharedServices.get(by: UsersManager.self)
                    let user = usersManager.firstUser!
                    let viewModel = MailboxViewModelImpl(label: .inbox,
                                                         userManager: user,
                                                         usersManager: usersManager,
                                                         pushService: sharedServices.get(),
                                                         coreDataService: sharedServices.get(),
                                                         lastUpdatedStore: sharedServices.get(by: LastUpdatedStore.self),
                                                         queueManager: sharedServices.get(by: QueueManager.self))
                    let mailbox = MailboxCoordinator(vc: mailboxViewController, vm: viewModel, services: sharedServices)
                    mailbox.start()
                }
            }
        case menuSegueID:
            segue.contentType = .menu
            guard let menuVC = segue.destination as? MenuViewController else {
                return
            }
            let usersManager = sharedServices.get(by: UsersManager.self)
            let pushService = sharedServices.get(by: PushNotificationService.self)
            let coreDataService = sharedServices.get(by: CoreDataService.self)
            let lateUpdatedStore = sharedServices.get(by: LastUpdatedStore.self)
            let queueManager = sharedServices.get(by: QueueManager.self)
            let viewModel = MenuViewModel(usersManager: usersManager, queueManager: queueManager, coreDataService: coreDataService)
            viewModel.set(delegate: menuVC)
            let coordinator = MenuCoordinator(services: sharedServices,
                                              vmService: sharedVMService,
                                              pushService: pushService,
                                              coreDataService: coreDataService,
                                              lastUpdatedStore: lateUpdatedStore,
                                              usersManager: usersManager,
                                              vc: menuVC,
                                              vm: viewModel)

            coordinator.start()
        default:
            break
        }
    }
}

// MARK: - consider move this to coordinator
extension AppDelegate: APIServiceDelegate, UserDataServiceDelegate {
    func onLogout(animated: Bool) {
        if #available(iOS 13.0, *) {
            let sessions = Array(UIApplication.shared.openSessions)
            let oneToStay = sessions.first(where: { $0.scene?.delegate as? WindowSceneDelegate != nil })
            (oneToStay?.scene?.delegate as? WindowSceneDelegate)?.coordinator.go(dest: .signInWindow)
            
            for session in sessions where session != oneToStay {
                UIApplication.shared.requestSceneSessionDestruction(session, options: nil) { error in
                    PMLog.D(error.localizedDescription)
                }
            }
        } else {
            self.coordinator.go(dest: .signInWindow)
        }
    }
    
    func isReachable() -> Bool {
        return sharedInternetReachability.currentReachabilityStatus() != NetworkStatus.NotReachable
    }
    
    func onError(error: NSError) {
        error.alertToast()
    }
    
    func onUpdate(serverTime: Int64) {
        Crypto.updateTime(serverTime)
    }

    var appVersion: String {
        get {
            return "iOS_\(Bundle.main.majorVersion)"
        }
    }

    var userAgent: String? {
        UserAgent.default.ua
    }

    func onDohTroubleshot() {
        //TODO:: fix me TBA
    }

    func onChallenge(challenge: URLAuthenticationChallenge,
                     credential: AutoreleasingUnsafeMutablePointer<URLCredential?>?) -> URLSession.AuthChallengeDisposition {
        //TODO:: fix me TBA
        return .useCredential
    }
}

extension AppDelegate: TrustKitUIDelegate {
    func onTrustKitValidationError(_ alert: UIAlertController) {
        let currentWindow: UIWindow? = {
            if #available(iOS 13.0, *) {
                let session = UIApplication.shared.openSessions.first { $0.scene?.activationState == UIScene.ActivationState.foregroundActive }
                let scene = session?.scene as? UIWindowScene
                let window = scene?.windows.first
                return window
            } else {
                return self.window
            }
        }()
        
        guard let top = currentWindow?.topmostViewController(), !(top is UIAlertController) else { return }
        top.present(alert, animated: true, completion: nil)
    }
}

//move to a manager class later
let sharedInternetReachability : Reachability = Reachability.forInternetConnection()
//let sharedRemoteReachability : Reachability = Reachability(hostName: AppConstants.API_HOST_URL)

// MARK: - UIApplicationDelegate
extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        sharedServices.get(by: AppCacheService.self).restoreCacheWhenAppStart()

        let usersManager = UsersManager(doh: DoHMail.default, delegate: self)
        let lastUpdatedStore = sharedServices.get(by: LastUpdatedStore.self)
        let messageQueue = PMPersistentQueue(queueName: PMPersistentQueue.Constant.name)
        let miscQueue = PMPersistentQueue(queueName: PMPersistentQueue.Constant.miscName)
        let queueManager = QueueManager(messageQueue: messageQueue, miscQueue: miscQueue)
        sharedServices.add(QueueManager.self, for: queueManager)
        sharedServices.add(UnlockManager.self, for: UnlockManager(cacheStatus: userCachedStatus, delegate: self))
        sharedServices.add(UsersManager.self, for: usersManager)
        sharedServices.add(SignInManager.self, for: SignInManager(usersManager: usersManager, lastUpdatedStore: lastUpdatedStore, queueManager: queueManager))
        sharedServices.add(SpringboardShortcutsService.self, for: SpringboardShortcutsService())
        sharedServices.add(StoreKitManagerImpl.self, for: StoreKitManagerImpl())
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG 
        PMLog.D("App group directory: " + FileManager.default.appGroupsDirectoryURL.absoluteString)
        PMLog.D("App directory: " + FileManager.default.applicationSupportDirectoryURL.absoluteString)
        PMLog.D("Tmp directory: " + FileManager.default.temporaryDirectoryUrl.absoluteString)
        PMAPIService.noTrustKit = true
        #else
        TrustKitWrapper.start(delegate: self)
        #endif

        Analytics.shared.setup()
        
        UIApplication.shared.setMinimumBackgroundFetchInterval(300)

        UINavigationBar.appearance().backIndicatorImage = UIImage(named: "back-arrow")?.withRenderingMode(.alwaysTemplate)
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage(named: "back-arrow")?.withRenderingMode(.alwaysTemplate)
        
        ///TODO::fixme refactor
        shareViewModelFactoy = ViewModelFactoryProduction()
        sharedVMService.cleanLegacy()
        
        AFNetworkActivityIndicatorManager.shared().isEnabled = true
        
        //start network notifier
        sharedInternetReachability.startNotifier()
        
        // setup language: iOS 13 allows setting language per-app in Settings.app, so we trust that value
        // we still use LanguageManager because Bundle.main of Share extension will take the value from host application :(
        if #available(iOS 13.0, *), let code = Bundle.main.preferredLocalizations.first {
            LanguageManager.saveLanguage(byCode: code)
        }
        //setup language
        LanguageManager.setupCurrentLanguage()

        let pushService : PushNotificationService = sharedServices.get()
        UNUserNotificationCenter.current().delegate = pushService
        pushService.registerForRemoteNotifications()
        pushService.setLaunchOptions(launchOptions)
        
        StoreKitManager.default.delegate = sharedServices.get(by: StoreKitManagerImpl.self)
        StoreKitManager.default.subscribeToPaymentQueue()
        StoreKitManager.default.updateAvailableProductsList()
        
        #if DEBUG
        NotificationCenter.default.addObserver(forName: Keymaker.Const.errorObtainingMainKey, object: nil, queue: .main) { notification in
            (notification.userInfo?["error"] as? Error)?.localizedDescription.alertToast()
        }
        NotificationCenter.default.addObserver(forName: Keymaker.Const.removedMainKeyFromMemory, object: nil, queue: .main) { notification in
            "Removed main key from memory".alertToastBottom()
        }
        #endif
        NotificationCenter.default.addObserver(forName: Keymaker.Const.obtainedMainKey, object: nil, queue: .main) { notification in
            #if DEBUG
                "Obtained main key".alertToastBottom()
            #endif
            
            if self.currentState != .active {
                keymaker.updateAutolockCountdownStart()
            }
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didSignOutNotification(_:)),
                                               name: NSNotification.Name.didSignOut,
                                               object: nil)
        
        if #available(iOS 12.0, *) {
//            let intent = WipeMainKeyIntent()
//            let suggestions = [INShortcut(intent: intent)!]
//            INVoiceShortcutCenter.shared.setShortcutSuggestions(suggestions)
        }

        if #available(iOS 13.0, *) {
            // multiwindow support managed by UISessionDelegate, not UIApplicationDelegate
        } else {
            self.coordinator.start()
        }
        return true
    }
    
    
    @objc fileprivate func didSignOutNotification(_ notification: Notification) {
        self.onLogout(animated: false)
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.checkOrientation(window?.rootViewController)
    }
    
    func checkOrientation (_ viewController: UIViewController?) -> UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad || viewController == nil {
            return UIInterfaceOrientationMask.all
        } else if let nav = viewController as? UINavigationController {
            if (nav.topViewController!.isKind(of: PinCodeViewController.self)) {
                return UIInterfaceOrientationMask.portrait
            }
            return UIInterfaceOrientationMask.all
        } else {
            if let sw = viewController as? SideMenuController {
                if let nav = sw.contentViewController as? UINavigationController {
                    if (nav.topViewController!.isKind(of: PinCodeViewController.self)) {
                        return UIInterfaceOrientationMask.portrait
                    }
                }
            }
            return .all
        }
    }
    
    @available(iOS, deprecated: 13, message: "This method will not get called on iOS 13, move the code to WindowSceneDelegate.scene(_:openURLContexts:)" )
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return self.application(app, handleOpen: url)
    }
    
    @available(iOS, deprecated: 13, message: "This method will not get called on iOS 13, move the code to WindowSceneDelegate.scene(_:openURLContexts:)" )
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return false
        }
        
        if ["protonmail", "mailto"].contains(urlComponents.scheme) || "mailto".caseInsensitiveCompare(urlComponents.scheme ?? "") == .orderedSame {
            var path = url.absoluteString
            if urlComponents.scheme == "protonmail" {
                path = path.preg_replace("protonmail://", replaceto: "")
            }
            
            let deeplink = DeepLink(String(describing: MailboxViewController.self), sender: Message.Location.inbox.rawValue)
            deeplink.append(DeepLink.Node(name: "toMailboxSegue", value: Message.Location.inbox))
            deeplink.append(DeepLink.Node(name: "toComposeMailto", value: path))
            self.coordinator.followDeeplink(deeplink)
            return true
        }
        
        guard urlComponents.host == "signup" else {
            return false
        }
        guard let queryItems = urlComponents.queryItems, let verifyObject = queryItems.filter({$0.name == "verifyCode"}).first else {
            return false
        }
        
        guard let code = verifyObject.value else {
            return false
        }
        ///TODO::fixme change to deeplink
        let info : [String:String] = ["verifyCode" : code]
        let notification = Notification(name: .customUrlSchema,
                                        object: nil,
                                        userInfo: info)
        NotificationCenter.default.post(notification)
                
        return true
    }
    
    @available(iOS, deprecated: 13, message: "This method will not get called on iOS 13, move the code to WindowSceneDelegate.sceneDidEnterBackground()" )
    func applicationDidEnterBackground(_ application: UIApplication) {
        self.currentState = .background
        keymaker.updateAutolockCountdownStart()
        
        let users: UsersManager = sharedServices.get()
        let queueManager: QueueManager = sharedServices.get()
        //TODO: - v4 set background remaining time to queue manager
        
        var taskID = UIBackgroundTaskIdentifier(rawValue: 0)
        taskID = application.beginBackgroundTask {
            PMLog.D("Background Task Timed Out")
        }
        let delayedCompletion: ()->Void = {
            PMLog.D("End Background Task")
            application.endBackgroundTask(taskID)
            taskID = .invalid
        }
        
        if let user = users.firstUser {
            user.messageService.purgeOldMessages()
            user.cacheService.cleanOldAttachment()
            user.messageService.updateMessageCount()
            
            let maxium = min(10, application.backgroundTimeRemaining)
            let limitation = Date().timeIntervalSinceNow + maxium
            queueManager.backgroundFetch(allowedTime: limitation) {
                delayedCompletion()
            }
        } else {
            delayedCompletion()
        }
        PMLog.D("Enter Background")
    }
    
    @available(iOS, deprecated: 13, message: "This method will not get called on iOS 13, deprecated in favor of similar method in WindowSceneDelegate" )
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    {
        if let data = userActivity.userInfo?["deeplink"] as? Data,
            let deeplink = try? JSONDecoder().decode(DeepLink.self, from: data)
        {
            self.coordinator.followDeeplink(deeplink)
        }
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        //TODO::here need change to notify composer to save editing draft
        let coreDataService = sharedServices.get(by: CoreDataService.self)
        
        let rootContext = coreDataService.rootSavingContext
        rootContext.performAndWait {
            let _ = rootContext.saveUpstreamIfNeeded()
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        self.currentState = .active
        let users: UsersManager = sharedServices.get()
        let queueManager = sharedServices.get(by: QueueManager.self)
        if users.firstUser != nil {
            queueManager.enterForeground()
        }
    }
    
    // MARK: Background methods
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // this feature can only work if user did not lock the app
        let signInManager = SignInManagerProvider()
        let unlockManager = UnlockManagerProvider()
        guard signInManager.isSignedIn, unlockManager.isUnlocked else {
            completionHandler(.noData)
            return
        }
        
        let queueManager = sharedServices.get(by: QueueManager.self)
        let maxium = min(5, application.backgroundTimeRemaining)
        let limitation = Date().timeIntervalSinceNow + maxium
        queueManager.backgroundFetch(allowedTime: limitation) {
            completionHandler(.newData)
        }
    }
    
    // MARK: Notification methods
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Analytics.shared.error(message: .notificationError, error: error)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PMLog.D(deviceToken.stringFromToken())
        let pushService: PushNotificationService = sharedServices.get()
        pushService.didRegisterForRemoteNotifications(withDeviceToken: deviceToken.stringFromToken())
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: UIApplication.shared.keyWindow)
            let statusBarFrame = UIApplication.shared.statusBarFrame
            if (statusBarFrame.contains(point)) {
                self.touchStatusBar()
            }
        }
    }
    
    func touchStatusBar() {
        let notification = Notification(name: .touchStatusBar, object: nil, userInfo: nil)
        NotificationCenter.default.post(notification)
    }

    // MARK: - State restoration
    
    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        if UIDevice.current.stateRestorationPolicy == .multiwindow {
            return false
        } else {
            self.coordinator.saveForRestoration(coder)
            return true
        }
    }
    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        if UIDevice.current.stateRestorationPolicy == .multiwindow {
            // everything is handled by a window scene delegate
        } else if UIDevice.current.stateRestorationPolicy == .deeplink {
            self.coordinator.restoreState(coder)
        }
        
        return false
    }
    
    // MARK: - Multiwindow iOS 13
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration
    {
        let scene = Scenes.fullApp // TODO: add more scenes
        let config = UISceneConfiguration(name: scene.rawValue, sessionRole: connectingSceneSession.role)
        config.delegateClass = scene.delegateClass
        return config
    }
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        sceneSessions.forEach { session in
            // TODO: check that this discards state restoration for scenes explicitely closed by user
            // up to at least iOS 13.3 beta 2 this does not work properly
            session.stateRestorationActivity = nil
            session.scene?.userActivity = nil
        }
    }
    
    // MARK: Shortcuts
    @available(iOS, deprecated: 13, message: "This method will not get called on iOS 13, deprecated in favor of similar method in WindowSceneDelegate" )
    func application(_ application: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void)
    {
        if let data = shortcutItem.userInfo?["deeplink"] as? Data,
            let deeplink = try? JSONDecoder().decode(DeepLink.self, from: data)
        {
            self.coordinator.followDeeplink(deeplink)
        }
        completionHandler(true)
    }
}

extension AppDelegate : UsersManagerDelegate {

    func migrating() {
        
    }
    
    func session() {
        
    }
    
    
}

extension AppDelegate : UnlockManagerDelegate {
    var isUserCredentialStored: Bool {
        get {
            let users = sharedServices.get(by: UsersManager.self)
            if users.isMailboxPasswordStored || users.hasUsers() {
                return true
            }
            return false
        }
    }
    
    func isUserStored() -> Bool {
        let users = sharedServices.get(by: UsersManager.self)
        if users.hasUserName() || users.hasUsers() {
            return true
        }
        return false
    }
    
    func isMailboxPasswordStored(forUser uid: String?) -> Bool {
        let users = sharedServices.get(by: UsersManager.self)
        guard let _ = uid else {
            return users.isPasswordStored || users.hasUserName() //|| users.isMailboxPasswordStored
        }
        return !(sharedServices.get(by: UsersManager.self).users.last?.mailboxPassword ?? "").isEmpty
    }
    
    func cleanAll() {
        ///
        sharedServices.get(by: UsersManager.self).clean().cauterize()
        keymaker.wipeMainKey()
        keymaker.mainKeyExists()
    }
    
    func unlocked() {
        // should work via messages
    }
}
