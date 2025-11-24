////
////  TileOrganizerVC.swift
////  intention
////
////  Created by Benjamin Tryon on 8/5/25.
////
//
//#if !NO_POWER_ORGANIZER
//import UIKit
//// Authority on delegates and section headers - with reorder support and onReorder callback
////Within-category reorder (UIKit reordering, SwiftUI list drag end)
//
//final class TileOrganizerVC: UICollectionViewController {
//    var onMoveTile: (TileM, UUID, UUID) -> Void = { _, _, _ in }
//    var onReorder: (([TileM], UUID) -> Void)?
//    
//    // injected from wrapper
//    var textColor: UIColor = .label
//    var tileSeparatorColor: UIColor = .separator
//    var sectionSeparatorColor: UIColor = .separator
//    var headerTextColor: UIColor = .label
//
//    private var categories: [CategoriesModel] = []
//    private var dragSourceIndexPath: IndexPath?
//
//    init() {
//        let layout = UICollectionViewFlowLayout()
//        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
//        // Self-sizing cells: give an estimated size, let Auto Layout compute height
//        layout.estimatedItemSize = CGSize(width: UIScreen.main.bounds.width - 48, height: 56)
//        layout.itemSize = UICollectionViewFlowLayout.automaticSize
//        layout.headerReferenceSize = CGSize(width: UIScreen.main.bounds.width, height: 30)
//        super.init(collectionViewLayout: layout)
//    }
//
//    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
//        collectionView.register(HeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
//        collectionView.dragDelegate = self
//        collectionView.dropDelegate = self
//        collectionView.dragInteractionEnabled = true
//        collectionView.reorderingCadence = .immediate
//        collectionView.backgroundColor = .clear
//    }
//
//    func update(categories: [CategoriesModel]) {
//        self.categories = categories
//        collectionView.reloadData()
//    }
//
//    override func numberOfSections(in collectionView: UICollectionView) -> Int {
//        categories.count
//    }
//
//    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        categories[section].tiles.count
//    }
//
//    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let tile = categories[indexPath.section].tiles[indexPath.row]
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
//
//        var config = UIListContentConfiguration.cell()
//        config.text = tile.text
//        config.textProperties.numberOfLines = 0          // allow wrapping
//        config.textToSecondaryTextVerticalPadding = 6
//        config.directionalLayoutMargins = .init(top: 10, leading: 12, bottom: 10, trailing: 12)
//        
//        config.textProperties.color = textColor             // accent label from struct TileOrganizerWrapper
//        cell.contentConfiguration = config
//        cell.backgroundColor = UIColor.secondarySystemBackground
//        cell.layer.cornerRadius = 8
//        cell.clipsToBounds = true
//        
//        // add/remove bottom separator (tan) except for the last row in the section
//        cell.contentView.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }
//        let isLast = indexPath.row == collectionView.numberOfItems(inSection: indexPath.section) - 1
//        if !isLast {
//            let sep = UIView()
//            sep.tag = 999
//            sep.backgroundColor = tileSeparatorColor
//            sep.translatesAutoresizingMaskIntoConstraints = false
//            cell.contentView.addSubview(sep)
//            NSLayoutConstraint.activate([
//                sep.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),
//                sep.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 6),
//                sep.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -6),
//                sep.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
//        ])
//        }
//
//        return cell
//    }
//    
//    // reordering within a single category, but prevents dragging into a different category via reorder
//    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        guard kind == UICollectionView.elementKindSectionHeader else { return UICollectionReusableView() }
//        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! HeaderView
//        header.label.text = categories[indexPath.section].persistedInput
//        header.label.textColor = headerTextColor
//
//                // bottom line between categories using "history" border
//                header.subviews.filter { $0.tag == 777 }.forEach { $0.removeFromSuperview() }
//                let line = UIView()
//                line.tag = 777
//                line.backgroundColor = sectionSeparatorColor
//                line.translatesAutoresizingMaskIntoConstraints = false
//                header.addSubview(line)
//                NSLayoutConstraint.activate([
//                    line.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),
//                    line.leadingAnchor.constraint(equalTo: header.leadingAnchor),
//                    line.trailingAnchor.constraint(equalTo: header.trailingAnchor),
//                    line.bottomAnchor.constraint(equalTo: header.bottomAnchor)
//                ])
//        return header
//    }
//    
//    // reorders within a same section/ category persist with `moveItemAt()
//    override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
//        guard sourceIndexPath.section == destinationIndexPath.section else {
//            collectionView.reloadData()
//            return
//        }
//
//        let categoryID = categories[sourceIndexPath.section].id
//        var tiles = categories[sourceIndexPath.section].tiles
//        let movedTile = tiles.remove(at: sourceIndexPath.row)
//        tiles.insert(movedTile, at: destinationIndexPath.row)
//        categories[sourceIndexPath.section].tiles = tiles
//
//        // Persist the reorder
//        onReorder?(tiles, categoryID)
//    }
//}
//
//extension TileOrganizerVC: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
//    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
//        dragSourceIndexPath = indexPath
//        let tile = categories[indexPath.section].tiles[indexPath.row]
//        let itemProvider = NSItemProvider(object: tile.text as NSString)
//        let dragItem = UIDragItem(itemProvider: itemProvider)
//        dragItem.localObject = tile
//        return [dragItem]
//    }
//
//    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
//        session.localDragSession != nil
//    }
//
//    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath indexPath: IndexPath?) -> UICollectionViewDropProposal {
//        if let from = dragSourceIndexPath, let to = indexPath, from.section == to.section {
//            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
//        } else {
//            return UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
//        }
//    }
//
//    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
//        guard
//            let destinationIndexPath = coordinator.destinationIndexPath,
//            let sourceIndexPath = dragSourceIndexPath,
//            let item = coordinator.items.first,
//            let tile = item.dragItem.localObject as? TileM
//        else {
//            return
//        }
//        // Reordering within section
//        let fromCategoryID = categories[sourceIndexPath.section].id
//        let toCategoryID = categories[destinationIndexPath.section].id
//
//        onMoveTile(tile, fromCategoryID, toCategoryID)
//        dragSourceIndexPath = nil
//    }
//}
//#endif
