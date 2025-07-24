import UIKit
import CoreData

protocol CategorySelectionDelegate: AnyObject {
    func didSelectCategory(_ category: TrackerCategoryCoreData)
}

final class CategoryViewController: UIViewController {
    
    weak var delegate: CategorySelectionDelegate?
    private var viewModel: CategoryViewModelProtocol
    private var categories: [TrackerCategoryCoreData] {
        viewModel.categories
    }
    
    init(viewModel: CategoryViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    
    // MARK: - UI
    private var tableViewHeightConstraint: NSLayoutConstraint?
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .ypLightGray.withAlphaComponent(0.3)
        table.separatorStyle = .singleLine
        table.layer.cornerRadius = 16
        table.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        table.showsVerticalScrollIndicator = false
        return table
    }()
    
    private let emptyImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .dizzyError)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Привычки и события можно\nобъединить по смыслу"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .ypBlack
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Добавить категорию", for: .normal)
        button.setTitleColor(.ypWhite, for: .normal)
        button.backgroundColor = .ypBlack
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhite
        
        setupLayout()
        setupBindings()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.reuseId)
        
        print("🔧 Setting up addButton target...")
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        
        // Проверяем, что кнопка настроена правильно
        print("✅ AddButton targets: \(addButton.allTargets)")
        print("✅ AddButton isEnabled: \(addButton.isEnabled)")
        print("✅ AddButton isUserInteractionEnabled: \(addButton.isUserInteractionEnabled)")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchCategories()
    }
    
    private func setupBindings() {
        viewModel.bindCategories = { [weak self] _ in
            guard let self else { return }
            
            let hasCategories = viewModel.hasCategories
            tableView.isHidden = !hasCategories
            emptyImageView.isHidden = hasCategories
            descriptionLabel.isHidden = hasCategories
            
            tableViewHeightConstraint?.constant = CGFloat(categories.count) * 75
            tableView.reloadData()
        }
    }
    
    // MARK: - Layout
    
    private func setupLayout() {
        configureNavigationBar()
        view.addSubview(emptyImageView)
        view.addSubview(descriptionLabel)
        view.addSubview(addButton)
        view.addSubview(tableView)
        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableViewHeightConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            emptyImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            
            descriptionLabel.topAnchor.constraint(equalTo: emptyImageView.bottomAnchor, constant: 8),
            descriptionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }
    
    // MARK: - Helpers
    
    private func configureNavigationBar() {
        title = "Категория"
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .ypWhite
        appearance.shadowColor = nil
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: UIColor.ypBlack
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    // MARK: - Actions
    
    @objc private func addButtonTapped() {
        AnimationHelper.animateButtonPress(addButton) { [weak self] in
            let newCategoryVC = NewCategoryViewController()
            newCategoryVC.onCategoryCreated = { [weak self] in
                self?.viewModel.fetchCategories() // Обновляем список категорий после создания
            }
            self?.navigationController?.pushViewController(newCategoryVC, animated: true)
        }
    }
}

extension CategoryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let category = categories[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CategoryCell.reuseId, for: indexPath) as? CategoryCell else {
            return UITableViewCell()
        }
        
        cell.titleLabel.text = category.title
        cell.accessoryType = category.isSelected ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectCategory(at: indexPath.row)
        
        let selectedCategory = categories[indexPath.row]
        
        let dismissBlock: (() -> Void) = { [weak self] in
            guard let self else { return }
            self.delegate?.didSelectCategory(selectedCategory)
        }
        
        if let nav = navigationController, nav.viewControllers.first == self {
            dismiss(animated: true, completion: dismissBlock)
        } else {
            navigationController?.popViewController(animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: dismissBlock)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        let category = categories[indexPath.row]
        
        let editAction = UIContextualAction(style: .normal, title: "Редактировать") { [weak self] _, _, done in
            self?.editCategory(category)
            done(true)
        }
        editAction.backgroundColor = .systemBlue
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] _, _, done in
            self?.confirmDeleteCategory(at: indexPath.row)
            done(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
    
    func tableView(_ tableView: UITableView,
                   contextMenuConfigurationForRowAt indexPath: IndexPath,
                   point: CGPoint) -> UIContextMenuConfiguration? {
        
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: nil) { _ in
            let delete = UIAction(title: "Удалить", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.confirmDeleteCategory(at: indexPath.row)
            }
            
            let edit = UIAction(title: "Редактировать", image: UIImage(systemName: "pencil")) { [weak self] _ in
                guard let self = self else { return }
                let category = self.categories[indexPath.row]
                self.editCategory(category)
            }
            
            return UIMenu(title: "", children: [edit, delete])
        }
    }
    private func editCategory(_ category: TrackerCategoryCoreData) {
        let editVC = NewCategoryViewController()
        editVC.configure(with: category)
        navigationController?.pushViewController(editVC, animated: true)
    }
    
    private func confirmDeleteCategory(at index: Int) {
        let alert = UIAlertController(
            title: "Эта категория точно не нужна?",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteCategory(at: index)
        })
        
        present(alert, animated: true)
    }
    
}

