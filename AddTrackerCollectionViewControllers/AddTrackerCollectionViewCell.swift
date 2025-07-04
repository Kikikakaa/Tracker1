import UIKit

final class AddTrackerCollectionViewCell: UICollectionViewCell {
    let cellIdentifier = "AddTrackerCollectionViewCell"
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let colorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let selectionBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.backgroundColor = .ypLightGray
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let colorSelectionView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 3
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var isEmojiCell = false
    private var isColorCell = false
    
    override init(frame: CGRect) {
        super .init(frame: frame)
        
        contentView.addSubviews([selectionBackgroundView, colorSelectionView, titleLabel, colorView])
        
        NSLayoutConstraint.activate([
            selectionBackgroundView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            selectionBackgroundView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            selectionBackgroundView.widthAnchor.constraint(equalToConstant: 52),
            selectionBackgroundView.heightAnchor.constraint(equalToConstant: 52),
            
            colorSelectionView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorSelectionView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorSelectionView.widthAnchor.constraint(equalToConstant: 46),
            colorSelectionView.heightAnchor.constraint(equalToConstant: 46),
            
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            colorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorView.widthAnchor.constraint(equalToConstant: 40),
            colorView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with color: UIColor, isSelected: Bool = false) {
        isColorCell = true
        isEmojiCell = false
        
        colorView.isHidden = false
        titleLabel.isHidden = true
        colorView.backgroundColor = color
        colorSelectionView.layer.borderColor = color.withAlphaComponent(0.3).cgColor
        
        setSelected(isSelected, animated: false)
    }
    
    func configure(with emoji: String, isSelected: Bool = false) {
        isEmojiCell = true
        isColorCell = false
        
        colorView.isHidden = true
        titleLabel.isHidden = false
        titleLabel.text = emoji
        
        setSelected(isSelected, animated: false)
    }
    
    func setSelected(_ selected: Bool, animated: Bool = true) {
           let duration = animated ? 0.1 : 0.0
           
           if isEmojiCell {
               if selected {
                   selectionBackgroundView.isHidden = false
                   UIView.animate(withDuration: duration) {
                       self.selectionBackgroundView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                   }
               } else {
                   UIView.animate(withDuration: duration, animations: {
                       self.selectionBackgroundView.transform = .identity
                   }) { _ in
                       self.selectionBackgroundView.isHidden = true
                   }
               }
           } else if isColorCell {
               if selected {
                   colorSelectionView.isHidden = false
                   UIView.animate(withDuration: duration) {
                       self.colorSelectionView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                   }
               } else {
                   UIView.animate(withDuration: duration, animations: {
                       self.colorSelectionView.transform = .identity
                   }) { _ in
                       self.colorSelectionView.isHidden = true
                   }
               }
           }
       }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        colorView.backgroundColor = nil
        selectionBackgroundView.isHidden = true
        colorSelectionView.isHidden = true
        selectionBackgroundView.transform = .identity
        colorSelectionView.transform = .identity
        isEmojiCell = false
        isColorCell = false
    }
}
