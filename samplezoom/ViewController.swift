import UIKit
import MobileRTC

class ViewController: UIViewController, MeetingDelegate, MobileRTCMeetingServiceDelegate {
    func onJoinMeeting() {
        hideActivityIndicator()
    }
    
    
    var spinner = UIActivityIndicatorView(style: .whiteLarge)
    var loadingView: UIView = UIView()

    lazy var joinMeetingButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Join meeting", for: .normal)
        button.addTarget(self, action: #selector(joinMeetingButtonPressed(_:)), for: .touchUpInside)
//        button.isEnabled = false
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        
        return button
    }()
    
    lazy var customMeetingUIViewController: CustomMeetingUIViewController = {
        let vc = CustomMeetingUIViewController()
        vc.meetingDelegate = self
        vc.modalPresentationStyle = .overFullScreen
        vc.delegate = self
        return vc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        joinMeetingButton.center.x = view.center.x
        joinMeetingButton.center.y = view.center.y
        view.addSubview(joinMeetingButton)
        
        let sdkInitContext = MobileRTCSDKInitContext()
        sdkInitContext.domain = "https://zoom.us"
        sdkInitContext.enableLog = true
        
        if MobileRTC.shared().initialize(sdkInitContext) {
            if let authService = MobileRTC.shared().getAuthService() {
                authService.delegate = self
                
                authService.jwtToken = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOm51bGwsImlzcyI6IjdrbjkwZE9xUkR1THh1amJORk03RXciLCJleHAiOi02Mjc1NjE3NTIsImlhdCI6MTY1MDQyMDg4M30.dEW_1yymnIpN6KbSjusrysUvqogTYSdXbOfjJSD3I9g"
            
                authService.sdkAuth()
            }
        }
    }
    
    func showActivityIndicator() {
        DispatchQueue.main.async {
            self.loadingView = UIView()
            self.loadingView.frame = CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0)
            self.loadingView.center = self.view.center
            if #available(iOS 11.0, *) {
                self.loadingView.backgroundColor = UIColor(red: 0.26, green: 0.26, blue: 0.26, alpha: 0.7)
            } else {
                // Fallback on earlier versions
            }
            self.loadingView.alpha = 0.7
            self.loadingView.clipsToBounds = true
            self.loadingView.layer.cornerRadius = 10

            self.spinner = UIActivityIndicatorView(style: .whiteLarge)
            self.spinner.frame = CGRect(x: 0.0, y: 0.0, width: 80.0, height: 80.0)
            self.spinner.center = CGPoint(x:self.loadingView.bounds.size.width / 2, y:self.loadingView.bounds.size.height / 2)

            self.loadingView.addSubview(self.spinner)
            self.view.addSubview(self.loadingView)
            self.spinner.startAnimating()
        }
    }
    
    func hideActivityIndicator() {
        print("hide loading")
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
            self.loadingView.removeFromSuperview()
        }
    }
    
    func joinMeeting() {
        guard let meetingService = MobileRTC.shared().getMeetingService(),
              let meetingSettings = MobileRTC.shared().getMeetingSettings() else { return }
        
//        meetingService.delegate = customMeetingUIViewController
//        meetingService.customizedUImeetingDelegate = self
        
        meetingService.delegate = self
        
//        meetingSettings.enableCustomMeeting = true
//        meetingSettings.bottomBarHidden = true
//        meetingSettings.topBarHidden = true
        meetingSettings.setAutoConnectInternetAudio(true)
        meetingSettings.setMuteVideoWhenJoinMeeting(true)
        meetingSettings.setMuteAudioWhenJoinMeeting(true)
        
        let joinParams = MobileRTCMeetingJoinParam()
//        joinParams.meetingNumber = "4677642404"
        joinParams.meetingNumber = "9259080566"
        joinParams.password = "123456"
        let joinMeetingReturnValue = meetingService.joinMeeting(with: joinParams)
        
        switch joinMeetingReturnValue {
        case .success:
            print("Joining meeting.")
        case .inAnotherMeeting:
            print("User is in another meeting.")
            if #available(iOS 13.0, *) {
                showAlert(with: "User is in another meeting.")
            } else {
                // Fallback on earlier versions
            }
        default:
            print("Error joining meeting: \(joinMeetingReturnValue.rawValue)")
        }
//        hideActivityIndicator()
    }
    

    @objc func joinMeetingButtonPressed(_ sender: UIButton) {
        print("join meeting button pressed")
//        showActivityIndicator()
        joinMeeting()
    }
}

extension ViewController: MobileRTCAuthDelegate {
    
    func onMobileRTCAuthReturn(_ returnValue: MobileRTCAuthError) {
        switch returnValue {
        case .success:
            print("SDK authed successfully.")
        default:
            print("Error authing SDK: \(returnValue.rawValue)")
        }
    }
}

//extension ViewController: MobileRTCMeetingServiceDelegate {
//    // Is called upon in-meeting errors, join meeting errors, start meeting errors, meeting connection errors, etc.
//    func onMeetingError(_ error: MobileRTCMeetError, message: String?) {
//        print("Meeting error: (error), message: (String(describing: message))")
//    }
//    // Is called when the user joins a meeting.
//    func onJoinMeetingConfirmed() {
//        print("Join meeting confirmed.")
//    }
//    // Is called upon meeting state changes.
//    func onMeetingStateChange(_ state: MobileRTCMeetingState) {
//        print("Current meeting state: (state)")
//    }
//}

extension ViewController: MobileRTCCustomizedUIMeetingDelegate {
    
    func onInitMeetingView() {
        
    }
    
    func onDestroyMeetingView() {
        
    }
}

extension ViewController: CustomMeetingUIViewControllerDelegate {
    
    func userWasAdmittedFromTheWaitingRoom() {
        DispatchQueue.main.async { [weak self] in
            if let strongSelf = self {
                strongSelf.modalPresentationStyle = .overFullScreen
                strongSelf.present(strongSelf.customMeetingUIViewController, animated: true, completion: nil)
            }
        }
    }
}

@available(iOS 13.0, *)
extension UIViewController {
    
    func showAlert(with title: String, and message: String? = nil, action: UIAlertAction? = nil) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            if let action = action {
                alertController.addAction(action)
            }
            
            let keyWindow = UIApplication.shared.connectedScenes
                    .filter({$0.activationState == .foregroundActive})
                    .compactMap({$0 as? UIWindowScene})
                    .first?.windows
                    .filter({$0.isKeyWindow}).first
            var rootViewController = keyWindow?.rootViewController
            if let navigationController = rootViewController as? UINavigationController {
                rootViewController = navigationController.viewControllers.first
            }
            
            
            rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }
}


