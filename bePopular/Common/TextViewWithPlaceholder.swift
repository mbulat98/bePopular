import UIKit

@IBDesignable
class TextViewWithPlaceholder: UITextView {
    override var text: String! {
        didSet {
            placeholderLabel.isHidden = !text.isEmpty
        }
    }
    private let defaultPadding: CGFloat = 8
    private let placeholderLabel = UILabel()
    private let notificationCenter = NotificationCenter.default

    @IBInspectable public var placeholder: String? {
        get {
            var placeholderText: String?
            placeholderText = placeholderLabel.text

            return placeholderText
        }
        set {
            placeholderLabel.text = newValue
            placeholderLabel.sizeToFit()
        }
    }

    @IBInspectable private var placeHolderColor: UIColor? {
        get {
            return textColor
        }
        set {
            placeholderLabel.textColor = newValue
        }
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        configureView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureView()
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        resizePlaceholder()
    }

    private func setupTheme() {
 //       layer.cornerRadius = 4
 //       layer.borderWidth = 0.5
//        layer.borderColor = goldColor.cgColor
        placeholderLabel.font = font ?? UIFont(name: "Gotham-Book", size: 11)
        backgroundColor = UIColor.clear
        textContainerInset = UIEdgeInsets(top: 14, left: 8, bottom: 14, right: 8)
    }

    private func setupTextChangeObserver() {
        notificationCenter.addObserver(self, selector: #selector(textDidChange), name: UITextView.textDidChangeNotification, object: nil)
    }

    @objc public func textDidChange() {
        placeholderLabel.isHidden = !text.isEmpty
    }

    func removeText() {
        self.text.removeAll()
        placeholderLabel.isHidden = false
    }

    private func configureView() {
        setupTheme()
        addPlaceholder()
        setupTextChangeObserver()
    }

    private func resizePlaceholder() {
        let labelX: CGFloat = 12
        let labelY: CGFloat = placeholderLabel.frame.height / 2
        let labelWidth = self.bounds.width - (labelX * 2)
        let labelHeight = placeholderLabel.frame.height

        placeholderLabel.frame = CGRect(x: labelX, y: labelY, width: labelWidth, height: labelHeight)
    }

    private func addPlaceholder() {
        placeholderLabel.sizeToFit()
        placeholderLabel.numberOfLines = 0

        placeholderLabel.font = self.font
        placeholderLabel.isHidden = !self.text.isEmpty

        self.addSubview(placeholderLabel)
    }
}
