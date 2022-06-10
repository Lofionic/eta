//
//  Created by Lofionic ©2021
//

import UIKit

@objc
protocol TrayDelegate: AnyObject {
//    func tray(_ tray: Tray, heightForState state: TrayState) -> CGFloat
    func tray(_ tray: Tray, restingHeightForHeight height: CGFloat, velocity: CGFloat) -> CGFloat
    
    func minimumPanningOffsetForTray(_ tray: Tray) -> CGFloat
    func maximumPanningOffsetForTray(_ tray: Tray) -> CGFloat
    
//    func tray(_ tray: Tray, didPanToOffset offset: CGFloat)
//    func tray(_ tray: Tray, willAnimateToOffset offset: CGFloat, animationDuration: Double)
}

@IBDesignable
final class Tray: UIView {
    
    @IBOutlet weak var delegate: TrayDelegate? { didSet {
        if let delegate = delegate, let panConstraint = panConstraint {
            panConstraint.constant = delegate.tray(self, restingHeightForHeight: 0, velocity: 0)
//            delegate.tray(self, didPanToOffset: normalizedOffset)
        }
    }}
    
    private var panConstraint: NSLayoutConstraint?
    
//    private var normalizedOffset: CGFloat {
//        guard let delegate = delegate, let panConstraint = panConstraint else {
//            return 1
//        }
//        let minimum = delegate.tray(self, heightForState: .closed)
//        let maximum = delegate.tray(self, heightForState: .open)
//        return (panConstraint.constant - minimum) / (maximum - minimum)
//    }
    
    struct PanState {
        let initialY: CGFloat
        let initialConstraintConstant: CGFloat
        let minimumOffset: CGFloat
        let maximumOffset: CGFloat
    }
    
//	private(set) var trayState = TrayState.closed
    var panState: PanState?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupShadow()
        setupPanning()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupShadow()
        setupPanning()
    }
    
    private func setupShadow() {
        layer.masksToBounds = false
        layer.shadowRadius = 4
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
    }
    
    private func setupPanning() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(updatePanGesture))
        addGestureRecognizer(panGestureRecognizer)
    }
    
    override func didMoveToSuperview() {
        if let panConstraint = panConstraint {
            NSLayoutConstraint.deactivate([panConstraint])
        }
        
        guard let superview = superview else { return }
        let panConstraint = superview.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: topAnchor, constant: 0)
        NSLayoutConstraint.activate([panConstraint])
        self.panConstraint = panConstraint
    }
    
    override func didAddSubview(_ subview: UIView) {
        subview.insetsLayoutMarginsFromSafeArea = false
    }
    
    @objc
    private func updatePanGesture(panGestureRecognizer: UIPanGestureRecognizer) {
        switch panGestureRecognizer.state {
        
        case .began:
            panGestureBegan(panGestureRecognizer: panGestureRecognizer)
        case .changed:
            panGestureChanged(panGestureRecognizer: panGestureRecognizer)
        case .ended, .cancelled:
            panGestureEnded(panGestureRecognizer: panGestureRecognizer)
        default:
            break
        }
    }
    
    private func panGestureBegan(panGestureRecognizer: UIPanGestureRecognizer) {
        guard
            let delegate = delegate,
            let superview = superview,
            let panConstraint = panConstraint else
        {
            return
        }
        
        let minimumOffset = delegate.minimumPanningOffsetForTray(self)
        let maximumOffset = delegate.maximumPanningOffsetForTray(self)
        
        panState = PanState(
            initialY: panGestureRecognizer.location(in: superview).y,
            initialConstraintConstant: panConstraint.constant,
            minimumOffset: minimumOffset,
            maximumOffset: maximumOffset)
    }
    
    private func panGestureChanged(panGestureRecognizer: UIPanGestureRecognizer) {
        guard
            let superview = superview,
            let panConstraint = panConstraint,
            let panState = panState else
        {
            return
        }
        
        let positionY = panGestureRecognizer.location(in: superview).y
        let translation = panState.initialY - positionY
        
//        let minimum = delegate.tray(self, heightForState: .closed)
//        let maximum = delegate.tray(self, heightForState: .open)
        
        panConstraint.constant = min(max(panState.initialConstraintConstant + translation, panState.minimumOffset), panState.maximumOffset)
//        delegate.tray(self, willAnimateToOffset: normalizedOffset, animationDuration: 0.1)
        
//        panConstraint.constant = panState.initialConstraintConstant + translation
        
        UIView.animate(withDuration: 0.1) {
            superview.layoutIfNeeded()
        }
    }
    
    private func panGestureEnded(panGestureRecognizer: UIPanGestureRecognizer) {
        guard
            let delegate = delegate,
            let superview = superview,
            let panConstraint = panConstraint else
        {
            return
        }
        
        let velocity = panGestureRecognizer.velocity(in: superview).y
        
        let restingOffset = delegate.tray(self, restingHeightForHeight: frame.height, velocity: velocity)
        panConstraint.constant = restingOffset
        
        UIView.animate(withDuration: 0.1) {
            superview.layoutIfNeeded()
        }
        self.panState = nil
    }
}
