//
//  ViewController.swift
//  Fastboard
//
//  Created by yunshi on 12/22/2021.
//  Copyright (c) 2021 yunshi. All rights reserved.
//

import UIKit
import Fastboard
import Whiteboard
import SnapKit

var globalUsingFPA = false

extension WhiteApplianceNameKey: CaseIterable {
    public static var allCases: [WhiteApplianceNameKey] {
        [.ApplianceClicker,
         .AppliancePencil,
         .ApplianceSelector,
         .ApplianceText,
         .ApplianceEllipse,
         .ApplianceRectangle,
         .ApplianceEraser,
         .ApplianceStraight,
         .ApplianceArrow,
         .ApplianceHand,
         .ApplianceLaserPointer
        ]
    }
}

extension WhiteApplianceShapeTypeKey: CaseIterable {
    public static var allCases: [WhiteApplianceShapeTypeKey] {
        [
            .ApplianceShapeTypeTriangle,
            .ApplianceShapeTypeRhombus,
            .ApplianceShapeTypePentagram,
            .ApplianceShapeTypeSpeechBalloon
        ]
    }
}

class ViewController: UIViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .landscape
    }
    
    var fastboard: Fastboard!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    func setupViews() {
        view.backgroundColor = .gray
        setupFastboard()
        setupBottomTools()
        setupMediaTools()
    }
    
    func setupFastboard(custom: FastboardOverlay? = nil) {
        let config: FastConfiguration
        if #available(iOS 13.0, *) {
            config = FastConfiguration(appIdentifier: RoomInfo.APPID.value,
                                           roomUUID: RoomInfo.ROOMUUID.value,
                                           roomToken: RoomInfo.ROOMTOKEN.value,
                                           region: .CN,
                                           userUID: "some-unique-id",
                                           useFPA: true)
        } else {
            // Without fpa
            config = FastConfiguration(appIdentifier: RoomInfo.APPID.value,
                                           roomUUID: RoomInfo.ROOMUUID.value,
                                           roomToken: RoomInfo.ROOMTOKEN.value,
                                           region: .CN,
                                           userUID: "some-unique-id")
        }
        config.customOverlay = custom
        let fastboard = Fastboard(configuration: config)
        fastboard.delegate = self
        let fastboardView = fastboard.view
        view.autoresizesSubviews = true
        view.addSubview(fastboardView)
        fastboardView.snp.makeConstraints { make in
            if #available(iOS 11.0, *) {
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(44)
            } else {
                make.top.equalToSuperview().inset(44)
            }
            make.left.right.equalToSuperview().inset(88)
            make.height.equalTo(fastboardView.snp.width).multipliedBy(1 / FastboardManager.globalFastboardRatio)
        }
        let activity: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            activity = UIActivityIndicatorView(activityIndicatorStyle: .medium)
        } else {
            activity = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        }
        fastboardView.addSubview(activity)
        activity.snp.makeConstraints { $0.edges.equalToSuperview() }
        activity.startAnimating()
        exampleControlView.isHidden = true
        fastboard.joinRoom { _ in
            activity.stopAnimating()
            self.exampleControlView.isHidden = false
        }
        self.fastboard = fastboard
    }
    
    func setupMediaTools() {
        view.addSubview(mediaControlView)
        mediaControlView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(fastboard.view.snp.top)
            make.height.equalTo(44)
        }
    }
    
    func setupBottomTools() {
        view.addSubview(exampleControlView)
        exampleControlView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(fastboard.view.snp.bottom)
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            } else {
                make.bottom.equalToSuperview()
            }
        }
    }
    
    func reloadFastboard(overlay: FastboardOverlay? = nil) {
        fastboard.view.removeFromSuperview()
        exampleControlView.removeFromSuperview()
        setupFastboard(custom: overlay)
        setupBottomTools()
    }
    
    var isHide = false {
        didSet {
            fastboard.setAllPanel(hide: isHide)
            let str = NSLocalizedString(isHide ? "On" : "Off", comment: "")
            exampleItems.first(where: { $0.title == NSLocalizedString("Hide PanelItem", comment: "")})?.status = str
        }
    }
    
    var currentTheme: ExampleTheme = .auto {
        didSet {
            switch currentTheme {
            case .light:
                ThemeManager.shared.apply(DefaultTheme.defaultLightTheme)
            case .dark:
                ThemeManager.shared.apply(DefaultTheme.defaultDarkTheme)
            case .auto:
                if #available(iOS 13, *) {
                    ThemeManager.shared.apply(DefaultTheme.defaultAutoTheme)
                } else {
                    return
                }
            }
        }
    }
    
    func applyNextTheme() -> ExampleTheme {
        let all = ExampleTheme.allCases
        let index = all.firstIndex(of: self.currentTheme)!
        if index == all.count - 1 {
            self.currentTheme = all.first!
        } else {
            let targetCurrentTheme = all[index + 1]
            if targetCurrentTheme == .auto {
                if #available(iOS 13, *) {
                    self.currentTheme = targetCurrentTheme
                } else {
                    self.currentTheme = all.first!
                }
            } else {
                self.currentTheme = targetCurrentTheme
            }
        }
        usingCustomTheme = false
        return self.currentTheme
    }
    
    var usingCustomTheme: Bool = false {
        didSet {
            if usingCustomTheme {
                let white = WhiteboardAssets(whiteboardBackgroundColor: .green, containerColor: .yellow)
                let control = ControlBarAssets(backgroundColor: .blue, borderColor: .gray, effectStyle: .init(style: .regular))
                let panel = PanelItemAssets(normalIconColor: .black, selectedIconColor: .systemRed, highlightBgColor: .cyan, subOpsIndicatorColor: .yellow, pageTextLabelColor: .orange)
                let theme = ThemeAsset(whiteboardAssets: white, controlBarAssets: control, panelItemAssets: panel)
                ThemeManager.shared.apply(theme)
            } else {
                let i = self.currentTheme
                self.currentTheme = i
            }
            exampleItems.first(where: { $0.title == NSLocalizedString("Update User Theme", comment: "") })?.status = NSLocalizedString(usingCustomTheme ? "On" : "Off", comment: "")
        }
    }
    
    var storedColors: [UIColor] = DefaultOperationItem.defaultColors
    var usingCustomPanelItemColor: Bool = false {
        didSet {
            if usingCustomPanelItemColor {
                DefaultOperationItem.defaultColors = [.red, .yellow, .blue]
            } else {
                DefaultOperationItem.defaultColors = storedColors
            }
            self.reloadFastboard(overlay: nil)
            exampleItems.first(where: { $0.title == NSLocalizedString("Custom Pencil Colors", comment: "") })?.status = NSLocalizedString(usingCustomPanelItemColor ? "On" : "Off", comment: "")
        }
    }
    
    var defaultPhoneItems = CompactFastboardOverlay.defaultCompactAppliance
    var usingCustomPhoneItems = false {
        didSet {
            if usingCustomTheme {
                CompactFastboardOverlay.defaultCompactAppliance = [.AppliancePencil, .ApplianceSelector, .ApplianceEraser]
            } else {
                CompactFastboardOverlay.defaultCompactAppliance = defaultPhoneItems
            }
            reloadFastboard(overlay: nil)
            exampleItems.first(where: { $0.title == NSLocalizedString("Update iPhone Items", comment: "") })?.status = NSLocalizedString(usingCustomPhoneItems ? "On" : "Off", comment: "")
        }
    }
    
    var defaultPadItems = RegularFastboardOverlay.customOptionPanel
    var usingCustomPadItems = false {
        didSet {
            if usingCustomPadItems {
                var items: [FastOperationItem] = []
                let shape = SubOpsItem(subOps: RegularFastboardOverlay.shapeItems)
                items.append(shape)
                items.append(DefaultOperationItem.selectableApplianceItem(.AppliancePencil, shape: nil))
                items.append(DefaultOperationItem.clean())
                let panel = FastPanel(items: items)
                RegularFastboardOverlay.customOptionPanel = {
                    return panel
                }
            } else {
                RegularFastboardOverlay.customOptionPanel = defaultPadItems
            }
            reloadFastboard(overlay: nil)
            exampleItems.first(where: { $0.title == NSLocalizedString("Update Pad Items", comment: "") })?.status = NSLocalizedString(usingCustomPadItems ? "On" : "Off", comment: "")
        }
    }
    
    var usingCustomIcons = false {
        didSet {
            if usingCustomIcons {
                ThemeManager.shared.updateIcons(using: Bundle.main)
            } else {
                let path = Bundle(for: FastboardManager.self).path(forResource: "Icons", ofType: "bundle")
                let bundle = Bundle(path: path!)!
                ThemeManager.shared.updateIcons(using: bundle)
            }
            AppearanceManager.shared.commitUpdate()
            reloadFastboard()
            view.isUserInteractionEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.view.isUserInteractionEnabled = true
            }
            exampleItems.first(where: { $0.title == NSLocalizedString("Update Custom Icons", comment: "") })?.status = NSLocalizedString(usingCustomIcons ? "On" : "Off", comment: "")
        }
    }
    
    var usingCustomOverlay = false {
        didSet {
            if usingCustomOverlay {
                self.reloadFastboard(overlay: CustomFastboardOverlay())
                ControlBar.appearance().itemWidth = 66
                AppearanceManager.shared.commitUpdate()
            } else {
                reloadFastboard()
                ControlBar.appearance().itemWidth = 40
                AppearanceManager.shared.commitUpdate()
            }
            exampleItems.first(where: { $0.title == NSLocalizedString("Custom Overlay", comment: "")})?.status = NSLocalizedString(usingCustomOverlay ? "On" : "Off", comment: "")
        }
    }
    
    lazy var exampleItems: [ExampleItem] = {
        var array: [ExampleItem] = [
            .init(title: NSLocalizedString("Reset", comment: ""), status: nil, clickBlock: { [unowned self] _ in
                let vc = ViewController()
                vc.usingCustomTheme = false
                UIApplication.shared.keyWindow?.rootViewController = vc
            }),
            .init(title: NSLocalizedString("Update Default Theme", comment: ""), status: "\(self.currentTheme)", clickBlock: { [unowned self] item in
                item.status = "\(self.applyNextTheme())"
            }),
            .init(title: NSLocalizedString("Update User Theme", comment: ""), status: NSLocalizedString(usingCustomTheme ? "On" : "Off", comment: ""), clickBlock: { [unowned self] _ in
                self.usingCustomTheme = !self.usingCustomTheme
            }),
            .init(title: NSLocalizedString("Custom Pencil Colors", comment: ""), status: NSLocalizedString(usingCustomTheme ? "On" : "Off", comment: ""), clickBlock: { [unowned self] _ in
                self.usingCustomPanelItemColor = !self.usingCustomPanelItemColor
            }),
            .init(title: NSLocalizedString("Update iPhone Items", comment: ""), status: NSLocalizedString(usingCustomPhoneItems ? "On" : "Off", comment: ""), clickBlock: { _ in
                self.usingCustomPhoneItems = !self.usingCustomPhoneItems
            }),
            .init(title: NSLocalizedString("Update Pad Items", comment: ""), status: NSLocalizedString(usingCustomPadItems ? "On" : "Off", comment: ""), clickBlock: { _ in
                self.usingCustomPadItems = !self.usingCustomPadItems
            }),
            .init(title: NSLocalizedString("Update ToolBar Direction", comment: ""), status: NSLocalizedString("Left", comment: ""), clickBlock: { [unowned self] item in
                if FastboardView.appearance().operationBarDirection == .left {
                    FastboardView.appearance().operationBarDirection = .right
                    item.status = NSLocalizedString("Right", comment: "")
                } else {
                    FastboardView.appearance().operationBarDirection = .left
                    item.status = NSLocalizedString("Left", comment: "")
                }
                AppearanceManager.shared.commitUpdate()
            }),
            .init(title: NSLocalizedString("BarSize", comment: ""), status: "40", clickBlock: { item in
                if ControlBar.appearance().itemWidth == 48 {
                    ControlBar.appearance().itemWidth = 40
                } else {
                    ControlBar.appearance().itemWidth = 48
                }
                item.status = ControlBar.appearance().itemWidth.description
                AppearanceManager.shared.commitUpdate()
            }),
            .init(title: NSLocalizedString("Update Custom Icons", comment: ""), status: NSLocalizedString(usingCustomIcons ? "On" : "Off", comment: ""), clickBlock: { [unowned self] _ in
                self.usingCustomIcons = !self.usingCustomIcons
            }),
            .init(title: NSLocalizedString("Hide PanelItem", comment: ""), status: NSLocalizedString(isHide ? "On" : "Off", comment: ""), clickBlock: { [unowned self] _ in
                self.isHide = !self.isHide
            }),
            .init(title: NSLocalizedString("Hide Item", comment: ""), status: nil, clickBlock: { [unowned self] _ in
                let alert = UIAlertController(title: NSLocalizedString("Hide Item", comment: ""), message: "", preferredStyle: .actionSheet)
                var values: [DefaultOperationIdentifier] = []
                values.append(contentsOf: WhiteApplianceNameKey.allCases.map { .applice(key: $0, shape: nil)})
                values.append(contentsOf: WhiteApplianceShapeTypeKey.allCases.map { .applice(key: .ApplianceShape, shape: $0) })
                let others: [DefaultOperationIdentifier] = [
                    .operationType(.clean)!,
                    .operationType(.previousPage)!,
                    .operationType(.newPage)!,
                    .operationType(.nextPage)!,
                    .operationType(.redo)!,
                    .operationType(.undo)!
                ]
                values.append(contentsOf: others)
                for key in values {
                    alert.addAction(.init(title: key.identifier,
                                          style: .default, handler: { _ in
                        self.fastboard.setPanelItemHide(item: key, hide: true)
                    }))
                }
                alert.addAction(.init(title: "cancel", style: .cancel, handler: nil))
                alert.popoverPresentationController?.sourceView = self.exampleControlView
                self.present(alert, animated: true, completion: nil)
            }),
            .init(title: NSLocalizedString("Update writable", comment: ""), status: NSLocalizedString("On", comment: ""), clickBlock: { [unowned self] item in
                guard let room = self.fastboard.room else { return }
                let writable = !room.isWritable
                self.fastboard.updateWritable(writable) { error in
                    if let error = error {
                        print(error)
                        return
                    }
                }
                item.status = NSLocalizedString(writable ? "On" : "Off", comment: "")
            }),
            .init(title: NSLocalizedString("Custom Overlay", comment: ""), status: NSLocalizedString("Off", comment: ""), clickBlock: { [unowned self] _ in
                self.usingCustomOverlay = !self.usingCustomOverlay
            }),
            .init(title: NSLocalizedString("Apple Pencil", comment: ""), status: NSLocalizedString(FastboardManager.followSystemPencilBehavior ? "On" : "Off", comment: ""), clickBlock: { [unowned self] item in
                FastboardManager.followSystemPencilBehavior = !FastboardManager.followSystemPencilBehavior
                item.status =
                NSLocalizedString(FastboardManager.followSystemPencilBehavior ? "On" : "Off", comment: "")
            }),
            .init(title: NSLocalizedString("Update Layout", comment: ""), status: nil, clickBlock: { [unowned self] _ in
                self.fastboard.view.overlay?.invalidAllLayout()
                if let regular = self.fastboard.view.overlay as? RegularFastboardOverlay {
                    regular.operationPanel.view?.snp.makeConstraints { make in
                        make.left.equalToSuperview()
                        make.centerY.equalToSuperview()
                    }
                    
                    regular.deleteSelectionPanel.view?.snp.makeConstraints({ make in
                        make.bottom.equalTo(regular.operationPanel.view!.snp.top).offset(-8)
                        make.left.equalToSuperview()
                    })
                    
                    regular.undoRedoPanel.view?.snp.makeConstraints({ make in
                        make.left.bottom.equalTo(self.fastboard.view.whiteboardView)
                    })
                    
                    regular.scenePanel.view?.snp.makeConstraints({ make in
                        make.bottom.equalTo(self.fastboard.view.whiteboardView)
                        make.centerX.equalToSuperview()
                    })
                }
                
                if let compact = self.fastboard.view.overlay as? CompactFastboardOverlay {
                    compact.operationPanel.view?.snp.makeConstraints({ make in
                        make.left.equalTo(self.fastboard.view.whiteboardView)
                        make.centerY.equalToSuperview()
                    })
                    
                    compact.colorAndStrokePanel.view?.snp.makeConstraints({ make in
                        make.left.equalTo(self.fastboard.view.whiteboardView)
                        make.bottom.equalTo(compact.operationPanel.view!.snp.top).offset(-8)
                    })
                    
                    compact.deleteSelectionPanel.view?.snp.makeConstraints { $0.edges.equalTo(compact.colorAndStrokePanel.view!) }
                    
                    compact.undoRedoPanel.view?.snp.makeConstraints({ make in
                        make.left.bottom.equalTo(self.fastboard.view.whiteboardView)
                    })
                    
                    compact.scenePanel.view?.snp.makeConstraints({ make in
                        make.bottom.centerX.equalTo(self.fastboard.view.whiteboardView)
                    })
                }
            })
        ]
        if #available(iOS 13.0, *) {
            array.append(.init(title: NSLocalizedString("UsingFPA", comment: ""), status: NSLocalizedString(globalUsingFPA ? "On" : "Off", comment: ""), clickBlock: { _ in
                globalUsingFPA = !globalUsingFPA
                let vc = ViewController()
                UIApplication.shared.keyWindow?.rootViewController = vc
            }))
        } else {
            array.append(.init(title: NSLocalizedString("UsingFPA", comment: ""), status: "iOS 13 available", clickBlock: { _ in
            }))
        }
        return array
    }()
    
    // MARK: Lazy
    lazy var exampleControlView = ExampleControlView(items: exampleItems)
    
    lazy var mediaControlView = ExampleControlView(items: [
        .init(title: NSLocalizedString("Insert Mock DOC", comment: ""), status: nil, clickBlock: { [unowned self] item in
            let doc = storage.first(where: { $0.fileType == .word })!
            [(doc.fileURL, doc.fileURL, )]
            self.fastboard.insertStaticDocument(<#T##pages: [(url: URL, preview: URL, size: CGSize)]##[(url: URL, preview: URL, size: CGSize)]#>, title: <#T##String#>, completionHandler: <#T##((String) -> Void)?##((String) -> Void)?##(String) -> Void#>)
//            self.fastboard.insertStaticDocument(<#T##pages: [(url: URL, preview: URL, size: CGSize)]##[(url: URL, preview: URL, size: CGSize)]#>, title: <#T##String#>, completionHandler: <#T##((String) -> Void)?##((String) -> Void)?##(String) -> Void#>)
        })
])
//    [
//        {
//            "name":"开始使用 Flat.pdf",
//            "url":"https://flat-storage.oss-accelerate.aliyuncs.com/cloud-storage/2022-02/15/09faea1a-42f2-4ef6-a40d-7866cc5e1104/09faea1a-42f2-4ef6-a40d-7866cc5e1104.pdf",
//            "taskUUID":"fddaeb908e0b11ecb94f39bd66b92986",
//            "taskToken":"NETLESSTASK_YWs9NWJod2NUeXk2MmRZWC11WiZub25jZT1mZTFlZjk3MC04ZTBiLTExZWMtYTMzNS01MWEyMGJkNzRiZjYmcm9sZT0yJnNpZz1jZGQwMzMyZTFlZTkwNGEyNjhlMjQ0NDc0NWQ4MTY0ZTAzNzNiOTIxZmI4ZDY0YTE0MTJiZTU5MmUwMjM3MzM4JnV1aWQ9ZmRkYWViOTA4ZTBiMTFlY2I5NGYzOWJkNjZiOTI5ODY"
//        },
//        {
//            "name":"Get Started with Flat.pptx",
//            "url":"https://flat-storage.oss-accelerate.aliyuncs.com/cloud-storage/2022-02/15/d9e8a040-5b44-4867-b4ea-dcd5551dd5a8/d9e8a040-5b44-4867-b4ea-dcd5551dd5a8.pptx",
//            "taskUUID":"feae41208e0b11ecb954e907f43a0c2c",
//            "taskToken":"NETLESSTASK_YWs9NWJod2NUeXk2MmRZWC11WiZub25jZT1mZWI5YjJkMC04ZTBiLTExZWMtYTMzNS01MWEyMGJkNzRiZjYmcm9sZT0yJnNpZz00MDc2MjU2YmIwNzI3YmU1NWUxMGQ1YmMxOTI1ZjNjZWZlMDIyZjE3Yzg2MzU4MWM3MjQzZDdhZGQ0MzVkOGM4JnV1aWQ9ZmVhZTQxMjA4ZTBiMTFlY2I5NTRlOTA3ZjQzYTBjMmM",
//        },
//        {
//            "name":"oceans.mp4",
//            "fileSize":23014356,
//            "url":"https://flat-storage.oss-accelerate.aliyuncs.com/cloud-storage/2022-02/15/55509848-5437-463e-b52c-f81d1319c837/55509848-5437-463e-b52c-f81d1319c837.mp4",
//        },
//        {
//            "name":"lena_color.png",
//            "url":"https://flat-storage.oss-accelerate.aliyuncs.com/cloud-storage/2022-02/15/ebe8320a-a90e-4e03-ad3a-a5dc06ae6eda/ebe8320a-a90e-4e03-ad3a-a5dc06ae6eda.png",
//            "width":512,
//            "height": 512
//        },
//        {
//            "name":"lena_gray.png",
//            "url":"https://flat-storage.oss-accelerate.aliyuncs.com/cloud-storage/2022-02/15/8d487d84-e527-4760-aeb6-e13235fd541f/8d487d84-e527-4760-aeb6-e13235fd541f.png",
//            "width":512,
//            "height": 512
//        }
//    ]

}

extension ViewController: FastboardDelegate {
    func fastboardPhaseDidUpdate(_ fastboard: Fastboard, phase: FastRoomPhase) {
        print(#function, phase)
    }
    
    func fastboardUserKickedOut(_ fastboard: Fastboard, reason: String) {
        print(#function, reason)
    }
    
    func fastboard(_ fastboard: Fastboard, error: FastError) {
        print(#function, error.localizedDescription)
    }
}
