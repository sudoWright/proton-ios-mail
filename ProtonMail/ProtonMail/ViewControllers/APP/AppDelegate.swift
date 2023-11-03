//
//  AppDelegate.swift
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

import BackgroundTasks
import Intents
import LifetimeTracker
import ProtonCoreCrypto
import ProtonCoreCryptoGoImplementation
import ProtonCoreDataModel
import ProtonCoreDoh
import ProtonCoreFeatureSwitch
import ProtonCoreKeymaker
import ProtonCoreLog
import ProtonCoreNetworking
import ProtonCoreObservability
import ProtonCorePayments
import ProtonCoreServices
import ProtonCoreUIFoundations
import ProtonMailAnalytics
import SideMenuSwift
import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder {
    lazy var coordinator: WindowsCoordinator = {
        let coordinator = WindowsCoordinator(dependencies: dependencies)
        coordinator.delegate = self
        return coordinator
    }()
    private var currentState: UIApplication.State = .active

    // TODO: make private
    let dependencies = GlobalContainer()

    private var springboardShortcutsService: SpringboardShortcutsService!

    override init() {
        injectDefaultCryptoImplementation()
        super.init()
    }
}

// MARK: - consider move this to coordinator
extension AppDelegate {
    func onLogout() {
            let sessions = Array(UIApplication.shared.openSessions)
            let oneToStay = sessions.first(where: { $0.scene?.delegate as? WindowSceneDelegate != nil })
            (oneToStay?.scene?.delegate as? WindowSceneDelegate)?.coordinator.go(dest: .signInWindow(.form))

            for session in sessions where session != oneToStay {
                UIApplication.shared.requestSceneSessionDestruction(session, options: nil) { _ in }
            }
    }
}

extension AppDelegate: TrustKitUIDelegate {
    func onTrustKitValidationError(_ alert: UIAlertController) {
        let currentWindow: UIWindow? = {
                let session = UIApplication.shared.openSessions.first { $0.scene?.activationState == UIScene.ActivationState.foregroundActive }
                let scene = session?.scene as? UIWindowScene
                let window = scene?.windows.first
                return window
        }()

        guard let top = currentWindow?.topmostViewController(), !(top is UIAlertController) else { return }
        top.present(alert, animated: true, completion: nil)
    }
}

// MARK: - UIApplicationDelegate
extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let appVersion = Bundle.main.appVersion
        let message = "\(#function) data available: \(UIApplication.shared.isProtectedDataAvailable) | \(appVersion)"
        SystemLogger.log(message: message, category: .appLifeCycle)

        let appCache = AppCacheService(dependencies: dependencies)
        appCache.restoreCacheWhenAppStart()

        sharedServices.add(UserCachedStatus.self, for: userCachedStatus)

        let coreKeyMaker = dependencies.keyMaker
        sharedServices.add(Keymaker.self, for: coreKeyMaker)
        sharedServices.add(KeyMakerProtocol.self, for: coreKeyMaker)

        if ProcessInfo.isRunningUnitTests {
            // swiftlint:disable:next force_try
            try! CoreDataStore.shared.initialize()

            coreKeyMaker.wipeMainKey()
            coreKeyMaker.activate(NoneProtection()) { _ in }
        }

        let usersManager = dependencies.usersManager
        let queueManager = dependencies.queueManager
        sharedServices.add(QueueManager.self, for: queueManager)

        let unlockManager = dependencies.unlockManager
        unlockManager.delegate = self

        springboardShortcutsService = .init(dependencies: dependencies)

        sharedServices.add(UsersManager.self, for: usersManager)
        sharedServices.add(PushNotificationService.self, for: dependencies.pushService)
        sharedServices.add(NotificationCenter.self, for: NotificationCenter.default)

#if DEBUG
        if ProcessInfo.isRunningUnitTests {
            sharedServices.add(CoreDataContextProviderProtocol.self, for: CoreDataService.shared)
            sharedServices.add(CoreDataService.self, for: CoreDataService.shared)
        } else {
            let lifetimeTrackerIntegration = LifetimeTrackerDashboardIntegration(
                visibility: .visibleWithIssuesDetected,
                style: .circular
            )
            LifetimeTracker.setup(onUpdate: lifetimeTrackerIntegration.refreshUI)
        }
        
        FeatureFactory.shared.disable(&.dynamicPlans)
#endif

        SecureTemporaryFile.cleanUpResidualFiles()

        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SystemLogger.log(message: #function, category: .appLifeCycle)
        #if DEBUG
        if ProcessInfo.isRunningUITests {
            UIView.setAnimationsEnabled(false)
        }
        #endif
        PMAPIService.setupTrustIfNeeded()
        configureCrypto()
        configureCoreObservability()
        configureAnalytics()
        configureAppearance()
        DFSSetting.enableDFS = true
        DFSSetting.limitToXXXLarge = true
        self.configureLanguage()
        /// configurePushService needs to be called in didFinishLaunchingWithOptions to make push
        /// notification actions work. This is because the app could be inactive when an action is triggered
        /// and `didFinishLaunchingWithOptions` will be called, but other functions
        /// like `applicationWillEnterForeground` won't.
        self.configurePushService(launchOptions: launchOptions)
        self.registerKeyMakerNotification()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didSignOutNotification),
                                               name: .didSignOutLastAccount,
                                               object: nil)
        
        dependencies.backgroundTaskHelper.registerBackgroundTask(task: .eventLoop)

        UIBarButtonItem.enableMenuSwizzle()
        #if DEBUG
        setupUITestsMocks()
        #endif
        return true
    }

    @objc fileprivate func didSignOutNotification() {
        self.onLogout()
    }

    func application(
          _ application: UIApplication,
          supportedInterfaceOrientationsFor window: UIWindow?
      ) -> UIInterfaceOrientationMask {
          let viewController = window?.rootViewController
          if UIDevice.current.userInterfaceIdiom == .pad || viewController == nil {
              return UIInterfaceOrientationMask.all
          }
          if viewController as? CoordinatorKeepingViewController<LockCoordinator> != nil {
              return .portrait
          }
          return .all
      }

    @available(iOS, deprecated: 13, message: "This method will not get called on iOS 13, move the code to WindowSceneDelegate.sceneDidEnterBackground()" )
    func applicationDidEnterBackground(_ application: UIApplication) {
        self.currentState = .background

        startAutoLockCountDownIfNeeded()
        
        dependencies.backgroundTaskHelper.scheduleBackgroundRefreshIfNeeded(task: .eventLoop)

        var taskID = UIBackgroundTaskIdentifier(rawValue: 0)
        taskID = application.beginBackgroundTask { }
        let delayedCompletion: () -> Void = {
            application.endBackgroundTask(taskID)
            taskID = .invalid
        }

        if let user = dependencies.usersManager.firstUser {
            user.cacheService.cleanOldAttachment()

            dependencies.queueManager.backgroundFetch(remainingTime: {
                application.backgroundTimeRemaining
            }, notify: {
                delayedCompletion()
            })
        } else {
            delayedCompletion()
        }
        BackgroundTimer.shared.willEnterBackgroundOrTerminate()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        BackgroundTimer().willEnterBackgroundOrTerminate()
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        Crypto.freeGolangMem()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        dependencies.pushService.registerIfAuthorized()
        self.currentState = .active
        if let user = dependencies.usersManager.firstUser {
            dependencies.queueManager.enterForeground()
            user.refreshFeatureFlags()
            user.blockedSenderCacheUpdater.requestUpdate()
        }
    }

    // MARK: Notification methods
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if ProcessInfo.isRunningUnitTests {
            return
        }
        dependencies.pushService.didRegisterForRemoteNotifications(withDeviceToken: deviceToken.stringFromToken())
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        dependencies.pushUpdater.update(with: userInfo)
        completionHandler(.newData)
    }

    // MARK: - Multiwindow iOS 13

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let scene = Scenes.fullApp // TODO: add more scenes
        let config = UISceneConfiguration(name: scene.rawValue, sessionRole: connectingSceneSession.role)
        config.delegateClass = scene.delegateClass
        return config
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        sceneSessions.forEach { session in
            // TODO: check that this discards state restoration for scenes explicitely closed by user
            // up to at least iOS 13.3 beta 2 this does not work properly
            session.stateRestorationActivity = nil
            session.scene?.userActivity = nil
        }
    }

    private func startAutoLockCountDownIfNeeded() {
        let coreKeyMaker = dependencies.keyMaker
        // When the app is launched without a lock set, the lock counter will immediately remove the mainKey, which triggers the app to display the lock screen.
        // However, this behavior is not necessary if there is no lock set.
        // We should only start the countdown when a lock has been set.
        guard coreKeyMaker.isProtectorActive(PinProtection.self) ||
                coreKeyMaker.isProtectorActive(BioProtection.self)
        else {
            return
        }
        coreKeyMaker.updateAutolockCountdownStart()
    }
}

extension AppDelegate: UnlockManagerDelegate, WindowsCoordinatorDelegate {
    func isUserStored() -> Bool {
        let users = dependencies.usersManager
        if users.hasUserName() || users.hasUsers() {
            return true
        }
        return false
    }

    func isMailboxPasswordStored(forUser uid: String?) -> Bool {
        let users = dependencies.usersManager
        guard let _ = uid else {
            return users.isPasswordStored || users.hasUserName() // || users.isMailboxPasswordStored
        }
        return !(dependencies.usersManager.users.last?.mailboxPassword.value ?? "").isEmpty
    }

    func cleanAll(completion: @escaping () -> Void) {
        guard dependencies.usersManager.hasUsers() else {
            completion()
            return
        }
        Breadcrumbs.shared.add(message: "AppDelegate.cleanAll called", to: .randomLogout)
        dependencies.usersManager.clean().ensure {
            completion()
        }.cauterize()
    }

    func setupCoreData() throws {
        try CoreDataStore.shared.initialize()

        sharedServices.add(CoreDataContextProviderProtocol.self, for: CoreDataService.shared)
        sharedServices.add(CoreDataService.self, for: CoreDataService.shared)
        let lastUpdatedStore = dependencies.lastUpdatedStore
        sharedServices.add(LastUpdatedStore.self, for: lastUpdatedStore)
        sharedServices.add(LastUpdatedStoreProtocol.self, for: lastUpdatedStore)
    }

    func loadUserDataAfterUnlock() {
        let usersManager = dependencies.usersManager
        usersManager.run()
        usersManager.tryRestore()

        DispatchQueue.global().async {
            usersManager.users.forEach {
                $0.messageService.injectTransientValuesIntoMessages()
            }
        }

        if let primaryUser = usersManager.firstUser {
            primaryUser.payments.storeKitManager.retryProcessingAllPendingTransactions(finishHandler: nil)
        }
    }
}

// MARK: Appearance
extension AppDelegate {
    private var backArrowImage: UIImage {
        IconProvider.arrowLeft.withRenderingMode(.alwaysTemplate)
    }

    private func configureAppearance() {
        UINavigationBar.appearance().backIndicatorImage = IconProvider.arrowLeft.withRenderingMode(.alwaysTemplate)
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = IconProvider.arrowLeft.withRenderingMode(.alwaysTemplate)
        if #available(iOS 15.0, *) {
            setupNavigationBarAppearance()
            UITableView.appearance().sectionHeaderTopPadding = .zero
        }
    }

    @available(iOS 15.0, *)
    private func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = ColorProvider.BackgroundNorm
        appearance.shadowColor = .clear
        appearance.setBackIndicatorImage(backArrowImage, transitionMaskImage: backArrowImage)
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = appearance
    }
}

// MARK: Launch configuration
extension AppDelegate {

    private func configureAnalytics() {
#if Enterprise
    #if DEBUG
        Analytics.shared.setup(isInDebug: true, environment: .enterprise)
    #else
        Analytics.shared.setup(isInDebug: false, environment: .enterprise)
    #endif
#else
    #if DEBUG
        Analytics.shared.setup(isInDebug: true, environment: .production)
    #else
        Analytics.shared.setup(isInDebug: false, environment: .production)
    #endif
#endif
    }

    private func configureCrypto() {
        Crypto().initializeGoCryptoWithDefaultConfiguration()
    }

    private func configureCoreObservability() {
        ObservabilityEnv.current.setupWorld(
            requestPerformer: PMAPIService.unauthorized(
                keyMaker: dependencies.keyMaker,
                userDefaults: dependencies.userDefaults
            )
        )
    }

    private func configureLanguage() {
        LanguageManager().storePreferredLanguageToBeUsedByExtensions()
    }

    private func configurePushService(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        let pushService = dependencies.pushService
        UNUserNotificationCenter.current().delegate = pushService
        pushService.registerForRemoteNotifications()
        pushService.setNotificationFrom(launchOptions: launchOptions)
    }

    private func registerKeyMakerNotification() {
        #if DEBUG
        NotificationCenter.default
            .addObserver(forName: Keymaker.Const.errorObtainingMainKey,
                         object: nil,
                         queue: .main) { notification in
                (notification.userInfo?["error"] as? Error)?.localizedDescription.alertToast()
            }

        NotificationCenter.default
            .addObserver(forName: Keymaker.Const.removedMainKeyFromMemory,
                         object: nil,
                         queue: .main) { notification in
                "Removed main key from memory".alertToastBottom()
            }
        #endif

        NotificationCenter.default
            .addObserver(forName: Keymaker.Const.obtainedMainKey,
                         object: nil,
                         queue: .main) { notification in
                #if DEBUG
                "Obtained main key".alertToastBottom()
                #endif

                if self.currentState != .active {
                    self.dependencies.keyMaker.updateAutolockCountdownStart()
                }
            }
    }
}

#if DEBUG
extension AppDelegate {

    private func setupUITestsMocks() {
        let environment = ProcessInfo.processInfo.environment
        if let _ = environment["HumanVerificationStubs"] {
            HumanVerificationManager.shared.setupUITestsMocks()
        } else if let _ = environment["ForceUpgradeStubs"] {
            ForceUpgradeManager.shared.setupUITestsMocks()
        }
    }
}
#endif
