import UIKit

protocol FilterSelectionDelegate: AnyObject {
    func didSelectFilter(_ filter: FilterType)
}

enum FilterType: CaseIterable {
    case all, today, completed, notCompleted

    var title: String {
        switch self {
        case .all: return "Все трекеры"
        case .today: return "Трекеры на сегодня"
        case .completed: return "Завершенные"
        case .notCompleted: return "Не завершенные"
        }
    }
    
    var shouldShowCheckmark: Bool {
        switch self {
        case .all, .today:
            return false
        case .completed, .notCompleted:
            return true
        }
    }
}

final class FilterViewController: UIViewController {

    weak var delegate: FilterSelectionDelegate?
    var selectedFilter: FilterType = .all

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Фильтры"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .ypBlack
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let filtersContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundDay
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let filtersStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhite
        setupLayout()
        setupFilters()
    }

    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(filtersContainer)
        filtersContainer.addSubview(filtersStack)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 28),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            filtersContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            filtersContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            filtersContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            filtersContainer.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            filtersStack.topAnchor.constraint(equalTo: filtersContainer.topAnchor),
            filtersStack.bottomAnchor.constraint(equalTo: filtersContainer.bottomAnchor),
            filtersStack.leadingAnchor.constraint(equalTo: filtersContainer.leadingAnchor, constant: 16),
            filtersStack.trailingAnchor.constraint(equalTo: filtersContainer.trailingAnchor, constant: -16)
        ])
    }

    private func setupFilters() {
        filtersStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, filter) in FilterType.allCases.enumerated() {
            let row = makeFilterRow(for: filter, index: index)
            filtersStack.addArrangedSubview(row)

            if index < FilterType.allCases.count - 1 {
                filtersStack.addArrangedSubview(makeDivider())
            }
        }
    }

    private func makeFilterRow(for filter: FilterType, index: Int) -> UIView {
        let label = UILabel()
        label.text = filter.title
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false

        let checkmark = UIImageView()
        if filter.shouldShowCheckmark && filter == selectedFilter {
            checkmark.image = UIImage(systemName: "checkmark")
            checkmark.tintColor = .ypBlue
        } else {
            checkmark.image = nil
        }
        
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        checkmark.setContentHuggingPriority(.required, for: .horizontal)
        checkmark.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        let rowStack = UIStackView(arrangedSubviews: [label, checkmark])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.distribution = .fill
        rowStack.spacing = 8
        rowStack.translatesAutoresizingMaskIntoConstraints = false

        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(rowStack)

        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: wrapper.topAnchor),
            rowStack.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            rowStack.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            rowStack.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            wrapper.heightAnchor.constraint(equalToConstant: 75)
        ])

        wrapper.tag = index
        wrapper.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(filterTapped(_:))))
        return wrapper
    }

    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return divider
    }

    @objc private func filterTapped(_ gesture: UITapGestureRecognizer) {
        guard let index = gesture.view?.tag,
              index < FilterType.allCases.count else { return }

        selectedFilter = FilterType.allCases[index]
        setupFilters()

        delegate?.didSelectFilter(selectedFilter)
    }
}
