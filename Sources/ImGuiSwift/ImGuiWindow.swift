//
//  ImGuiWindow.swift
//  Swift-imgui
//
//  Created by Hiroaki Yamane on 10/24/16.
//  Copyright © 2016 Hiroaki Yamane. All rights reserved.
//

import UIKit

@objc public final class ImGuiWindow: UIWindow {
	
	public enum GestureType {
		case Shake
		case Gesture(UIGestureRecognizer)
	}
    
    public var frameOverride: CGRect?
	
	/// The amount of time you need to shake your device to bring up the ImGui UI
	private static let shakeWindowTimeInterval: Double = 0.4
	
	/// The GestureType used to determine when to present the UI.
	private let gestureType: GestureType
	
	/// By holding on to the ImGuiViewController, we get easy state restoration!
	@objc public var imguiViewController: ViewControllerAlias! // requires self for init
	
	/// Whether or not the device is shaking. Used in determining when to present the ImGui UI when the device is shaken.
	private var shaking: Bool = false
	
	private var shouldPresentImGui: Bool {
		switch gestureType {
		case .Shake: return shaking
		case .Gesture: return true
		}
	}
	
	// MARK: Init
	
    public init(frame: CGRect, api: ImGui.API = .metal, fontPath: String? = nil, gestureType: GestureType = .Shake) {
		self.gestureType = gestureType
		
//		// Are we running on a Mac? If so, then we're in a simulator!
//		#if (arch(i386) || arch(x86_64))
//			self.runningInSimulator = true
//		#else
//			self.runningInSimulator = false
//		#endif
		
		super.init(frame: frame)
		
		// tintColor = AppTheme.Colors.controlTinted
		
		switch gestureType {
		case .Gesture(let gestureRecognizer):
			gestureRecognizer.addTarget(self, action: #selector(self.presentImGui))
		case .Shake:
			break
		}
        
        ImGui.initialize(api, fontPath: fontPath)
        
        if let vc = ImGui.vc {
            imguiViewController = vc
        }
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: Shaking & Gestures
	public override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
		
		if motion == .motionShake {
			shaking = true
			
			DispatchQueue.main.asyncAfter(deadline: .now() + ImGuiWindow.shakeWindowTimeInterval, execute: {
				if self.shouldPresentImGui {
					if !self.presentImGui() {
						self.dismissImGui()
					}
				}
			})
		}
		
		super.motionBegan(motion, with: event)
	}
	
	public override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
		if motion == .motionShake {
			shaking = false
		}
		
		super.motionEnded(motion, with: event)
	}
	
	// MARK: Presenting & Dismissing
	
	@objc private func presentImGui() -> Bool {
		
		guard let rootViewController = rootViewController else {
			return true
		}
		
		var visibleViewController = rootViewController
		
		while (visibleViewController.presentedViewController != nil) {
			visibleViewController = visibleViewController.presentedViewController!
		}
		
		if !(visibleViewController is ImGuiViewControllerProtocol) {
			imguiViewController.providesPresentationContextTransitionStyle = true
			imguiViewController.definesPresentationContext = true
			imguiViewController.modalPresentationStyle = .overCurrentContext
			imguiViewController.view.backgroundColor = .clear
            imguiViewController.view.frame = visibleViewController.view.frame
            imguiViewController.modalPresentationStyle = .custom
            imguiViewController.transitioningDelegate = self
            
            
			visibleViewController.present(imguiViewController, animated: true, completion: nil)
			return true
		} else {
			return false
		}
	}
	
	@objc func dismissImGui(completion: (() -> ())? = nil) {
		imguiViewController.dismiss(animated: true, completion: completion)
	}
}

extension ImGuiWindow: UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let controller = AdjustableSizePresentationContrller(presentedViewController: presented, presenting: presenting)
        controller.frame = frameOverride != nil ? frameOverride! : presenting!.view.frame
        return controller
    }
}

class AdjustableSizePresentationContrller: UIPresentationController {
    @objc var frame: CGRect = CGRect.zero
    override var frameOfPresentedViewInContainerView: CGRect {
        return frame
    }
}

//extension ImGuiWindow: ImGuiViewControllerDelegate {
//    public func imguiViewControllerRequestsDismiss(imguiViewController: ImGuiViewController, completion: (() -> ())? = nil) {
//        dismissImGui(completion: completion)
//    }
//}

