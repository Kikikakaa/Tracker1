import UIKit

final class StatCardView: UIView {

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .ypBlack
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .ypBlack
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .ypWhite
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let borderLayer = CAGradientLayer()

    init(value: String, title: String) {
        super.init(frame: .zero)
        setupUI()
        configure(value: value, title: title)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        layer.cornerRadius = 16
        layer.masksToBounds = true
        layer.addSublayer(borderLayer)

        addSubview(containerView)
        containerView.addSubview(valueLabel)
        containerView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 1),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 1),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -1),

            valueLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            valueLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            valueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 7),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
    }

    private func configure(value: String, title: String) {
        valueLabel.text = value
        titleLabel.text = title
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        borderLayer.frame = bounds
        borderLayer.cornerRadius = 16
        borderLayer.borderWidth = 1
        borderLayer.colors = [
            UIColor(hex: "#FD4C49").cgColor,
            UIColor(hex: "#46E69D").cgColor,
            UIColor(hex: "#007BFA").cgColor
        ]
        borderLayer.startPoint = CGPoint(x: 0, y: 0.5)
        borderLayer.endPoint = CGPoint(x: 1, y: 0.5)
        borderLayer.borderColor = UIColor.clear.cgColor
        borderLayer.masksToBounds = true
    }
}
