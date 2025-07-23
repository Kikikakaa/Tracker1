import UIKit
import CoreData

final class NewCategoryViewController: UIViewController {
    
    // MARK: - Properties
    var onCategoryCreated: (() -> Void)?
    private var editingCategory: TrackerCategoryCoreData?
    
    // MARK: - UI
    
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите название категории"
        textField.backgroundColor = .ypLightGray.withAlphaComponent(0.3)
        textField.layer.cornerRadius = 16
        textField.textColor = .ypBlack
        textField.font = .systemFont(ofSize: 17, weight: .regular)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 75).isActive = true
        
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 75))
        textField.leftView = padding
        textField.leftViewMode = .always
        
        return textField
    }()
    
    private let createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Готово", for: .normal)
        button.setTitleColor(.ypWhite, for: .normal)
        button.backgroundColor = .ypGray
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 16
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhite
        navigationItem.hidesBackButton = true
        navigationItem.title = editingCategory == nil ? "Новая категория" : "Редактирование категории"
        
        configureNavigationBarAppearance()
        setupLayout()
        setupActions()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUIIfEditing()
    }
    
    // MARK: - Setup
    
    private func setupLayout() {
        view.addSubview(nameTextField)
        view.addSubview(createButton)
        
        NSLayoutConstraint.activate([
            nameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setupActions() {
        nameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
    }
    
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .ypWhite
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: UIColor.ypBlack
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    private func updateUIIfEditing() {
        if let category = editingCategory {
            nameTextField.text = category.title
            textFieldDidChange(nameTextField)
        }
    }
    
    // MARK: - Actions
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        let isValid = !(textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        createButton.isEnabled = isValid
        createButton.backgroundColor = isValid ? .ypBlack : .ypGray
    }
    
    @objc private func createTapped() {
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return
        }
        
        AnimationHelper.animateButtonPress(createButton) {
            let context = CoreDataManager.shared.context
            
            if self.editingCategory == nil {
                let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
                request.predicate = NSPredicate(format: "title == %@", name)
                let existing = (try? context.fetch(request)) ?? []
                if !existing.isEmpty {
                    self.showDuplicateAlert()
                    return
                }
            }
            
//            let category = self.editingCategory ?? TrackerCategoryCoreData(context: context)
            
            let category: TrackerCategoryCoreData
              
              if let existingCategory = self.editingCategory {
                  category = existingCategory
              } else {
                  // Создаем новую категорию
                  category = TrackerCategoryCoreData(context: context)
                  category.id = UUID() // Явно устанавливаем ID сразу при создании
              }
            
            category.title = name
            category.isSelected = false
            
            CoreDataManager.shared.saveContext()
            self.onCategoryCreated?()
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func showDuplicateAlert() {
        let alert = UIAlertController(title: "Категория уже существует", message: "Введите другое название.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - External Configuration
    
    func configure(with category: TrackerCategoryCoreData) {
        editingCategory = category
    }
}
