import UIKit

final class RandomEventCreationViewController: UIViewController {
    
    private var trackerTitle: String = ""
    
    var onTrackerCreated: ((Tracker) -> Void)?
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Новое нерегулярное событие"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var nameTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Введите название трекера"
        field.backgroundColor = UIColor(resource: .backgroundDay)
        field.layer.cornerRadius = 16
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        field.leftViewMode = .always
        field.clearButtonMode = .whileEditing
        
        field.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ypRed
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var textFieldStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private var categoryDetailsLabel: UILabel!
    
    private lazy var categoryButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor(resource: .backgroundDay)
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(categoryTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let textContainer = UIView()
        textContainer.isUserInteractionEnabled = false
        textContainer.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(textContainer)
        
        // Лейбл "Категория"
        let titleLabel = UILabel()
        titleLabel.text = "Категория"
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        titleLabel.textColor = UIColor(resource: .ypBlack)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        textContainer.addSubview(titleLabel)
        
        // Лейбл для деталей категории
        categoryDetailsLabel = UILabel()
        categoryDetailsLabel.text = "Важное"
        categoryDetailsLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        categoryDetailsLabel.textColor = UIColor(resource: .ypGray)
        categoryDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        textContainer.addSubview(categoryDetailsLabel)
        
        let chevronImage = UIImageView(image: .chevron)
        chevronImage.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(chevronImage)
        
        NSLayoutConstraint.activate([
            textContainer.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            textContainer.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            textContainer.trailingAnchor.constraint(lessThanOrEqualTo: chevronImage.leadingAnchor, constant: -16),
            
            titleLabel.topAnchor.constraint(equalTo: textContainer.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor),
            
            categoryDetailsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            categoryDetailsLabel.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor),
            categoryDetailsLabel.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor),
            categoryDetailsLabel.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor),
            
            chevronImage.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            chevronImage.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            chevronImage.widthAnchor.constraint(equalToConstant: 24),
            chevronImage.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return button
    }()
    
    private lazy var buttonsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("Отменить", for: .normal)
        button.setTitleColor(UIColor(resource: .ypRed), for: .normal)
        button.backgroundColor = UIColor(resource: .ypWhite)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(resource: .ypRed).cgColor
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var createButton: UIButton = {
        let button = UIButton()
        button.setTitle("Создать", for: .normal)
        button.setTitleColor(UIColor(resource: .ypWhite), for: .normal)
        button.backgroundColor = UIColor(resource: .ypGray)
        button.layer.cornerRadius = 16
        button.isEnabled = false
        button.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .ypWhite)
        nameTextField.delegate = self
        setupUI()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameTextField.becomeFirstResponder() // Активируем текстовое поле и показываем клавиатуру
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setupUI() {
        view.addSubviews([scrollView, titleLabel, buttonsStack])
        scrollView.addSubview(contentView)
        contentView.addSubviews([textFieldStack, categoryButton])
        buttonsStack.addArrangedSubview(cancelButton)
        buttonsStack.addArrangedSubview(createButton)
        textFieldStack.addArrangedSubview(nameTextField)
        textFieldStack.addArrangedSubview(errorLabel)
        
        nameTextField.heightAnchor.constraint(equalToConstant: 75).isActive = true
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 74),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            
            contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor, multiplier: 1.5),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 38),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            textFieldStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            textFieldStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textFieldStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            categoryButton.topAnchor.constraint(equalTo: textFieldStack.bottomAnchor, constant: 24),
            categoryButton.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            categoryButton.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            categoryButton.heightAnchor.constraint(equalToConstant: 75),
            
            buttonsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonsStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            buttonsStack.heightAnchor.constraint(equalToConstant: 60),
        ])
    }
    
    @objc private func textFieldChanged() {
        trackerTitle = nameTextField.text ?? ""
        
        if trackerTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            hideError()
        }
        
        updateCreateButtonState()
    }
    
    @objc private func categoryTapped() {
        // Заглушка для будущей реализации
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func createTapped() {
        let newTracker = Tracker(
            id: UUID(),
            title: trackerTitle,
            color: .systemRed,
            emoji: "😄",
            schedule: nil
        )
        
        // Используем замыкание для передачи трекера
        onTrackerCreated?(newTracker)
        navigationController?.popToRootViewController(animated: true)
        dismiss(animated: true)
    }
    
    private func updateCreateButtonState() {
        let isTitleValid = !trackerTitle.trimmingCharacters(in: .whitespaces).isEmpty
        createButton.isEnabled = isTitleValid
        createButton.backgroundColor = createButton.isEnabled ? UIColor(resource: .ypBlack) : UIColor(resource: .ypGray)
    }
}

extension RandomEventCreationViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let currentText = textField.text,
              let rangeInText = Range(range, in: currentText) else {
            return true
        }
        
        let updatedText = currentText.replacingCharacters(in: rangeInText, with: string)
        
        if updatedText.count > 38 {
            showError("Ограничение 38 символов")
            return false
        }
        hideError()
        return true
    }
    private func showError(_ message: String) {
        errorLabel.isHidden = false
        errorLabel.text = message
        nameTextField.layer.borderColor = UIColor.systemRed.cgColor
        nameTextField.layer.borderWidth = 1
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func hideError() {
        errorLabel.isHidden = true
        errorLabel.text = nil
        nameTextField.layer.borderWidth = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
}
