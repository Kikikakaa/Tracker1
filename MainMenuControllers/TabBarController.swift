import UIKit

final class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mainVC = TrackerViewController()
        mainVC.tabBarItem = UITabBarItem(
            title: "Трекеры",
            image: UIImage(resource: .recordCircle),
            tag: 0)
        
        let statsVC = StatisticsViewController()
        statsVC.tabBarItem = UITabBarItem(
            title: "Статистика",
            image: UIImage(resource: .hare),
            tag: 1)
        
        setViewControllers([mainVC, statsVC], animated: false)
        
        addTabBarBorder()
    }
    
    private func addTabBarBorder() {
        let border = UIView()
        border.translatesAutoresizingMaskIntoConstraints = false
        border.backgroundColor = .ypGray
        
        tabBar.addSubview(border)
        
        NSLayoutConstraint.activate([
            border.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            border.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            border.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            border.topAnchor.constraint(equalTo: tabBar.topAnchor)
        ])
    }
    
}
