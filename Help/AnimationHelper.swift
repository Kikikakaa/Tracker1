import UIKit

enum AnimationHelper {
    static func animateButtonPress(_ button: UIButton, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.1, animations: {
            button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }, completion: { _ in
            UIView.animate(withDuration: 0.1, animations: {
                button.transform = .identity
            }, completion: { _ in
                completion?()
            })
        })
    }
}
