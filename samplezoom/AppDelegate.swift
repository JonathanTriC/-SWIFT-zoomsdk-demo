import UIKit
import MobileRTC
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let sdkKey = "Jwdp8A1p7pur6gPlgugOPbkJhFqM4roRGOxl"
    let sdkSecret = "wylA6G5jzkzin7gAApFUIr0Q77gmlZVAB9cT"
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupSDK(sdkKey: sdkKey, sdkSecret: sdkSecret)
        return true
    }
    // Logs the user out of the app upon application termination.
        // This is not a necessary action. In real use cases, the SDK should be alerted of app events. For example, in applicationWillTerminate(_ application: UIApplication), MobileRTC.shared().appWillTerminate should be called.
        func applicationWillTerminate(_ application: UIApplication) {
            // Obtain the MobileRTCAuthService from the Zoom SDK, this service can log in a Zoom user, log out a Zoom user, authorize the Zoom SDK etc.
            if let authorizationService = MobileRTC.shared().getAuthService() {
                // Call logoutRTC() to log the user out.
                authorizationService.logoutRTC()
                // Notify MobileRTC of appWillTerminate call.
                MobileRTC.shared().appWillTerminate()
            }
        }
        func applicationWillResignActive(_ application: UIApplication) {
            // Notify MobileRTC of appWillResignActive call.
            MobileRTC.shared().appWillResignActive()
        }
        func applicationDidBecomeActive(_ application: UIApplication) {
            // Notify MobileRTC of appDidBecomeActive call.
            MobileRTC.shared().appDidBecomeActive()
        }
        func applicationDidEnterBackground(_ application: UIApplication) {
            // Notify MobileRTC of appDidEnterBackgroud call.
            MobileRTC.shared().appDidEnterBackgroud()
        }
    func setupSDK(sdkKey: String, sdkSecret: String) {
        // Create a MobileRTCSDKInitContext. This class contains attributes for determining how the SDK will be used. You must supply the context with a domain.
        let context = MobileRTCSDKInitContext()
        // The domain we will use is zoom.us
        context.domain = "zoom.us"
        // Turns on SDK logging. This is optional.
        context.enableLog = true
        // Call initialize(_ context: MobileRTCSDKInitContext) to create an instance of the Zoom SDK. Without initialization, the SDK will not be operational. This call will return true if the SDK was initialized successfully.
        let sdkInitializedSuccessfully = MobileRTC.shared().initialize(context)
        // Check if initialization was successful. Obtain a MobileRTCAuthService, this is for supplying credentials to the SDK for authorization.
        if sdkInitializedSuccessfully == true, let authorizationService = MobileRTC.shared().getAuthService() {
// Supply the SDK with SDK Key and SDK Secret.
// To use a JWT instead, replace these lines with authorizationService.jwtToken = yourJWTToken.
            authorizationService.clientKey = sdkKey
            authorizationService.clientSecret = sdkSecret
            // Assign AppDelegate to be a MobileRTCAuthDelegate to listen for authorization callbacks.
            authorizationService.delegate = self
            // Call sdkAuth to perform authorization.
            authorizationService.sdkAuth()
        }
    }
}
// MARK: - MobileRTCAuthDelegate
// Conform AppDelegate to MobileRTCAuthDelegate.
// MobileRTCAuthDelegate listens to authorization events like SDK authorization, user login, etc.
extension AppDelegate: MobileRTCAuthDelegate {
    // Result of calling sdkAuth(). MobileRTCAuthError_Success represents a successful authorization.
    func onMobileRTCAuthReturn(_ returnValue: MobileRTCAuthError) {
        switch returnValue {
        case .success:
            print("SDK successfully initialized.")
        case .keyOrSecretEmpty:
            assertionFailure("SDK Key/Secret was not provided. Replace sdkKey and sdkSecret at the top of this file with your SDK Key/Secret.")
        case .keyOrSecretWrong, .unknown:
            assertionFailure("SDK Key/Secret is not valid.")
        default:
            assertionFailure("SDK Authorization failed with MobileRTCAuthError: (returnValue).")
        }
    }
  }

