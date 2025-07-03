import UIKit

final class TrackerViewController: UIViewController {
    
    private var categories: [TrackerCategory] = []
    private var completedTrackers: [TrackerRecord] = []
    private var currentDate = Date()
    private let cellIdentifier = TrackerCollectionViewCell.identifier
    private let collectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Поиск"
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.layer.cornerRadius = 10
            textField.clipsToBounds = true
            NSLayoutConstraint.activate([
                textField.topAnchor.constraint(equalTo: searchBar.topAnchor),
                textField.bottomAnchor.constraint(equalTo: searchBar.bottomAnchor),
                textField.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor),
                textField.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor),
                textField.heightAnchor.constraint(equalToConstant: 36)
            ])
        }
        return searchBar
    }()
    
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
    
    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale(identifier: "ru_RU")
        picker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    private lazy var trackerAddButton: UIButton = {
        let button =  UIButton()
        button.setImage(UIImage(resource: .addTracker), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var stubImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .dizzyError)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var stubLabel: UILabel = {
        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Трекеры"
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .ypWhite)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)
        setupUI()
        setupCollectionView()
        trackerAddButton.addTarget(self, action: #selector(addTrackerTapped), for: .touchUpInside)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        categories = [
            TrackerCategory(title: "Тестовая категория 1", trackers: [
                Tracker(id: UUID(), title: "Трекер 1", color: .systemBlue, emoji: "😈", schedule: [.monday, .tuesday]),
                Tracker(id: UUID(), title: "Трекер 2", color: .systemGreen, emoji: "📚", schedule: [.wednesday])
            ]),
            TrackerCategory(title: "Тестовая категория 2", trackers: [
                Tracker(id: UUID(), title: "Трекер 3", color: .systemRed, emoji: "🔥", schedule: nil),
                Tracker(id: UUID(), title: "Трекер 4", color: .systemPurple, emoji: "🎉", schedule: nil)
            ])
        ]

        
        collectionView.reloadData()
        updateStubVisibility()
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(TrackerCollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.register(TrackerSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TrackerSectionHeaderView.identifier)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func dateChanged() {
        currentDate = datePicker.date
        collectionView.reloadData()
        updateStubVisibility()
    }
    
    private func updateStubVisibility() {
        let hasTrackers = !filteredCategories().isEmpty
        print("""
        \n=== Проверка заглушки ===
        Есть трекеры: \(hasTrackers ? "ДА" : "НЕТ")
        Заглушка: \(hasTrackers ? "скрыта" : "показана")
        """)
        stubImageView.isHidden = hasTrackers
        stubLabel.isHidden = hasTrackers
    }
    
    private func filteredCategories() -> [TrackerCategory] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: currentDate)
        guard let currentWeekday = Weekday(rawValue: weekday) else {
            print("⚠️ Ошибка: Не удалось определить текущий день недели")
            return categories // Возвращаем все категории в случае ошибки
        }
        
        print("""
    === Фильтрация трекеров ===
    Текущая дата: \(currentDate)
    День недели: \(currentWeekday.shortName)
    Всего категорий: \(categories.count)
    """)

        let filtered = categories.compactMap { category in
            let filteredTrackers = category.trackers.filter { tracker in
                if tracker.schedule == nil {
                    print("Трекер '\(tracker.title)': ✅ подходит (без расписания)")
                    return true
                }

                let isIncluded = tracker.schedule?.contains(currentWeekday) ?? false
                print("Трекер '\(tracker.title)': \(isIncluded ? "✅ подходит" : "❌ не подходит")")
                return isIncluded
            }
            
            if !filteredTrackers.isEmpty {
                return TrackerCategory(title: category.title, trackers: filteredTrackers)
            } else {
                return nil
            }
        }
        
        print("Результат фильтрации:")
        filtered.forEach { print("- \($0.title): \($0.trackers.count) трекеров") }
        return filtered
    }
    
    private func isTrackerCompletedToday(_ tracker: Tracker) -> Bool {
        let calendar = Calendar.current
        return completedTrackers.contains { record in
            calendar.isDate(record.date, inSameDayAs: currentDate) && record.trackerId == tracker.id
        }
    }
    
    private func completeTracker(_ tracker: Tracker) {
        let record = TrackerRecord(trackerId: tracker.id, date: currentDate)
        completedTrackers.append(record)
        collectionView.reloadData()
    }
    
    private func uncompleteTracker(_ tracker: Tracker) {
        completedTrackers.removeAll { record in
            let calendar = Calendar.current
            return calendar.isDate(record.date, inSameDayAs: currentDate) && record.trackerId == tracker.id
        }
        collectionView.reloadData()
    }
    
    private func daysCompleted(for tracker: Tracker) -> Int {
        completedTrackers.filter { $0.trackerId == tracker.id }.count
    }
    
    private func setupUI() {
        view.addSubviews([titleLabel, trackerAddButton, datePicker, searchBar, stubLabel, stubImageView, collectionView])
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 24),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44),
            
            trackerAddButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 6),
            trackerAddButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 1),
            trackerAddButton.widthAnchor.constraint(equalToConstant: 42),
            trackerAddButton.heightAnchor.constraint(equalToConstant: 42),
            
            datePicker.centerYAnchor.constraint(equalTo: trackerAddButton.centerYAnchor),
            datePicker.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            
            stubImageView.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            stubImageView.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            
            stubLabel.topAnchor.constraint(equalTo: stubImageView.bottomAnchor, constant: 8),
            stubLabel.centerXAnchor.constraint(equalTo: stubImageView.centerXAnchor),
            
            searchBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 7),
            searchBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            searchBar.heightAnchor.constraint(equalToConstant: 36),
            searchBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
            
        ])
    }
}

extension TrackerViewController: UICollectionViewDelegate {
    
}

extension TrackerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 9 - 16 * 2) / 2
        return CGSize(width: width, height: 148)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 9
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 12, left: 16, bottom: 16, right: 16)
    }
}

extension TrackerViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        filteredCategories().count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filteredCategories()[section].trackers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("\nЗапрошена ячейка для секции \(indexPath.section), строки \(indexPath.row)")
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? TrackerCollectionViewCell else {
            print("⚠️ Ошибка: Не удалось создать ячейку")
            return UICollectionViewCell()
        }
        let category = filteredCategories()[indexPath.section]
        let tracker = category.trackers[indexPath.item]
        let isCompleted = isTrackerCompletedToday(tracker)
        let daysCompleted = daysCompleted(for: tracker)
        
        cell.configure(with: tracker, completedDays: daysCompleted, isCompleted: isCompleted)
        
        let isFutureDate = currentDate > Date()
        cell.completeButton.isEnabled = !isFutureDate
        cell.completeButton.alpha = isFutureDate ? 0.3 : 1.0
        
        cell.onCompleteButtonTapped = { [weak self] in
            guard let self = self else { return }
            if isCompleted {
                self.uncompleteTracker(tracker)
            } else {
                self.completeTracker(tracker)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        
        guard let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: TrackerSectionHeaderView.identifier,
            for: indexPath
        ) as? TrackerSectionHeaderView else {
            assertionFailure("Не удалось создать header типа TrackerSectionHeaderView")
            return UICollectionReusableView()
        }
        
        let category = filteredCategories()[indexPath.section]
        header.titleLabel.text = category.title
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 20)
    }
    
}

extension TrackerViewController {
    @objc private func addTrackerTapped() {
        let addTrackerVC = AddTrackerViewController()
        addTrackerVC.delegate = self  // Устанавливаем делегат
        let navController = UINavigationController(rootViewController: addTrackerVC)
        navController.isNavigationBarHidden = true
        present(navController, animated: true)
    }
    
    func addNewTracker(_ tracker: Tracker) {
        print("""
        \n=== Получен трекер в TrackerViewController ===
        ID: \(tracker.id)
        Название: \(tracker.title)
        Дни: \(tracker.schedule?.map { $0.shortName } ?? [])
        """)
        
        let categoryTitle = "Мои трекеры"
        
        if let index = categories.firstIndex(where: { $0.title == categoryTitle }) {
            print("Найдена категория 'Мои трекеры' (индекс \(index))")
            var updatedTrackers = categories[index].trackers
            updatedTrackers.append(tracker)
            categories[index] = TrackerCategory(title: categoryTitle, trackers: updatedTrackers)
        } else {
            print("Создаем новую категорию 'Мои трекеры'")
            categories.append(TrackerCategory(title: categoryTitle, trackers: [tracker]))
        }
        
        print("Текущие категории после обновления:")
            categories.forEach { print("- \($0.title): \($0.trackers.count) трекеров") }
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.updateStubVisibility()
        }
    }
}

extension TrackerViewController: AddTrackerDelegate {
    func didCreateTracker(_ tracker: Tracker) {
        addNewTracker(tracker)
    }
}
