//
//  HTViewController.swift
//  Fastboard
//
//  Created by xuyunshi on 2023/8/29.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import Fastboard
import Whiteboard

class HTViewController: UIViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    
    var fastRoom: FastRoom!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        performJoinRoom()
        setupGesture()
        applyTheme()
        
        // DEBUG
        helpFunction()
    }
    
    @objc func onSwipeGesture(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .left:
            fastRoom.room?.dispatchDocsEvent(.nextPage, options: nil, completionHandler: { _ in })
        case .right:
            fastRoom.room?.dispatchDocsEvent(.prevPage, options: nil, completionHandler: { _ in })
        default: return
        }
    }
    
    func setupGesture() {
        fastRoom.view.addGestureRecognizer(leftSwipeGesture)
        fastRoom.view.addGestureRecognizer(rightSwipeGesture)
    }
    
    func helpFunction() {
        let btn = UIButton(type: .system)
        view.addSubview(btn)
        btn.setTitle("Insert Debug ppt", for: .normal)
        btn.addTarget(self, action: #selector(addTestPPT), for: .touchUpInside)
        btn.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(44)
            make.centerX.equalToSuperview()
        }
        
        let closeBtn = UIButton(type: .system)
        view.addSubview(closeBtn)
        closeBtn.setTitle("Close All", for: .normal)
        closeBtn.addTarget(self, action: #selector(closeAll), for: .touchUpInside)
        closeBtn.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(88)
            make.centerX.equalToSuperview()
        }
    }
    
    @objc func closeAll() {
        fastRoom.room?.queryAllApps(completionHandler: { dic, error in
            if let _ = error { return }
            dic.keys.forEach {
                self.fastRoom.room?.closeApp($0, completionHandler: {
                })
            }
        })
    }
    
    @objc func addTestPPT() {
        fastRoom.insertPptx(
            uuid: "73cceb3365f44264a5bdb3907bf16056",
            url: "https://convertcdn.netless.link/dynamicConvert",
            title: "Test PPT") { appId in
            }
    }

    func setupViews() {
        view.backgroundColor = .gray
        let windowRatio: CGFloat = htContainerRatio
        let config: FastRoomConfiguration = FastRoomConfiguration(appIdentifier: RoomInfo.APPID.value,
                                                                  roomUUID: RoomInfo.ROOMUUID.value,
                                                                  roomToken: RoomInfo.ROOMTOKEN.value,
                                                                  region: .CN,
                                                                  userUID: "some-unique-id-xxx")
        Fastboard.globalFastboardRatio = windowRatio
        config.customOverlay = HTOverlay()
        config.whiteRoomConfig.windowParams?.fullscreen = true
        let fastRoom = Fastboard.createFastRoom(withFastRoomConfig: config)
        fastRoom.delegate = self
        let fastRoomView = fastRoom.view
        fastRoomView.backgroundColor = .black
        view.autoresizesSubviews = true
        view.addSubview(fastRoomView)
        fastRoomView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(fastRoomView.snp.width).multipliedBy(1 / windowRatio)
        }
        self.fastRoom = fastRoom
        
        view.addSubview(drawingButton)
        drawingButton.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
    
    func applyTheme() {
        let customTheme = FastRoomDefaultTheme.defaultDarkTheme
        customTheme.controlBarAssets = .init(backgroundColor: .clear, borderColor: .clear)
        FastRoomControlBar.appearance().borderWidth = 0
        FastRoomControlBar.appearance().commonRadius = 0
        FastRoomControlBar.appearance().itemWidth = view.bounds.width / 7
        
        FastRoomThemeManager.shared.updateIcons(using: .main)
        FastRoomThemeManager.shared.apply(customTheme)
    }
    
    func performJoinRoom() {
        let activity: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            activity = UIActivityIndicatorView(activityIndicatorStyle: .medium)
            activity.color = .white
        } else {
            activity = UIActivityIndicatorView(activityIndicatorStyle: .white)
        }
        fastRoom.view.addSubview(activity)
        activity.snp.makeConstraints { $0.center.equalToSuperview() }
        drawingButton.isHidden = true
        activity.startAnimating()
        fastRoom.joinRoom { [weak self] _ in
            self?.drawingButton.isHidden = false
            self?.update(editable: false)
            activity.stopAnimating()
        }
    }

    func update(editable: Bool) {
        fastRoom.setAllPanel(hide: !editable)
        fastRoom.room?.disableDeviceInputs(!editable)
        [rightSwipeGesture, leftSwipeGesture]
            .forEach { $0.isEnabled = !editable }
    }
    
    @objc
    func onClickDrawing(_ sender: UIButton) {
        sender.isSelected.toggle()
        
        let editing = sender.isSelected
        sender.backgroundColor = editing ? .lightGray : .clear
        sender.tintColor = editing ? .darkGray : .lightGray
        update(editable: editing)
    }
    
    lazy var drawingButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.addTarget(self, action: #selector(onClickDrawing), for: .touchUpInside)
        if #available(iOS 13.0, *) {
            btn.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        }
        btn.tintColor = .lightGray
        btn.clipsToBounds = true
        btn.layer.cornerRadius = 4
        return btn
    }()
    
    lazy var leftSwipeGesture: UISwipeGestureRecognizer = {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeGesture))
        swipe.direction = .left
        swipe.delegate = self
        return swipe
    }()
    
    lazy var rightSwipeGesture: UISwipeGestureRecognizer = {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeGesture))
        swipe.direction = .right
        swipe.delegate = self
        return swipe
    }()
}

extension HTViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

extension HTViewController: FastRoomDelegate {
    func fastboardDidJoinRoomSuccess(_ fastboard: FastRoom, room: WhiteRoom) {
        return
    }
    
    func fastboardDidOccurError(_ fastboard: FastRoom, error: FastRoomError) {
        return
    }
    
    func fastboardUserKickedOut(_ fastboard: FastRoom, reason: String) {
        return
    }
    
    func fastboardPhaseDidUpdate(_ fastboard: FastRoom, phase: FastRoomPhase) {
        return
    }
}
