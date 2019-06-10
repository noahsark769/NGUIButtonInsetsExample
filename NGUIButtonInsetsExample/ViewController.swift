//
//  ViewController.swift
//  NGUIButtonInsetsExample
//
//  Created by Noah Gilmore on 4/18/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

import UIKit

// MARK:  -
// MARK: Timer -

final class TimerPool {
    static let shared = TimerPool()
    private var timers: [Timer] = []
    
    func addTimer(_ block: @escaping () -> Void) {
        timers.append(Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
            block()
        }))
    }
    func invalidateAllTimers(){
        for timer in timers {
            timer.invalidate()
        }
        timers = []
    }
}

// MARK:  -
// MARK: Types -

enum InsetsType: String, CaseIterable {
    case content = "contentEdgeInsets"
    case image = "imageEdgeInsets"
    case title = "titleEdgeInsets"
    
    var displayName: String {
        return self.rawValue
    }
}

enum InsetsEdge: String {
    case top
    case left
    case bottom
    case right
    
    var displayName: String {
        return self.rawValue
    }
}

extension UIEdgeInsets {
    mutating func change(edge: InsetsEdge, to value: Int) {
        switch edge {
        case .top: self.top = CGFloat(value)
        case .bottom: self.bottom = CGFloat(value)
        case .left: self.left = CGFloat(value)
        case .right: self.right = CGFloat(value)
        }
    }
}

// MARK:  -
// MARK: Edge Sliders -

final class EdgeSliderView: UIStackView {
    private let label = UILabel()
    private let valueLabel = UILabel()
    private let slider = UISlider()
    private let sliderDidChange: (Int) -> Void
    private var currentlyTickingPositively = true
    
    init(edge: InsetsEdge, sliderDidChange: @escaping (Int) -> Void) {
        self.sliderDidChange = sliderDidChange
        super.init(frame: .zero)
        self.axis = .horizontal
        self.spacing = 8
        
        label.text = edge.displayName
        label.font = .systemFont(ofSize: 12.0)
        label.adjustsFontSizeToFitWidth = true
        
        slider.minimumValue = -25
        slider.maximumValue = 25
        slider.addTarget(self, action: #selector(sliderDidChange(_:)), for: .valueChanged)
        slider.widthAnchor.constraint(equalToConstant: 80).isActive = true
        valueLabel.widthAnchor.constraint(equalToConstant: 30).isActive = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        self.addArrangedSubview(label)
        self.addArrangedSubview(slider)
        self.addArrangedSubview(valueLabel)
        valueLabel.text = "0"
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(labelWasDoubleTapped(_:)))
        doubleTap.numberOfTapsRequired = 1
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(doubleTap)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Actions -
    
    @objc private func sliderDidChange(_ sender: UISlider) {
        let value = Int(round(sender.value))
        self.sliderDidChange(value)
        self.valueLabel.text = "\(value)"
    }
    
    @objc private func labelWasDoubleTapped(_ sender: UITapGestureRecognizer) {
        TimerPool.shared.addTimer {
            self.tick()
        }
    }
    
    func reset() {
        self.slider.setValue(0, animated: true)
        self.sliderDidChange(self.slider)
    }
    
    func tick() {
        let value = Int(round(slider.value))
        if Float(value) == slider.maximumValue {
            currentlyTickingPositively = false
        }
        if Float(value) == slider.minimumValue {
            currentlyTickingPositively = true
        }
        
        let newValue = currentlyTickingPositively ? value + 1 : value - 1
        slider.setValue(Float(newValue), animated: true)
        self.sliderDidChange(self.slider)
    }
}

final class InsetsView: UIStackView {
    private let firstStackView = UIStackView()
    private let secondStackView = UIStackView()
    private let insetsDidChange: (UIEdgeInsets) -> Void
    private var currentInsets: UIEdgeInsets = .zero
    private let label = UILabel()
    
    init(insets: InsetsType, insetsDidChange: @escaping (UIEdgeInsets) -> Void) {
        self.insetsDidChange = insetsDidChange
        super.init(frame: .zero)
        self.axis = .vertical
        self.spacing = 8
        
        self.addArrangedSubview(label)
        label.text = insets.displayName
        
        self.addArrangedSubview(firstStackView)
        self.addArrangedSubview(secondStackView)
        
        for stackView in [firstStackView, secondStackView] {
            stackView.axis = .horizontal
            stackView.spacing = 10
        }
        
        for edge in [InsetsEdge.top, InsetsEdge.bottom] {
            let slider = EdgeSliderView(edge: edge, sliderDidChange: { [weak self] value in
                guard let `self` = self else { return }
                self.edgeInset(edge, didChangeTo: value)
            })
            self.firstStackView.addArrangedSubview(slider)
        }
        for edge in [InsetsEdge.left, InsetsEdge.right] {
            let slider = EdgeSliderView(edge: edge, sliderDidChange: { [weak self] value in
                guard let `self` = self else { return }
                self.edgeInset(edge, didChangeTo: value)
            })
            self.secondStackView.addArrangedSubview(slider)
        }
    }
    
    private func edgeInset(_ edge: InsetsEdge, didChangeTo value: Int) {
        currentInsets.change(edge: edge, to: value)
        self.insetsDidChange(currentInsets)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reset() {
        for stackView in [self.firstStackView, self.secondStackView] {
            for view in stackView.arrangedSubviews {
                if let view = view as? EdgeSliderView {
                    view.reset()
                }
            }
        }
    }
    
    func tick() {
        for stackView in [self.firstStackView, self.secondStackView] {
            for view in stackView.arrangedSubviews {
                if let view = view as? EdgeSliderView {
                    view.tick()
                }
            }
        }
    }
}

final class AllInsetsView: UIStackView {
    init(insetsDidChange: @escaping (InsetsType, UIEdgeInsets) -> Void) {
        super.init(frame: .zero)
        self.axis = .vertical
        self.spacing = 30
        
        for type in InsetsType.allCases {
            self.addArrangedSubview(InsetsView(insets: type, insetsDidChange: { insets in
                insetsDidChange(type, insets)
            }))
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reset() {
        for view in self.arrangedSubviews {
            if let view = view as? InsetsView {
                view.reset()
            }
        }
    }
    
    func tick() {
        for view in self.arrangedSubviews {
            if let view = view as? InsetsView {
                view.tick()
            }
        }
    }
}

// MARK:  -
// MARK: Buttons -

final class ButtonsView: UIView {
    private let imageButton = UIButton()
    private let textButton = UIButton()
    private let bothButton = UIButton()
    
    init() {
        super.init(frame: .zero)
        
        for button in [textButton, imageButton, bothButton] {
            button.backgroundColor = .red
            addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        }
        
        textButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 8).isActive = true
        bothButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        imageButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8).isActive = true
        
        for button in [imageButton, bothButton] {
            button.setImage(UIImage(named: "image")!, for: .normal)
        }
        
        for button in [textButton, bothButton] {
            button.setTitle("Button", for: .normal)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(insets: UIEdgeInsets, type: InsetsType) {
        for button in [imageButton, textButton, bothButton] {
            switch type {
            case .image: button.imageEdgeInsets = insets
            case .title: button.titleEdgeInsets = insets
            case .content: button.contentEdgeInsets = insets
            }
        }
    }
}

// MARK:  -
// MARK: VC -

class ViewController: UIViewController {
    
    // MARK: UI Properties -
    
    private lazy var buttonsView: ButtonsView = {
        let bsv = ButtonsView()
        bsv.translatesAutoresizingMaskIntoConstraints = false
        return bsv
    }()
    
    private lazy var resetButton: UIButton = {
        let rsb = UIButton()
        rsb.translatesAutoresizingMaskIntoConstraints = false
        rsb.setTitle("Reset", for: .normal)
        rsb.setTitleColor(.blue, for: .normal)
        rsb.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        return rsb
    }()
    
    private lazy var stackView: UIStackView = {
        let stv = UIStackView()
        stv.axis = .vertical
        stv.spacing = 50
        stv.translatesAutoresizingMaskIntoConstraints = false
        stv.backgroundColor = .lightGray
        return stv
    }()
    
    private lazy var allInsetsView: AllInsetsView = {
        let aiv = AllInsetsView(insetsDidChange: { [weak self] type, insets in
            guard let `self` = self else { return }
            self.buttonsView.set(insets: insets, type: type)
        })
        aiv.translatesAutoresizingMaskIntoConstraints = false
        aiv.backgroundColor = .lightGray
        return aiv
    }()
    
    //MARK: Properties -
    
    private var timer: Timer?
    
    // MARK: Lifecycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
}

// MARK: Setup -

private extension ViewController {
    
    func setupView() {
        view.backgroundColor = .white
        setupStackView()
        setupButtonsView()
        setupAllInsetsView()
        setupResetButton()
    }
    
    func setupStackView() {
        view.addSubview(stackView)
        view.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: -30).isActive = true
        view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 30).isActive = true
        view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: stackView.topAnchor).isActive = true
        view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor).isActive = true
    }
    
    func setupButtonsView() {
        stackView.addArrangedSubview(buttonsView)
        buttonsView.heightAnchor.constraint(equalTo: stackView.heightAnchor, multiplier: 0.3).isActive = true
    }
    
    func setupAllInsetsView() {
        stackView.addArrangedSubview(allInsetsView)
    }
    
    func setupResetButton() {
        stackView.addArrangedSubview(resetButton)
        resetButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
}

// MARK: Actions -

private extension ViewController {
    @objc private func resetTapped() {
        for view in stackView.arrangedSubviews {
            if let view = view as? AllInsetsView { view.reset() }
        }
        self.timer?.invalidate()
        TimerPool.shared.invalidateAllTimers()
    }
}


