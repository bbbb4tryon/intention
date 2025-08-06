//
//  TileOrganizerVC.swift
//  intention
//
//  Created by Benjamin Tryon on 8/5/25.
//

import UIKit
// Authority on delegates and section headers
final class TileOrganizerVC: UICollectionViewController {
    var onMoveTile: (TileM, UUID, UUID) -> Void = { _,_,_ in }
    private var categories: [CategoriesModel] = []
    private var dragSourceIndexPath: IndexPath?

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 48, height: 44)
        layout.headerReferenceSize = CGSize(width: UIScreen.main.bounds.width, height: 30)
        super.init(collectionViewLayout: layout)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.register(HeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true
        collectionView.reorderingCadence = .immediate
        collectionView.backgroundColor = .clear
    }

    func update(categories: [CategoriesModel]) {
        self.categories = categories
        collectionView.reloadData()
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        categories.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        categories[section].tiles.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let tile = categories[indexPath.section].tiles[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)

        var config = UIListContentConfiguration.cell()
        config.text = tile.text
        cell.contentConfiguration = config
        cell.backgroundColor = UIColor.systemGray6
        cell.layer.cornerRadius = 8
        cell.clipsToBounds = true

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else { return UICollectionReusableView() }
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! HeaderView
        header.label.text = categories[indexPath.section].persistedInput
        return header
    }
}

extension TileOrganizerVC: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        dragSourceIndexPath = indexPath
        let tile = categories[indexPath.section].tiles[indexPath.row]
        let itemProvider = NSItemProvider(object: tile.text as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = tile
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        session.localDragSession != nil
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath indexPath: IndexPath?) -> UICollectionViewDropProposal {
        UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard
            let destinationIndexPath = coordinator.destinationIndexPath,
            let sourceIndexPath = dragSourceIndexPath,
            let item = coordinator.items.first,
            let tile = item.dragItem.localObject as? TileM
        else {
            return
        }

        let fromCategoryID = categories[sourceIndexPath.section].id
        let toCategoryID = categories[destinationIndexPath.section].id

        onMoveTile(tile, fromCategoryID, toCategoryID)
        dragSourceIndexPath = nil
    }
}

final class HeaderView: UICollectionReusableView {
    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
}

