//
//  WeDataListScreenletView.swift
//  WeDeployApp
//
//  Created by Victor Galán on 16/01/2017.
//  Copyright © 2017 liferay. All rights reserved.
//

import UIKit
import WeDeploy
import WZLBadge

class WeDataListScreenletView: BaseListScreenletView {

	public static let LogoutAction = "LogoutAction"
	public static let OpenCartAction = "OpenCartAction"

	public enum LayoutType {
		case card
		case list
		case collection

		var icon: String  {
			switch self {
			case .card:
				return .cardLayout
			case .list:
				return .listLayout
			case .collection:
				return .collectionLayout
			}
		}

		var nextLayout: LayoutType {
			switch self {
			case .card:
				return .list
			case .list:
				return .collection
			case .collection:
				return .card
			}
		}

		var height: CGFloat {
			switch self {
			case .card:
				return 320
			case .list:
				return 132
			case .collection:
				return 252
			}
		}
	}

	public var currentLayout: LayoutType = .card

	public var totalItemsInCart: Int = 0

	public var previousOffset: CGFloat = 0

	var itemWidth: CGFloat = 0
	var itemHeight: CGFloat = 320

	@IBOutlet weak var topConstraint: NSLayoutConstraint!

	@IBOutlet weak var categoryView: ViewWithArrow! {
		didSet {
			categoryView.onClick = { [weak self] in
				self?.categoryButtonClick()
			}
		}
	}
	
	@IBOutlet weak var toolbarView: UIView! {
		didSet {
			toolbarView.layer.shadowColor = UIColor.black.cgColor
			toolbarView.layer.shadowOffset = CGSize(width: 0, height: 0);
			toolbarView.layer.shadowRadius = 5;
			toolbarView.layer.shadowOpacity = 0.2;
			toolbarView.layer.masksToBounds = false
		}
	}

	@IBOutlet weak var navigationBar: UINavigationBar! {
		didSet {
			navigationBar.titleTextAttributes = [
				NSForegroundColorAttributeName : UIColor.white,
				NSFontAttributeName: UIFont.boldSystemFont(ofSize: 20)
			]
			navigationBar.topItem?.title = "Supermarket"
			navigationBar.barTintColor = .mainColor
		}
	}
	@IBOutlet weak var cartIcon: UIBarButtonItem! {
		didSet {
			cartIcon.setTitleTextAttributes([
					NSForegroundColorAttributeName : UIColor.white,
					NSFontAttributeName: UIFont.iconFont16px(ofSize: 24)
				], for: .normal)
			cartIcon.title = .cart
		}
	}
	
	@IBOutlet weak var titleLabel: UILabel! {
		didSet {
			titleLabel.font = UIFont.semiboldWeFont(ofSize: 20)
		}
	}

	@IBOutlet weak var changeLayoutButton: UIButton! {
		didSet {
			changeLayoutButton.backgroundColor = .WeTextFieldSelectedBackgroundColor
			changeLayoutButton.setTitleColor(.WeTextColor, for: .normal)
			changeLayoutButton.layer.cornerRadius = 4
			changeLayoutButton.setTitle(currentLayout.nextLayout.icon, for: .normal)
		}
	}

	@IBOutlet weak var userPortraitScreenlet: UserPortraitScreenlet! {
		didSet {
			let recognizer = UITapGestureRecognizer(target: self, action: #selector(userPortraitClick))

			userPortraitScreenlet.addGestureRecognizer(recognizer)
		}
	}

	override func didMoveToWindow() {
		if window != nil {
			totalItemsInCart = ShopCart.shared.totalItemsCount

			if totalItemsInCart == 0 {
				cartIcon.clearBadge()
			}
			else {
				cartIcon.showBadge(with: .number, value: totalItemsInCart, animationType: .none)
			}
		}
	}

	override func onCreated() {
		super.onCreated()

		itemWidth = self.frame.width

		collectionView.backgroundColor = .white
		loadDataFrom(category: "All")
	}

	override func registerCell(with identifier: String) {
		let nib = UINib(nibName: "ProductCell", bundle: nil)
		self.collectionView.register(nib, forCellWithReuseIdentifier: identifier)
	}

	override open func configureCell(cell: UICollectionViewCell, item: Any) {
		let cell = cell as! ProductCell
		let item = item as! Product

		cell.imageUrl = item.imageUrl
		cell.nameLabel.text = item.name
		cell.priceLabel.text = "$\(item.price)"
		cell.onAddToCartClick = { [weak self] in
			self?.totalItemsInCart += 1
			ShopCart.shared.add(product: item)
			self?.cartIcon.showBadge(with: .number, value: self?.totalItemsInCart ?? 0, animationType: .none)
		}
	}

	@IBAction func changeLayoutButtonClick() {
		let nextType = self.currentLayout.nextLayout

		if case .collection = nextType {
			self.itemWidth = self.frame.width/2
		}
		else {
			self.itemWidth = self.frame.width
		}

		self.itemHeight = nextType.height
		self.changeLayoutButton.setTitle(nextType.nextLayout.icon, for: .normal)

		self.currentLayout = nextType

		self.collectionView.performBatchUpdates({
			self.collectionView.collectionViewLayout.invalidateLayout()
		}, completion: nil)
	}

	@IBAction func categoryButtonClick() {
		let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		let handler = { [weak self] (alertView: UIAlertAction) -> Void in
			self?.loadDataFrom(category: alertView.title ?? "All")
			self?.categoryView.text = alertView.title
		}

		let allAction = UIAlertAction(title: "All", style: .default, handler: handler)
		let bakeryAction = UIAlertAction(title: "Bakery", style: .default, handler: handler)
		let dairyAction = UIAlertAction(title: "Dairy", style: .default, handler: handler)
		let fruitAction = UIAlertAction(title: "Fruit", style: .default, handler: handler)
		let vegetableAction = UIAlertAction(title: "Vegetable", style: .default, handler: handler)
		let meatAction = UIAlertAction(title: "Meat", style: .default, handler: handler)

		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

		alertController.addAction(allAction)
		alertController.addAction(bakeryAction)
		alertController.addAction(dairyAction)
		alertController.addAction(fruitAction)
		alertController.addAction(vegetableAction)
		alertController.addAction(meatAction)
		alertController.addAction(cancelAction)

		UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
	}

	func userPortraitClick() {
		let logoutAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		let logoutAction = UIAlertAction(title: "Log out", style: .destructive) { [weak self] _ in

			ShopCart.shared.emptyCart()
			self?.perform(actionName: WeDataListScreenletView.LogoutAction, params: "")
		}

		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

		logoutAlert.addAction(logoutAction)
		logoutAlert.addAction(cancelAction)


		UIApplication.shared.keyWindow?.rootViewController?.present(logoutAlert, animated: true, completion: nil)
	}

	@IBAction func cartIconClick(_ sender: UIBarButtonItem) {
		perform(actionName: WeDataListScreenletView.OpenCartAction)
	}

	func loadDataFrom(category: String) {
		let query = LoadDataQuery().orderBy(field: "id", order: .ASC)

		if category != "All" {
			_ = query.filter(filter: Filter.equal("type", category.lowercased()))
		}

		let input = LoadDataInteractorInput(resourceName: "products", type: Product.self, dataQuery: query)
		self.perform(actionName: DataListScreenlet.LoadDataAction, params: input)
	}

	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let size = self.toolbarView.frame.height
		let scrollOffset = scrollView.contentOffset.y
		let scrollDiff = scrollOffset - self.previousOffset
		let scrollHeight = scrollView.frame.height
		let scrollcontentSizeHeight = scrollView.contentSize.height + scrollView.contentInset.bottom

		if scrollOffset <= -scrollView.contentInset.top {
			topConstraint.constant = 0
		} else if scrollOffset + scrollHeight >= scrollcontentSizeHeight {
			topConstraint.constant = -size
		} else {
			topConstraint.constant = min(0, max(-size, topConstraint.constant - scrollDiff))
		}

		self.previousOffset = scrollOffset
	}

	override open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: itemWidth, height: itemHeight)
	}

	open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {

		return 0
	}

}
