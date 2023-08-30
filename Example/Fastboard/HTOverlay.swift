//
//  HTOverlay.swift
//  Fastboard
//
//  Created by xuyunshi on 2023/8/29.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Fastboard
import Whiteboard

class HTOverlay: FastRoomOverlay {
    func invalidAllLayout() {}
    func updateControlBarLayout(direction _: OperationBarDirection) {}
    func initUIWith(appliance: WhiteApplianceNameKey?, shape: WhiteApplianceShapeTypeKey?) {
        if let appliance = appliance {
            mainPanel.deselectAll()
            let identifier = FastRoomDefaultOperationIdentifier.applice(key: appliance, shape: shape).identifier
            if let target = mainPanel.flatItems
                .first(where: { $0.identifier == identifier })?.associatedView as? UIButton {
                target.isSelected = true
            }
        }
    }

    func update(strokeColor _: UIColor) {}
    func update(strokeWidth _: Float) {}
    func update(pageState _: WhitePageState) {}
    func update(undoEnable: Bool) {
        mainPanel.flatItems
            .first(where: {
                $0.identifier == FastRoomDefaultOperationIdentifier.operationType(.undo)?.identifier
            })?
            .setEnable(undoEnable)
    }
    
    func update(redoEnable: Bool) {
        mainPanel.flatItems
            .first(where: {
                $0.identifier == FastRoomDefaultOperationIdentifier.operationType(.redo)?.identifier
            })?
            .setEnable(redoEnable)
    }

    func update(boxState _: WhiteWindowBoxState?) {}
    func update(roomPhase _: FastRoomPhase) {}
    func setPanelItemHide(item _: FastRoomDefaultOperationIdentifier, hide _: Bool) {}
    func dismissAllSubPanels() {}

    func setupWith(room: WhiteRoom, fastboardView: FastRoomView, direction _: OperationBarDirection) {
        let panelView = mainPanel.setup(room: room, direction: .horizontal)
        fastboardView.addSubview(panelView)
        panelView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }
    }

    func setAllPanel(hide: Bool) {
        mainPanel.view?.isHidden = hide
    }

    // MARK: - Lazy -

    lazy var mainPanel: FastRoomPanel = createMainPanel()
}

extension HTOverlay: FastPanelDelegate {
    func itemWillBeExecuted(fastPanel: FastRoomPanel, item: FastRoomOperationItem) {
        if item is HTApplianceItem {
            fastPanel.deselectAll()
        }
    }
}

extension HTOverlay {
    func createMainPanel() -> FastRoomPanel {
        let panel = FastRoomPanel(items: [
            applianceItem(.ApplianceHand),
            applianceItem(.ApplianceLaserPointer),
            applianceItem(.AppliancePencil),
            applianceItem(.ApplianceText),
            undoItem(),
            redoItem(),
            cleanItem(),
        ])
        panel.delegate = self
        return panel
    }
    
    func applianceItem(_ appliance: WhiteApplianceNameKey,
                       shape: WhiteApplianceShapeTypeKey? = nil) -> FastRoomOperationItem
    {
        var imageName = "whiteboard_"
        if appliance == .ApplianceShape, let shape = shape {
            imageName = imageName + "shape_\(shape.rawValue)"
        } else {
            imageName += appliance.rawValue
        }
        let identifier = FastRoomDefaultOperationIdentifier.applice(key: appliance, shape: shape).identifier
        return HTApplianceItem(image: UIImage(named: imageName)!,
                               selectedImage: UIImage(named: imageName + "-selected"),
                               title: appliance.localizedTitle,
                               action: { room, _ in
                                   let memberState = WhiteMemberState()
                                   memberState.currentApplianceName = appliance
                                   memberState.shapeType = shape
                                   room.setMemberState(memberState)
                               },
                               identifier: identifier)
    }

    func cleanItem() -> FastRoomOperationItem {
        HTExecutionItem(image: UIImage(named: "whiteboard_clean")!,
                        title: "清除",
                        action: { room, _ in
                            room.cleanScene(true)
                        },
                        identifier: FastRoomDefaultOperationIdentifier.operationType(.clean)!.identifier)
    }

    func undoItem() -> FastRoomOperationItem {
        HTExecutionItem(image: UIImage(named: "whiteboard_undo")!,
                        disableImage: UIImage(named: "whiteboard_undo-disable"),
                        title: "撤销",
                        action: { room, _ in
                            room.undo()
                        },
                        identifier: FastRoomDefaultOperationIdentifier.operationType(.undo)!.identifier)
    }

    func redoItem() -> FastRoomOperationItem {
        HTExecutionItem(image: UIImage(named: "whiteboard_redo")!,
                        disableImage: UIImage(named: "whiteboard_redo-disable"),
                        title: "重做",
                        action: { room, _ in
                            room.redo()
                        },
                        identifier: FastRoomDefaultOperationIdentifier.operationType(.redo)!.identifier)
    }
}
