import UIKit

final class OnboardingViewController: UIPageViewController {
    
    var onFinish: (() -> Void)?
    
    private var didSetInitialPage = false
    
    private let pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPageIndicatorTintColor = .ypBlack
        control.pageIndicatorTintColor = .ypGray
        control.translatesAutoresizingMaskIntoConstraints = false
        control.isUserInteractionEnabled = false
        return control
    }()


    private lazy var pages: [UIViewController] = [
        OnboardingPageViewController(
            imageName: "bckgrndBlue",
            labelText: "Отслеживайте только то, что хотите",
            onButtonTap: { [weak self] in self?.finishOnboarding() }
        ),
        OnboardingPageViewController(
            imageName: "bckgrndRed",
            labelText: "Даже если это\nне литры воды и йога",
            onButtonTap: { [weak self] in self?.finishOnboarding() }
        )
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self

        setViewControllers([pages[0]], direction: .forward, animated: false)

        view.addSubview(pageControl)
        setupPageControlConstraints()
        view.bringSubviewToFront(pageControl)

        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !didSetInitialPage {
            pageControl.currentPage = 0
            didSetInitialPage = true
        }
    }

    private func finishOnboarding() {
        onFinish?()
    }
    
    private func setupPageControlConstraints() {
        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -134),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}

extension OnboardingViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), index > 0 else { return nil }
        return pages[index - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), index < pages.count - 1 else { return nil }
        return pages[index + 1]
    }
}

extension OnboardingViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard completed,
              let currentVC = viewControllers?.first,
              let index = pages.firstIndex(of: currentVC) else { return }
        pageControl.currentPage = index
    }
}
