//
//  SessionLinkView.swift
//  eta
//
//  Created by Chris Rivers on 23/03/2021.
//

import UIKit

import RxSwift

@IBDesignable
final class SessionLinkView: UIView {
    
    private let button = Button()
    
    private let linkView = HighlightingView()
    private let linkLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    var link: String? {
        get { linkLabel.text }
        set {
            linkLabel.text = newValue ?? " "
            if newValue == nil {
                hideLinkLabel()
            } else {
                showLinkLabel()
            }
        }
    }
    
    var isEnabled: Bool {
        get { button.isEnabled }
        set { button.isEnabled = newValue }
    }
    
    var tapButtonHandler: () -> Void = {}
    var tapLinkHandler: (String?) -> Void = { _ in }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonSetup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonSetup()
    }
    
    private func commonSetup() {
        button.translatesAutoresizingMaskIntoConstraints = false
        linkView.translatesAutoresizingMaskIntoConstraints = false
        linkLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        linkView.addSubview(linkLabel)
        linkView.addSubview(subtitleLabel)
        
        addSubview(button)
        addSubview(linkView)
        
        button.alpha = 1
        linkView.alpha = 0
        
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            
            linkView.leadingAnchor.constraint(equalTo: leadingAnchor),
            linkView.trailingAnchor.constraint(equalTo: trailingAnchor),
            linkView.topAnchor.constraint(equalTo: topAnchor),
            linkView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            linkLabel.leadingAnchor.constraint(equalTo: linkView.layoutMarginsGuide.leadingAnchor),
            linkLabel.trailingAnchor.constraint(equalTo: linkView.layoutMarginsGuide.trailingAnchor),
            linkLabel.topAnchor.constraint(equalTo: linkView.layoutMarginsGuide.topAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: linkLabel.bottomAnchor, constant: 4),
            subtitleLabel.bottomAnchor.constraint(equalTo: linkView.layoutMarginsGuide.bottomAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: linkView.layoutMarginsGuide.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: linkView.layoutMarginsGuide.trailingAnchor),
            
            button.heightAnchor.constraint(equalTo: linkView.heightAnchor),
        ])
        
        linkView.backgroundColor = UIColor.systemBackground
        linkView.layer.masksToBounds = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapLink))
        linkView.addGestureRecognizer(tapGestureRecognizer)
        
        linkLabel.textAlignment = .center
        linkLabel.text = " "
        linkLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        linkLabel.textColor = UIColor.label
        linkLabel.font = UIFont.preferredFont(forTextStyle: .body)
        
        subtitleLabel.textAlignment = .center
        subtitleLabel.text = "Tap to share"
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        subtitleLabel.textColor = UIColor.label
        subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        button.setContentHuggingPriority(.defaultLow, for: .vertical)
        button.addTarget(self, action: #selector(didTapButton), for: .primaryActionTriggered)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        linkView.layer.cornerRadius = linkView.frame.height / 2.0
    }
    
    func startAnimatingActivityIndicator() {
        button.startAnimatingActivityIndicator()
    }
    
    func stopAnimatingActivityIndicator() {
        button.stopAnimatingActivityIndicator()
    }
    
    func setButtonTitle(_ title: String?, for state: UIControl.State) {
        button.setTitle(title, for: state)
    }
    
    private func showLinkLabel() {
        button.titleLabel?.isHidden = true
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.linkView.alpha = 1
            self?.button.alpha = 0
        }
    }
    
    private func hideLinkLabel() {
        button.titleLabel?.isHidden = false
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.linkView.alpha = 0
            self?.button.alpha = 1
        }
    }
    
    @objc private func didTapButton() {
        tapButtonHandler()
    }
    
    @objc private func didTapLink() {
        tapLinkHandler(linkLabel.text)
    }
}

extension Reactive where Base == SessionLinkView {
    
    var isEnabled: Binder<Bool> {
        return Binder<Bool>(base) { base, isEnabled  in
            base.isEnabled = isEnabled
        }
    }
    
    var isAnimatingActivityIndicator: Binder<Bool> {
        return Binder<Bool>(base) { base, isAnimatingActivityIndicator  in
            if isAnimatingActivityIndicator {
                base.startAnimatingActivityIndicator()
            } else {
                base.stopAnimatingActivityIndicator()
            }
        }
    }
    
    var link: Binder<String?> {
        return Binder<String?>(base) { base, link  in
            base.link = link
        }
    }
}

private class HighlightingView: UIView {
    
    let unhighlightedBackgroundColor = UIColor.systemBackground
    let highlightedBackgroundColor = UIColor.systemGray2
    
    let onTapHandler: () -> Void = {}
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonSetup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonSetup()
    }
    
    private func commonSetup() {
        self.backgroundColor = unhighlightedBackgroundColor
//        isUserInteractionEnabled = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        backgroundColor = highlightedBackgroundColor
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        backgroundColor = unhighlightedBackgroundColor
    }
}
