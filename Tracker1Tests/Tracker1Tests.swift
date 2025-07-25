import XCTest
import SnapshotTesting
@testable import Tracker1

final class TrackerTests: XCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    func testViewController() {
        let vc = TrackerViewController()
        
        // Загружаем view принудительно
        vc.loadViewIfNeeded()
        
        // Устанавливаем размер view для тестирования
        vc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        
        // Принудительно обновляем layout
        vc.view.layoutIfNeeded()
        
        // Тест для светлой темы
        assertSnapshot(
            of: vc,
            as: .image(traits: .init(userInterfaceStyle: .light))
        )
        
        // Тест для темной темы
        assertSnapshot(
            of: vc,
            as: .image(traits: .init(userInterfaceStyle: .dark))
        )
    }
    
    func testExample() throws {
        // Базовый тест для проверки работоспособности
        XCTAssertTrue(true)
    }
}
