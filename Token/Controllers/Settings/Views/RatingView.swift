import UIKit
import SweetUIKit

open class RatingView: UIView {

    private var starSize: CGFloat = 12
    private var rating: Float = 0
    private(set) var numberOfStars: Int = 0

    private lazy var backgroundStars: UIView = {
        let view = UIView(withAutoLayout: true)
        view.layer.mask = self.starsMask
        view.backgroundColor = Theme.ratingBackground

        return view
    }()

    private lazy var ratingStars: UIView = {
        let view = UIView(withAutoLayout: true)
        view.layer.mask = self.starsMask
        view.backgroundColor = Theme.ratingTint

        return view
    }()

    private lazy var ratingConstraint: NSLayoutConstraint = {
        self.ratingStars.widthAnchor.constraint(equalToConstant: 0)
    }()

    convenience init(numberOfStars: Int, customStarSize: CGFloat? = nil) {
        self.init(frame: .zero)
        self.numberOfStars = numberOfStars

        if let customStarSize = customStarSize {
            self.starSize = customStarSize
            self.backgroundStars.backgroundColor = Theme.greyTextColor
        }

        self.addSubview(self.backgroundStars)

        NSLayoutConstraint.activate([
            self.backgroundStars.topAnchor.constraint(equalTo: self.topAnchor),
            self.backgroundStars.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.backgroundStars.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.backgroundStars.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.backgroundStars.widthAnchor.constraint(equalToConstant: starSize * CGFloat(numberOfStars)).priority(.high),
            self.backgroundStars.heightAnchor.constraint(equalToConstant: starSize).priority(.high),
        ])

        self.addSubview(self.ratingStars)

        NSLayoutConstraint.activate([
            self.ratingStars.topAnchor.constraint(equalTo: self.topAnchor),
            self.ratingStars.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.ratingStars.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])

        self.ratingConstraint.isActive = true
    }

    func set(rating: Float, animated: Bool = false) {
        self.rating = min(Float(self.numberOfStars), max(0, rating))
        self.ratingConstraint.constant = self.starSize * CGFloat(rating)

        if animated {
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .easeOut, animations: {
                self.layoutIfNeeded()
            }, completion: nil)
        } else {
            self.layoutIfNeeded()
        }
    }

    var starsMask: CALayer {
        let starRadius = self.starSize / 2

        let mask = CAShapeLayer()
        mask.frame = CGRect(x: 0, y: 0, width: self.starSize, height: self.starSize)
        mask.position = CGPoint(x: starRadius, y: starRadius)

        var mutablePath: CGMutablePath?

        for i in 0 ..< self.numberOfStars {

            if let mutablePath = mutablePath {
                mutablePath.addPath(self.starPath(with: starRadius, offset: CGFloat(i) * self.starSize))
            } else {
                mutablePath = self.starPath(with: starRadius).mutableCopy()
            }
        }

        mask.path = mutablePath

        return mask
    }

    func starPath(with radius: CGFloat, offset: CGFloat = 0) -> CGPath {
        let center = CGPoint(x: radius, y: radius)
        let theta = CGFloat(Double.pi * 2) * (2 / 5)
        let flipVertical: CGFloat = -1

        let path = UIBezierPath()
        path.move(to: CGPoint(x: center.x, y: radius * center.y * flipVertical))

        for i in 0 ..< 6 {
            let x = radius * sin(CGFloat(i) * theta) + offset
            let y = radius * cos(CGFloat(i) * theta)
            path.addLine(to: CGPoint(x: x + center.x, y: (y * flipVertical) + center.y))
        }

        path.close()

        return path.cgPath
    }
}
