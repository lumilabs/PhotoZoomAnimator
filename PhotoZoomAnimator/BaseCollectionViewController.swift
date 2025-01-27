//
//  BaseCollectionViewController.swift
//  PhotoZoomAnimator
//
//  Created by Joshua on 8/6/19.
//  Copyright © 2019 JHC Dev. All rights reserved.
//

import UIKit

private let reuseIdentifier = "baseCollectionCell"

public class BaseCollectionViewController: UICollectionViewController {
    
    
    var imagesNames: [String]
    var images = [UIImage]()
    
    let numberOfImagesPerRow: CGFloat = 4.0
    let spacingBetweenCells: CGFloat = 0.1
    
    var currentIndex = 0

    public init(imagesNames: [String]) {
        self.imagesNames = imagesNames
        let layout = UICollectionViewFlowLayout()
        super.init(collectionViewLayout: layout)
    }

    required init?(coder: NSCoder) {
        self.imagesNames = [] // Default to an empty array
        super.init(coder: coder)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(BaseCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        // self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
        
        title = "Image Collection"
        collectionView.alwaysBounceVertical = true
        collectionView.delegate = self
        
        for imageName in imagesNames {
            if let image = UIImage(named: imageName) { images.append(image) }
            else {
                print("Image not found: \(imageName)")
            }    
        }
    }

    // MARK: UICollectionViewDataSource

    override public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    override public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BaseCollectionViewCell
        
        cell.imageView.image = images[indexPath.item]
        cell.imageView.contentMode = .scaleAspectFill
    
        return cell
    }
    
    override public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        currentIndex = indexPath.item
    }

}


// sizing of collection view cells
extension BaseCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.frame.width / numberOfImagesPerRow - (spacingBetweenCells * numberOfImagesPerRow)
        return CGSize(width: width, height: width)
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return spacingBetweenCells
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return spacingBetweenCells
    }
}


// segues
extension BaseCollectionViewController {
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? PagingCollectionViewController {
            // set stored properties of the destination `PagingCollectionViewController`
            destinationViewController.images = images
            if let indexPath = collectionView.indexPathsForSelectedItems?.first {
                destinationViewController.startingIndex = indexPath.item
            }
            
            // set the navigation controller delegate as the `ZoomTransitionController
            // of the destination `PagingCollectionViewController`
            self.navigationController?.delegate = destinationViewController.transitionController
            
            // PagingCollectionViewControllerDelegate
            // will get updated about changes in index from the paging view controller
            destinationViewController.containerDelegate = self
            
            // set source and destination delegates for the transition controller
            destinationViewController.transitionController.fromDelegate = self
            destinationViewController.transitionController.toDelegate = destinationViewController
        }
    }
}


// ZoomAnimatorDelegate
extension BaseCollectionViewController: ZoomAnimatorDelegate {
    func transitionWillStartWith(zoomAnimator: ZoomAnimator) {
        // add code here to be run just before the transition animation
    }
    
    func transitionDidEndWith(zoomAnimator: ZoomAnimator) {
        // add code here to be run just after the transition animation
    }
    
    func getCell(for zoomAnimator: ZoomAnimator) -> BaseCollectionViewCell? {
        let indexPath = zoomAnimator.isPresenting ? collectionView.indexPathsForSelectedItems?.first : IndexPath(item: currentIndex, section: 0)
        
        if let cell = collectionView.cellForItem(at: indexPath!) as? BaseCollectionViewCell {
            return cell
        } else {
            return nil
        }
    }
    
    func referenceImageView(for zoomAnimator: ZoomAnimator) -> UIImageView? {
        if let cell = getCell(for: zoomAnimator) { return cell.imageView }
        return nil
    }
    
    func referenceImageViewFrameInTransitioningView(for zoomAnimator: ZoomAnimator) -> CGRect? {
        if let cell = getCell(for: zoomAnimator) {
            return cell.contentView.convert(cell.imageView.frame, to: view)
        }
        return nil
    }
}


extension BaseCollectionViewController: PagingCollectionViewControllerDelegate {
    func containerViewController(_ containerViewController: PagingCollectionViewController, indexDidChangeTo currentIndex: Int) {
        self.currentIndex = currentIndex
        collectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: .centeredVertically, animated: false)
    }
}
