//
//  ViewController.swift
//  NGUIButtonInsetsExample
//
//  Created by Noah Gilmore on 4/18/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

import UIKit

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

final class EdgeSliderView: UIStackView {
    private let label = UILabel()
    private let valueLabel = UILabel()
    private let slider = UISlider()
    private let sliderDidChange: (Int) -> Void

    init(edge: InsetsEdge, sliderDidChange: @escaping (Int) -> Void) {
        self.sliderDidChange = sliderDidChange
        super.init(frame: .zero)
        self.axis = .horizontal
        self.spacing = 8

        label.text = edge.displayName
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
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func sliderDidChange(_ sender: UISlider) {
        let value = Int(round(sender.value))
        self.sliderDidChange(value)
        self.valueLabel.text = "\(value)"
    }

    func reset() {
        self.slider.setValue(0, animated: true)
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
}

import UIKit

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
}

final class ButtonView: UIView {
    private let imageButton = UIButton()
    private let textButton = UIButton()
    private let bothButton = UIButton()

    init() {
        super.init(frame: .zero)

        for button in [imageButton, textButton, bothButton] {
            button.backgroundColor = .red
            addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        }

        textButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        imageButton.bottomAnchor.constraint(equalTo: textButton.topAnchor, constant: -8).isActive = true
        textButton.bottomAnchor.constraint(equalTo: bothButton.topAnchor, constant: -8).isActive = true

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

class ViewController: UIViewController {
    private let stackView = UIStackView()
    private let buttonView = ButtonView()
    private let resetButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        view.addSubview(stackView)
        stackView.axis = .vertical
        stackView.spacing = 50

        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: -30).isActive = true
        view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 30).isActive = true
        view.topAnchor.constraint(equalTo: stackView.topAnchor).isActive = true
//        view.bottomAnchor.constraint(equalTo: stackView.safeAreaLayoutGuide.bottomAnchor).isActive = true

        stackView.addArrangedSubview(buttonView)
        buttonView.heightAnchor.constraint(equalToConstant: 300).isActive = true

        stackView.addArrangedSubview(AllInsetsView(insetsDidChange: { [weak self] type, insets in
            guard let `self` = self else { return }
            self.buttonView.set(insets: insets, type: type)
        }))

        stackView.addArrangedSubview(resetButton)
        resetButton.setTitle("Reset", for: .normal)
        resetButton.setTitleColor(.blue, for: .normal)
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
    }

    @objc private func resetTapped() {
//        self.buttonView.button.imageEdgeInsets = .zero
//        self.buttonView.button.titleEdgeInsets = .zero
//        self.buttonView.button.contentEdgeInsets = .zero

        for view in stackView.arrangedSubviews {
            if let view = view as? AllInsetsView {
                view.reset()
            }
        }
    }


}

