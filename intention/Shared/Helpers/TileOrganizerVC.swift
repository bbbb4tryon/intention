//
//  TileOrganizerVC.swift
//  intention
//
//  Created by Benjamin Tryon on 8/5/25.
//

import UIKit
import Foundation


class TileOrganizerVC: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    private var categories: [CategoriesModel] = []
    var onMoveTile: (TileM, UUID, UUID) -> Void = { _,_,_ in }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.reorderingCadence = .immediate
        collectionView.dragInteractionEnabled = true
    }

    func update(categories: [CategoriesModel]) {
        self.categories = categories
        collectionView.reloadData()
    }

    // MARK: - UICollectionViewDataSource methods

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return categories.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories[section].tiles.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let tile = categories[indexPath.section].tiles[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        var content = UIListContentConfiguration.cell()
        content.text = tile.text
        cell.contentConfiguration = content
        return cell
    }

    // MARK: - UICollectionViewDragDelegate / DropDelegate to be added here
}
