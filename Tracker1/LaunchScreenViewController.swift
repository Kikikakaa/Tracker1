import UIKit

final class LaunchScreenViewController: UIViewController {
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(resource: .logo))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private static var window: UIWindow? {
        return UIApplication.shared.windows.first
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(resource: .ypBlue)
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.showMainScreen()
        }
    }
    
    private func showMainScreen() {
        
        let hasSeenOnboarding = UserDefaultsService.shared.hasSeenOnboarding
        
        guard let window = LaunchScreenViewController.window else {
            print("❌ Не удалось получить окно")
            return
        }
        
        if hasSeenOnboarding {
            let tabBarController = TabBarController()
            
            let navController = UINavigationController(rootViewController: tabBarController)
            navController.isNavigationBarHidden = true
            
            window.rootViewController = navController
            UIView.transition(
                with: window,
                duration: 0.5,
                options: .transitionCrossDissolve,
                animations: nil,
                completion: nil
            )
        } else {
            let onboardingVC = OnboardingViewController()
            onboardingVC.onFinish = {
                UserDefaultsService.shared.hasSeenOnboarding = true
                
                let tabBarController = TabBarController()
                
                let navController = UINavigationController(rootViewController: tabBarController)
                navController.isNavigationBarHidden = true
                
                window.rootViewController = navController
                UIView.transition(
                    with: window,
                    duration: 0.5,
                    options: .transitionCrossDissolve,
                    animations: nil,
                    completion: nil
                )
            }
            window.rootViewController = onboardingVC
            UIView.transition(
                with: window,
                duration: 0.5,
                options: .transitionCrossDissolve,
                animations: nil,
                completion: nil
            )
        }
    }
    
    private func setupUI() {
        view.addSubview(logoImageView)
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 91),
            logoImageView.heightAnchor.constraint(equalToConstant: 94)
        ])
    }
}
