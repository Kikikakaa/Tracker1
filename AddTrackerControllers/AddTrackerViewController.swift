import UIKit

protocol AddTrackerDelegate: AnyObject {
    func didCreateTracker(_ tracker: Tracker, in category: TrackerCategoryCoreData)
}

final class AddTrackerViewController: UIViewController {
    
    var mode: Mode = .create
    weak var delegate: AddTrackerDelegate?
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Создание трекера"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var habitAddButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor(resource: .ypBlack)
        button.setTitle("Привычка", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.ypWhite, for: .normal)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(addHabitTapped), for: .touchUpInside)
        return button
    }()
     
    private lazy var randomEventAddButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor(resource: .ypBlack)
        button.setTitle("Нерегулярное событие", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.ypWhite, for: .normal)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(addRandomEventTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhite
        setupUI()
    }
    
    private func setupUI() {
        view.addSubviews([titleLabel, habitAddButton, randomEventAddButton])
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 38),
            
            habitAddButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            habitAddButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            habitAddButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            habitAddButton.heightAnchor.constraint(equalToConstant: 60),
            
            randomEventAddButton.topAnchor.constraint(equalTo: habitAddButton.bottomAnchor, constant: 16),
            randomEventAddButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            randomEventAddButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            randomEventAddButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }
    
    @objc private func addHabitTapped() {
        let habitCreationVC = HabitCreationViewController()
        if case .edit(let tracker) = mode {
            habitCreationVC.mode = .edit(tracker)
        }
        habitCreationVC.onTrackerCreated = { [weak self] (tracker: Tracker, category: TrackerCategoryCoreData) in
            self?.delegate?.didCreateTracker(tracker, in: category)
        }
        navigationController?.pushViewController(habitCreationVC, animated: true)
    }
    
    @objc private func addRandomEventTapped() {
        let randomEventCreationVC = RandomEventCreationViewController()
        randomEventCreationVC.onTrackerCreated = { [weak self] tracker, category in
            self?.delegate?.didCreateTracker(tracker, in: category)
        }
        navigationController?.pushViewController(randomEventCreationVC, animated: true)
    }
}
