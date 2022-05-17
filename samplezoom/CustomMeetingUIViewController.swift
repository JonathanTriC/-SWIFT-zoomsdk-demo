import Foundation
import MobileRTC

protocol CustomMeetingUIViewControllerDelegate: NSObject {
    
    func userWasAdmittedFromTheWaitingRoom()
}

class CustomMeetingUIViewController: UIViewController {
    
    weak var delegate: CustomMeetingUIViewControllerDelegate?
    
    var meetingDelegate: MeetingDelegate?
    
    var screenWidth: CGFloat {
        return view.frame.width
    }
    
    var screenHeight: CGFloat {
        return view.frame.height
    }
    
    var spinner = UIActivityIndicatorView(style: .whiteLarge)
    var loadingView: UIView = UIView()
    
    lazy var localUserView: MobileRTCVideoView = {
        let videoView = MobileRTCVideoView(frame: CGRect(x: 15.0, y: 0.0, width: screenWidth - 30, height: (screenHeight / 4)))
        videoView.setVideoAspect(MobileRTCVideoAspect_PanAndScan)
        
        return videoView
    }()
    
    lazy var remoteUserView: MobileRTCVideoView = {
        let videoView = MobileRTCVideoView(frame: CGRect(x: 15.0, y: ((screenHeight / 4) + 15), width: screenWidth - 30, height: (screenHeight / 4)))
        videoView.setVideoAspect(MobileRTCVideoAspect_PanAndScan)

        return videoView
    }()
    
    lazy var activeVideoView: MobileRTCActiveShareView = {
        
        let videoView = MobileRTCActiveShareView(frame: CGRect(x: 15.0, y: (((screenHeight / 4) * 2) + 30), width: screenWidth - 30, height: (screenHeight / 4)))
        videoView.setVideoAspect(MobileRTCVideoAspect_PanAndScan)
        return videoView
    }()
    
    lazy var buttonContainerScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceHorizontal = true
        
        return scrollView
    }()
    
    lazy var buttonStackViewView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.axis = .horizontal
        stackView.spacing = 5
        
        return stackView
    }()
    
    @objc lazy var leaveMeetingButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Leave Meeting", for: .normal)
        button.addTarget(self, action: #selector(leaveMeeting), for: .touchUpInside)
        if #available(iOS 14.0, *) {
            button.addAction(UIAction(handler: { _ in
                self.dismiss(animated: true, completion: nil)
            }), for: .touchUpInside)
        } else {
            // Fallback on earlier versions
        }
        
        return button
    }()
    
    lazy var toggleMuteAudioButton: UIButton = {
        let button = UIButton(type: .system)
        let title = (MobileRTC.shared().getMeetingService()?.isMyAudioMuted() ?? true) ? "Unmute" : "Mute"
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(toggleMuteAudio), for: .touchUpInside)
        
        return button
    }()
    
    lazy var toggleMuteVideoButton: UIButton = {
        let button = UIButton(type: .system)
        let title = (MobileRTC.shared().getMeetingService()?.isSendingMyVideo() ?? false) ? "Stop Video" : "Start Video"
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(toggleMuteVideo), for: .touchUpInside)
        
        return button
    }()
    
    override func viewDidLoad() {
//        let value = UIInterfaceOrientation.landscapeLeft.rawValue
//        UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        view.backgroundColor = .black
        meetingDelegate?.onJoinMeeting()
        
        setupVideoViews()
        setupButtons()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("leave button pressed")
        leaveMeeting()
//        MobileRTC.shared().getMeetingService()?.leaveMeeting(with: .leave)
        hideActivityIndicator()
    }
    
//    override var shouldAutorotate: Bool {
//        return true
//    }
    
    func hideActivityIndicator() {
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
            self.loadingView.removeFromSuperview()
        }
    }
    
    
    func setupVideoViews() {
        guard let localUserID = MobileRTC.shared().getMeetingService()?.myselfUserID() else { return }
        view.addSubview(localUserView)
        localUserView.showAttendeeVideo(withUserID: localUserID)
        
        if let firstRemoteUserID = MobileRTC.shared().getMeetingService()?.getInMeetingUserList()?.first(where: { UInt(truncating: $0) != localUserID }) {
            view.addSubview(remoteUserView)
            remoteUserView.showAttendeeVideo(withUserID: UInt(truncating: firstRemoteUserID))
        }
        
        guard let activeUserID = MobileRTC.shared().getMeetingService()?.activeShareUserID() else { return }
        view.addSubview(activeVideoView)
        activeVideoView.showActiveShare(withUserID: activeUserID)
    }
    
    func setupButtons() {
        view.addSubview(buttonContainerScrollView)
        buttonContainerScrollView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        buttonContainerScrollView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        if #available(iOS 11.0, *) {
            buttonContainerScrollView.bottomAnchor.constraint(equalTo:view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            // Fallback on earlier versions
        }
        buttonContainerScrollView.leadingAnchor.constraint(equalTo:view.leadingAnchor).isActive = true
        buttonContainerScrollView.trailingAnchor.constraint(equalTo:view.trailingAnchor).isActive = true
        
        buttonContainerScrollView.addSubview(buttonStackViewView)
        buttonStackViewView.leadingAnchor.constraint(equalTo: buttonContainerScrollView.leadingAnchor).isActive = true
        buttonStackViewView.trailingAnchor.constraint(equalTo: buttonContainerScrollView.trailingAnchor).isActive = true
        buttonStackViewView.topAnchor.constraint(equalTo: buttonContainerScrollView.topAnchor).isActive = true
        buttonStackViewView.bottomAnchor.constraint(equalTo: buttonContainerScrollView.bottomAnchor).isActive = true
        buttonStackViewView.widthAnchor.constraint(greaterThanOrEqualTo: buttonContainerScrollView.widthAnchor).isActive = true
        
        buttonStackViewView.addArrangedSubview(leaveMeetingButton)
        buttonStackViewView.addArrangedSubview(toggleMuteAudioButton)
        buttonStackViewView.addArrangedSubview(toggleMuteVideoButton)
    }
    
    func updateViews() {
        guard let meetingService = MobileRTC.shared().getMeetingService() else { return }
        let localUserID = meetingService.myselfUserID()
        localUserView.showAttendeeVideo(withUserID: localUserID)

        if let firstRemoteUserID = meetingService.getInMeetingUserList()?.first(where: { UInt(truncating: $0) != localUserID }) {
            remoteUserView.showAttendeeVideo(withUserID: UInt(truncating: firstRemoteUserID))
        }
        let activeUserID = meetingService.getParticipantID()
        activeVideoView.showAttendeeVideo(withUserID: activeUserID)
        
        toggleMuteAudioButton.setTitle(meetingService.isMyAudioMuted() ? "Unmute" : "Mute", for: .normal)
        toggleMuteVideoButton.setTitle(meetingService.isSendingMyVideo() ? "Stop Video" : "Start Video", for: .normal)
    }
    
    @objc func toggleMuteAudio() {
        guard let meetingService = MobileRTC.shared().getMeetingService() else { return }
        
        if meetingService.isMyAudioMuted() {
            meetingService.muteMyAudio(false)
        } else {
            meetingService.muteMyAudio(true)
        }
    }
    
    @objc func toggleMuteVideo() {
        guard let meetingService = MobileRTC.shared().getMeetingService() else { return }
        
        if meetingService.isSendingMyVideo() {
            meetingService.muteMyVideo(true)
        } else {
            meetingService.muteMyVideo(false)
        }
    }
    
    @objc func leaveMeeting() {
        guard let meetingService = MobileRTC.shared().getMeetingService() else { return }
        
        meetingService.leaveMeeting(with: .leave)
        hideActivityIndicator()
    }
}

extension CustomMeetingUIViewController: MobileRTCMeetingServiceDelegate {
    
    func onJBHWaiting(with cmd: JBHCmd) {
        switch cmd {
        case .show:
            print("Joined before host.")
            if #available(iOS 13.0, *) {
                showAlert(with: "Joined before host.", and: "Wait for the host to start the meeting.")
            } else {
                // Fallback on earlier versions
            }
        case .hide:
            print("Hide join before host message.")
        @unknown default:
            print("Unexpected error.")
        }
    }
    
    func onWaitingRoomStatusChange(_ needWaiting: Bool) {
        if needWaiting {
            print("User joined waiting room.")
            if #available(iOS 13.0, *) {
                showAlert(with: "User now in waiting room.", and: "User needs to be admitted by host or leave.", action: UIAlertAction(title: "Leave", style: .default, handler: { _ in
                    MobileRTC.shared().getMeetingService()?.leaveMeeting(with: .leave)
                }))
            } else {
                // Fallback on earlier versions
            }
        } else {
            print("User is entering meeting.")
            delegate?.userWasAdmittedFromTheWaitingRoom()
        }
    }
    
    func onMeetingError(_ error: MobileRTCMeetError, message: String?) {
        switch error {
        case .inAnotherMeeting:
            if #available(iOS 13.0, *) {
                showAlert(with: "User is already in another meeting.")
            } else {
                // Fallback on earlier versions
            }
            print("User is already in another meeting.")
        case .meetingNotExist:
            if #available(iOS 13.0, *) {
                showAlert(with: "Meeting does not exist.")
            } else {
                // Fallback on earlier versions
            }
            meetingDelegate?.onJoinMeeting()
            print("Meeting does not exist")
        case .invalidArguments:
            if #available(iOS 13.0, *) {
                showAlert(with: "One or more of the join meeting params was invalid.")
            } else {
                // Fallback on earlier versions
            }
            print("One or more of the join meeting params was invalid.")
        case .passwordError:
            if #available(iOS 13.0, *) {
                showAlert(with: "Incorrect meeting password.")
            } else {
                // Fallback on earlier versions
            }
            print("Incorrect meeting password.")
        case .success:
            print("Meeting operation was successful.")
        default:
            print("Meeting error: \(error) \(message ?? "")")
        }
    }
    
    func onMeetingStateChange(_ state: MobileRTCMeetingState) {
        switch state {
        case .connecting:
            print("Meeting State: connecting...")
        case .ended:
            hideActivityIndicator()
            print("Meeting State: ended.")
        case .failed:
            print("Meeting State: failed.")
        case .reconnecting:
            print("Meeting State: reconnecting...")
        case .inWaitingRoom:
            print("Meeting State: in waiting room.")
        default:
            break
        }
    }
    
    func onMeetingEndedReason(_ reason: MobileRTCMeetingEndReason) {
        switch reason {
        case .connectBroken:
            print("Meeting ended due to lost connection.")
        case .endByHost:
            if #available(iOS 13.0, *) {
                showAlert2(with: "Meeting was ended by the host.")
            } else {
                // Fallback on earlier versions
            }
            print("Meeting was ended by the host.")
        case .freeMeetingTimeout:
            print("Meeting ended due to free meeting limit being reached.")
        case .selfLeave:
            hideActivityIndicator()
            print("User left meeting.")
        case .removedByHost:
            print("User was removed by host.")
        default:
            print("Meeting ended with reason: \(reason)")
        }
    }
    
    private func onSubscribeUserFail(_ errorCode: Int, size: Int, userId: UInt) {
        print("Failed to subscribe to user video. Error: \(errorCode)")
    }
}

extension CustomMeetingUIViewController: MobileRTCVideoServiceDelegate {
    func onSpotlightVideoUserChange(_ spotlightedUserList: [NSNumber]) {
        print("onSpotlightVideoUserChange")
    }
    
    func onHostVideoOrderUpdated(_ orderArr: [NSNumber]?) {
        print("onHostVideoOrderUpdated")
    }
    
    func onLocalVideoOrderUpdated(_ localOrderArr: [NSNumber]?) {
        print("onLocalVideoOrderUpdated")
    }
    
    func onFollowHostVideoOrderChanged(_ follow: Bool) {
        print("onFollowHostVideoOrderChanged")
    }
    
    func onSinkMeetingActiveVideo(_ userID: UInt) {
        print("Active video status changed.")
        updateViews()
    }
    
    func onSinkMeetingVideoStatusChange(_ userID: UInt) {
        print("User video status changed: \(userID)")
    }
    
    func onMyVideoStateChange() {
        print("Local user's video status changed.")
        updateViews()
    }
    
    func onSinkMeetingVideoStatusChange(_ userID: UInt, videoStatus: MobileRTC_VideoStatus) {
        print("User video status changed: \(userID)")
        updateViews()
    }
    
    func onSpotlightVideoChange(_ on: Bool) {
        print("Spotlight status changed.")
    }
    
    func onSinkMeetingPreviewStopped() {
        print("Meeting preview ended.")
    }
    
    func onSinkMeetingActiveVideo(forDeck userID: UInt) {
        print("Active video user changed")
    }
    
    func onSinkMeetingVideoQualityChanged(_ qality: MobileRTCNetworkQuality, userID: UInt) {
        print("Video quality changed for user: \(userID)")
    }
    
    func onSinkMeetingVideoRequestUnmute(byHost completion: @escaping (Bool) -> Void) {
        print("User was asked to start video by host")
    }
    
    func onSinkMeetingShowMinimizeMeetingOrBackZoomUI(_ state: MobileRTCMinimizeMeetingState) {
        // Only for default UI.
        print("Meeting minimization was toggled. ")
    }
}

@available(iOS 13.0, *)
extension UIViewController {
    
    func showAlert2(with title: String, and message: String? = nil, action: UIAlertAction? = nil) {
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
