import UIKit

final class TrackerViewController: UIViewController {
    
    private var categories: [TrackerCategory] = []
    private var visibleCategories: [TrackerCategory] = []
    private var completedTrackers: [TrackerRecord] = []
    private var currentDate = Date()
    private let trackerStore = TrackerStore(context: CoreDataManager.shared.context)
    private let categoryStore = TrackerCategoryStore(context: CoreDataManager.shared.context)
    private let recordStore = TrackerRecordStore(context: CoreDataManager.shared.context)
    private var currentFilter: FilterType = .all
    private let cellIdentifier = TrackerCollectionViewCell.identifier
    private let collectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.contentInset = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: 45,
            right: 0
        )
        return collectionView
    }()
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = NSLocalizedString("search_placeholder", comment: "")
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.delegate = self
        
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
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
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
        let button =  UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .label
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
        label.text = NSLocalizedString("empty_placeholder", comment: "")
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("trackers_title", comment: "")
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let filtersButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("filters_button_title", comment: ""), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.backgroundColor = .ypBlue
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapFilters), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .ypWhite)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)
        setupUI()
        setupCollectionView()
        trackerAddButton.addTarget(self, action: #selector(addTrackerTapped), for: .touchUpInside)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        do {
            try trackerStore.cleanupDuplicates()
        } catch {
            print("❌ Ошибка очистки дубликатов: \(error)")
        }
        
        loadData()
        reloadContent()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Отслеживаем открытие экрана
        AnalyticsService.shared.trackScreenOpen(screen: .main)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Отслеживаем закрытие экрана
        AnalyticsService.shared.trackScreenClose(screen: .main)
    }
    
    private func loadData() {
        do {
            // Очищаем локальные массивы перед загрузкой
            categories.removeAll()
            completedTrackers.removeAll()
            visibleCategories.removeAll()
            
            // Сначала очищаем дубликаты в Core Data
            try trackerStore.cleanupDuplicates()
            
            // Загрузка категорий и трекеров из Core Data
            let coreDataCategories = try categoryStore.fetchAllCategories()
            
            // Теперь дубликаты уже не должны появляться, но оставляем проверку как дополнительную защиту
            var uniqueCategories: [TrackerCategory] = []
            
            for category in coreDataCategories {
                // Создаем Set для отслеживания уникальных ID трекеров в этой категории
                var seenTrackerIds: Set<UUID> = []
                var uniqueTrackers: [Tracker] = []
                
                for tracker in category.trackers {
                    if !seenTrackerIds.contains(tracker.id) {
                        seenTrackerIds.insert(tracker.id)
                        uniqueTrackers.append(tracker)
                    } else {
                        print("⚠️ Обнаружен дубликат трекера в категории: \(tracker.title) (ID: \(tracker.id))")
                    }
                }
                
                if !uniqueTrackers.isEmpty {
                    uniqueCategories.append(TrackerCategory(
                        id: category.id,
                        title: category.title,
                        trackers: uniqueTrackers
                    ))
                }
            }
            
            categories = uniqueCategories
            
            // Загрузка выполненных трекеров из Core Data
            completedTrackers = try recordStore.fetchAllRecords()
            
            print("✅ Загружено \(categories.count) категорий с \(categories.flatMap { $0.trackers }.count) уникальными трекерами")
            
        } catch {
            print("❌ Ошибка загрузки данных: \(error)")
        }
    }
    
    private func updateVisibleCategories() {
        let filteredByDateAndType = filteredCategories()
         
        if let searchText = searchBar.text, !searchText.isEmpty {
            // Дополнительная фильтрация по поисковому запросу
            visibleCategories = filteredByDateAndType.compactMap { category in
                let searchFilteredTrackers = category.trackers.filter { tracker in
                    tracker.title.lowercased().contains(searchText.lowercased())
                }
                
                if !searchFilteredTrackers.isEmpty {
                    return TrackerCategory(id: category.id, title: category.title, trackers: searchFilteredTrackers)
                } else {
                    return nil
                }
            }
        } else {
            // Без поиска - используем результат фильтрации по дате и типу
            visibleCategories = filteredByDateAndType
        }
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
    
    @objc private func didTapFilters() {
        AnalyticsService.shared.trackButtonClick(screen: .main, item: .filter)
        let filterVC = FilterViewController()
        filterVC.delegate = self
        filterVC.selectedFilter = currentFilter
        filterVC.modalPresentationStyle = .pageSheet
        present(filterVC, animated: true)
    }
    
    @objc private func dateChanged() {
        currentDate = datePicker.date
        AnalyticsService.shared.trackDateChanged(selectedDate: currentDate)
        reloadContent()
    }
    
    private func updateFiltersButtonVisibility(with filteredCategories: [TrackerCategory]) {
        let hasAnyTrackers = categories.flatMap { $0.trackers }.count > 0
        filtersButton.isHidden = !hasAnyTrackers
    }
    
    private func updateStubVisibility() {
        let hasTrackers = !visibleCategories.isEmpty
        stubImageView.isHidden = hasTrackers
        stubLabel.isHidden = hasTrackers
        
        // Обновляем текст заглушки в зависимости от фильтра
        updateStubText()
    }
    
    private func filteredCategories() -> [TrackerCategory] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: currentDate)
        guard let currentWeekday = Weekday(rawValue: weekday) else {
            return categories
        }

        // Сначала фильтруем по дате и расписанию
        let dateFiltered = categories.compactMap { category in
            let filteredTrackers = category.trackers.filter { tracker in
                if tracker.schedule == nil {
                    return true
                }
                return tracker.schedule?.contains(currentWeekday) ?? false
            }
            
            if !filteredTrackers.isEmpty {
                return TrackerCategory(id: category.id, title: category.title, trackers: filteredTrackers)
            } else {
                return nil
            }
        }
        
        // Затем применяем фильтр по типу
        let typeFiltered = applyCurrentFilter(to: dateFiltered)
        
        return typeFiltered
    }
    
    private func isTrackerCompletedToday(_ tracker: Tracker) -> Bool {
        let calendar = Calendar.current
        return completedTrackers.contains { record in
            calendar.isDate(record.date, inSameDayAs: currentDate) && record.trackerId == tracker.id
        }
    }
    
    private func completeTracker(_ tracker: Tracker) {
        if isTrackerCompletedToday(tracker) {
            return
        }
        AnalyticsService.shared.trackButtonClick(screen: .main, item: .track)
        do {
            try recordStore.addRecord(trackerId: tracker.id, date: currentDate)
            let record = TrackerRecord(id: UUID(), trackerId: tracker.id, date: currentDate)
            completedTrackers.append(record)
            
            let completedDays = daysCompleted(for: tracker)
            AnalyticsService.shared.trackTrackerCompleted(
                trackerId: tracker.id,
                trackerTitle: tracker.title,
                isCompleted: true,
                completedDaysCount: completedDays
            )
        } catch {
            print("❌ Ошибка при сохранении записи: \(error)")
        }
        
        // Перезагружаем UI в любом случае
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    private func reloadCompletedTrackers() {
        do {
            completedTrackers = try recordStore.fetchAllRecords()
        } catch {
            print("❌ Ошибка при перезагрузке записей: \(error)")
        }
    }
    
    private func completeTrackerUpdated(_ tracker: Tracker) {
        if isTrackerCompletedToday(tracker) {
            return
        }
        
        do {
            try recordStore.addRecord(trackerId: tracker.id, date: currentDate)
            reloadCompletedTrackers() // Перезагружаем данные из Core Data
        } catch {
            print("❌ Ошибка при сохранении записи: \(error)")
        }
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }

    private func uncompleteTrackerUpdated(_ tracker: Tracker) {
        do {
            try recordStore.deleteRecord(trackerId: tracker.id, date: currentDate)
            reloadCompletedTrackers() // Перезагружаем данные из Core Data
        } catch {
            print("❌ Ошибка при удалении записи: \(error)")
        }
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    private func uncompleteTracker(_ tracker: Tracker) {
        AnalyticsService.shared.trackButtonClick(screen: .main, item: .track)
        do {
            // Удаляем из Core Data
            try recordStore.deleteRecord(trackerId: tracker.id, date: currentDate)
            
            // Обновляем локальный массив
            completedTrackers.removeAll { record in
                let calendar = Calendar.current
                return calendar.isDate(record.date, inSameDayAs: currentDate) && record.trackerId == tracker.id
            }
            
            let completedDays = daysCompleted(for: tracker)
            AnalyticsService.shared.trackTrackerCompleted(
                trackerId: tracker.id,
                trackerTitle: tracker.title,
                isCompleted: false,
                completedDaysCount: completedDays
            )
        } catch {
            print("❌ Ошибка при удалении записи: \(error)")
        }
        
        // Перезагружаем UI в любом случае
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    private func daysCompleted(for tracker: Tracker) -> Int {
        do {
             // Получаем актуальное количество из Core Data
             return try recordStore.countRecords(for: tracker.id)
         } catch {
             print("❌ Ошибка при подсчете выполненных дней: \(error)")
             // Fallback на локальный массив
             return completedTrackers.filter { $0.trackerId == tracker.id }.count
         }
    }
    
    private func setupUI() {
        view.addSubviews([titleLabel, trackerAddButton, datePicker, searchBar, stubLabel, stubImageView, collectionView, filtersButton])
        
        view.bringSubviewToFront(filtersButton)
        
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
            searchBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            
            filtersButton.heightAnchor.constraint(equalToConstant: 50),
            filtersButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filtersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            filtersButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
        ])
    }
}

extension TrackerViewController: UICollectionViewDelegate {
     func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
         // Скрываем клавиатуру при начале прокрутки
         if searchBar.isFirstResponder {
             searchBar.resignFirstResponder()
         }
     }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return nil // Используем контекстное меню из ячейки
    }
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
        visibleCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        visibleCategories[section].trackers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? TrackerCollectionViewCell else {
            print("⚠️ Ошибка: Не удалось создать ячейку")
            return UICollectionViewCell()
        }
        let category = visibleCategories[indexPath.section]
        let tracker = category.trackers[indexPath.item]
        let isCompleted = isTrackerCompletedToday(tracker)
        let daysCompleted = daysCompleted(for: tracker)
        let isPinned = false
        
        cell.configure(with: tracker, completedDays: daysCompleted, isCompleted: isCompleted, isPinned: isPinned)
        
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
        
        cell.onPinButtonTapped = { [weak self] in
            self?.togglePin(for: tracker)
        }
        
        cell.onEditButtonTapped = { [weak self] in
            AnalyticsService.shared.trackButtonClick(screen: .main, item: .edit)
            self?.editTracker(tracker)
        }
        
        cell.onDeleteButtonTapped = { [weak self] in
            AnalyticsService.shared.trackButtonClick(screen: .main, item: .delete)
            self?.showDeleteConfirmation(for: tracker)
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
        
        let category = visibleCategories[indexPath.section]
        header.titleLabel.text = category.title
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 20)
    }
    
}

extension TrackerViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            AnalyticsService.shared.trackSearch(query: searchText)
        }
        
        reloadContent()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        reloadContent()
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
    
    func addNewTracker(_ tracker: Tracker, to selectedCategory: TrackerCategoryCoreData) {
        do {
            // Сохраняем трекер в Core Data
            try trackerStore.addTracker(tracker, category: selectedCategory)
            
            AnalyticsService.shared.trackTrackerCreated(
                 trackerTitle: tracker.title,
                 category: selectedCategory.title ?? "Без категории",
                 hasSchedule: tracker.schedule != nil
             )
            
            // Обновляем локальные данные
            let categoryTitle = selectedCategory.title ?? "Без категории"
            
            if let index = categories.firstIndex(where: { $0.title == categoryTitle }) {
                var updatedTrackers = categories[index].trackers
                updatedTrackers.append(tracker)
                categories[index] = TrackerCategory(
                    id: categories[index].id,
                    title: categoryTitle,
                    trackers: updatedTrackers
                )
            } else {
                let newCategory = TrackerCategory(
                    id: selectedCategory.id ?? UUID(),
                    title: categoryTitle,
                    trackers: [tracker]
                )
                categories.append(newCategory)
            }
            
            DispatchQueue.main.async {
                self.reloadContent()
            }
        } catch {
            print("❌ Ошибка при сохранении трекера: \(error)")
        }
    }
    
    private func togglePin(for tracker: Tracker) {
        // Реализация переключения состояния закрепления
        print("Закрепить/открепить трекер: \(tracker.title)")
        // Здесь нужно обновить состояние в CoreData и перезагрузить данные
    }
    
    private func editTracker(_ tracker: Tracker) {
        let habitCreationVC = HabitCreationViewController()
        habitCreationVC.mode = .edit(tracker) // Устанавливаем режим редактирования
        
        // Find the category for the tracker
        if let category = try? categoryStore.fetchCategory(for: tracker.id) {
            habitCreationVC.selectedCategory = category
        }
        
        // Важно: устанавливаем делегат для обработки результата
        habitCreationVC.onTrackerCreated = { [weak self] updatedTracker, category in
            // Используем метод делегата для единообразной обработки
            self?.didCreateTracker(updatedTracker, in: category)
        }
        
        present(habitCreationVC, animated: true)
    }
    
    private func updateTracker(_ tracker: Tracker, in category: TrackerCategoryCoreData) {
        do {
            try trackerStore.updateTracker(tracker, in: category)
            loadData()
            reloadContent()
        } catch {
            print("❌ Ошибка при обновлении трекера: \(error)")
        }
    }
    
    private func deleteTracker(_ tracker: Tracker) {
        do {
            // 1. Удаляем все записи о выполнении трекера
            try recordStore.deleteAllRecords(for: tracker.id)
            
            // 2. Удаляем сам трекер
            try trackerStore.deleteTracker(tracker.id)
            // Обновляем локальные данные
            for (index, category) in categories.enumerated() {
                if let trackerIndex = category.trackers.firstIndex(where: { $0.id == tracker.id }) {
                    var updatedTrackers = category.trackers
                    updatedTrackers.remove(at: trackerIndex)
                    
                    if updatedTrackers.isEmpty {
                        categories.remove(at: index)
                        } else {
                            categories[index] = TrackerCategory(
                                id: category.id,
                                title: category.title,
                                trackers: updatedTrackers
                            )
                        }
                        break
                    }
                }
                
                completedTrackers.removeAll { $0.trackerId == tracker.id }
                
                DispatchQueue.main.async {
                    self.reloadContent()
                }
                
            } catch {
                print("❌ Ошибка при удалении трекера: \(error)")
            }
        }
    
    private func showDeleteConfirmation(for tracker: Tracker) {
        let alert = UIAlertController(
            title: "Удаление трекера",
            message: "Вы уверены, что хотите удалить трекер \"\(tracker.title)\"?",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.deleteTracker(tracker)
        })
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        
        present(alert, animated: true)
    }
    
}

extension TrackerViewController: AddTrackerDelegate {
    func didCreateTracker(_ tracker: Tracker, in category: TrackerCategoryCoreData) {
        // Проверяем, есть ли уже трекер с таким ID в массиве
        var trackerExists = false
        
        for (categoryIndex, existingCategory) in categories.enumerated() {
            if let trackerIndex = existingCategory.trackers.firstIndex(where: { $0.id == tracker.id }) {
                // Трекер найден - это редактирование
                trackerExists = true
                var updatedTrackers = existingCategory.trackers
                updatedTrackers[trackerIndex] = tracker
                
                categories[categoryIndex] = TrackerCategory(
                    id: existingCategory.id,
                    title: existingCategory.title,
                    trackers: updatedTrackers
                )
                break
            }
        }
        
        // Если трекер не найден, добавляем как новый
        if !trackerExists {
            addNewTracker(tracker, to: category)
        } else {
            // Если найден, просто обновляем UI
            DispatchQueue.main.async {
                self.reloadContent()
            }
        }
    }
}

extension TrackerViewController: FilterSelectionDelegate {
    func didSelectFilter(_ filter: FilterType) {
        print("Выбран фильтр:", filter.title)
        currentFilter = filter
        
        // Автоматически устанавливаем текущую дату для фильтра "Трекеры на сегодня"
        if filter == .today {
            let today = Date()
            currentDate = today
            
            datePicker.setDate(today, animated: true)
        }
        
        reloadContent()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.dismiss(animated: true)
        }
    }
}

extension TrackerViewController {
    
    // MARK: - Filter Methods
    
    func reloadContent() {
        updateVisibleCategories()
        collectionView.reloadData()
        updateStubVisibility()
        updateFiltersButtonVisibility(with: categories)
    }
    
    private func applyCurrentFilter(to categories: [TrackerCategory]) -> [TrackerCategory] {
        let calendar = Calendar.current
        
        switch currentFilter {
        case .all:
            return categories
            
        case .today:
            // Показываем только трекеры на сегодня
            let today = Date()
            let todayWeekday = calendar.component(.weekday, from: today)
            guard let currentWeekday = Weekday(rawValue: todayWeekday) else {
                return []
            }
            
            return categories.compactMap { category in
                let todayTrackers = category.trackers.filter { tracker in
                    if tracker.schedule == nil {
                        return true // Нерегулярные события показываем всегда
                    }
                    return tracker.schedule?.contains(currentWeekday) ?? false
                }
                
                if !todayTrackers.isEmpty {
                    return TrackerCategory(id: category.id, title: category.title, trackers: todayTrackers)
                } else {
                    return nil
                }
            }
            
        case .completed:
            // Показываем только завершенные на выбранную дату трекеры
            return categories.compactMap { category in
                let completedTrackers = category.trackers.filter { tracker in
                    isTrackerCompletedToday(tracker)
                }
                
                if !completedTrackers.isEmpty {
                    return TrackerCategory(id: category.id, title: category.title, trackers: completedTrackers)
                } else {
                    return nil
                }
            }
            
        case .notCompleted:
            // Показываем только незавершенные на выбранную дату трекеры
            return categories.compactMap { category in
                let notCompletedTrackers = category.trackers.filter { tracker in
                    !isTrackerCompletedToday(tracker)
                }
                
                if !notCompletedTrackers.isEmpty {
                    return TrackerCategory(id: category.id, title: category.title, trackers: notCompletedTrackers)
                } else {
                    return nil
                }
            }
        }
    }
    
    private func updateStubText() {
        // Если нет трекеров вообще - показываем стандартное сообщение
        if categories.flatMap({ $0.trackers }).isEmpty {
            stubLabel.text = NSLocalizedString("empty_placeholder", comment: "")
            return
        }
        
        // Если есть трекеры, но фильтр их скрывает - показываем соответствующее сообщение
        switch currentFilter {
        case .all:
            if let searchText = searchBar.text, !searchText.isEmpty {
                stubLabel.text = "Ничего не найдено"
            } else {
                stubLabel.text = NSLocalizedString("empty_placeholder", comment: "")
            }
        case .today:
            stubLabel.text = "На сегодня нет трекеров"
        case .completed:
            stubLabel.text = "Нет завершенных трекеров"
        case .notCompleted:
            stubLabel.text = "Нет незавершенных трекеров"
        }
    }
}
