//
//  ZoomAnimator.swift
//  PhotoZoomAnimator
//
//  Created by Joshua on 8/6/19.
//  Copyright © 2019 JHC Dev. All rights reserved.
//

import UIKit


public protocol ZoomAnimatorDelegate: class {
    // these two methods are run just before and just after the animation
    // they are here as helper functions and do not need to do anything
    func transitionWillStartWith(zoomAnimator: ZoomAnimator)
    func transitionDidEndWith(zoomAnimator: ZoomAnimator)
    
    // return the image view that is being zoomed from or to
    func referenceImageView(for zoomAnimator: ZoomAnimator) -> UIImageView?
    
    // the frame of the image view in the transitioning view
    func referenceImageViewFrameInTransitioningView(for zoomAnimator: ZoomAnimator) -> CGRect?
}


public class ZoomAnimator: NSObject {

    weak var fromDelegate: ZoomAnimatorDelegate?
    weak var toDelegate: ZoomAnimatorDelegate?
    
    var isPresenting = true
    
    var transitionImageView: UIImageView?
    
    
    fileprivate func animateZoomInTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        // container view of the animation
        let containerView = transitionContext.containerView
        
        // get view controllers and image views
        guard
            let fromVC = transitionContext.viewController(forKey: .from),
            let fromReferenceImageView = self.fromDelegate?.referenceImageView(for: self),
            let fromReferenceImageViewFrame = self.fromDelegate?.referenceImageViewFrameInTransitioningView(for: self),
            let toVC = transitionContext.viewController(forKey: .to),
            let toView = transitionContext.view(forKey: .to)
            else {
                return
        }
        
        // these are optional functions in the delegates that get called before the animation runs
        self.fromDelegate?.transitionWillStartWith(zoomAnimator: self)
        self.toDelegate?.transitionWillStartWith(zoomAnimator: self)
        
        // STEP 1 //
        // start the destination as transparent and hidden
        toVC.view.alpha = 0.0
        containerView.addSubview(toVC.view)
        
        // STEP 2
        let referenceImage = fromReferenceImageView.image!
        if self.transitionImageView == nil {
            let transitionImageView = UIImageView(image: referenceImage)
            transitionImageView.contentMode = .scaleAspectFill
            transitionImageView.clipsToBounds = true
            transitionImageView.frame = fromReferenceImageViewFrame
            
            self.transitionImageView = transitionImageView
            containerView.addSubview(transitionImageView)
        }
        
        // STEP 3
        // hide the source image view
        fromReferenceImageView.isHidden = true
        
        
        // STEP 4 //
        let finalTransitionSize = calculateZoomInImageFrame(image: referenceImage, forView: toView)
        
        // STEP 5 //
        // animation
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: [.transitionCrossDissolve, .curveEaseOut],
            animations: {
                toVC.view.alpha = 1.0
                self.transitionImageView?.frame = finalTransitionSize  // animate size of image view
                fromVC.tabBarController?.tabBar.alpha = 0              // animate transparency of tab bar out
        },
            completion: { _ in
                // remove transition image view and show both view controllers, again
                self.transitionImageView?.removeFromSuperview()
                self.transitionImageView = nil
                
                fromReferenceImageView.isHidden = false
                
                // end the transition (unless was cancelled)
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                
                // these are optional functions in the delegates that get called after the animation runs
                self.toDelegate?.transitionDidEndWith(zoomAnimator: self)
                self.fromDelegate?.transitionDidEndWith(zoomAnimator: self)
        })
        
    }
    
    
    fileprivate func animateZoomOutTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        // container view of the animation
        let containerView = transitionContext.containerView
        
        // get view controllers and image views
        guard
            let toVC = transitionContext.viewController(forKey: .to),
            let fromVC = transitionContext.viewController(forKey: .from),
            let fromReferenceImageView = self.fromDelegate?.referenceImageView(for: self),
            let toReferenceImageView = self.toDelegate?.referenceImageView(for: self),
            let fromReferenceImageViewFrame = self.fromDelegate?.referenceImageViewFrameInTransitioningView(for: self),
            let toReferenceImageViewFrame = self.toDelegate?.referenceImageViewFrameInTransitioningView(for: self)
            else {
                print("unable to collect required assets - animation failed")
                return
        }
        
        // these are optional functions in the delegates that get called before the animation runs
        self.fromDelegate?.transitionWillStartWith(zoomAnimator: self)
        self.toDelegate?.transitionWillStartWith(zoomAnimator: self)
        
        // STEP 1 //
        // hide the source image view
        toReferenceImageView.isHidden = true
        
        // STEP 2 //
        let referenceImage = fromReferenceImageView.image!
        if self.transitionImageView == nil {
            let transitionImageView = UIImageView(image: referenceImage)
            transitionImageView.contentMode = .scaleAspectFill
            transitionImageView.clipsToBounds = true
            transitionImageView.frame = fromReferenceImageViewFrame
            self.transitionImageView = transitionImageView
        }
        
        // STEP 3 //
        containerView.addSubview(toVC.view)
        containerView.addSubview(fromVC.view)
        containerView.addSubview(transitionImageView!)
        fromReferenceImageView.isHidden = true
        
        // STEP 4 //
        let finalTransitionSize = toReferenceImageViewFrame
        
        // STEP 5 //
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: [.curveEaseOut],
            animations: {
                fromVC.view.alpha = 0                                  // animate transparency of source view out
                self.transitionImageView?.frame = finalTransitionSize  // animate size of image view
                toVC.tabBarController?.tabBar.alpha = 1                // animate transparency of tab bar in
        },
            completion: { _ in
                self.transitionImageView?.removeFromSuperview()
                self.transitionImageView = nil
                
                toReferenceImageView.isHidden = false
                fromReferenceImageView.isHidden = false
                
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                
                // these are optional functions in the delegates that get called after the animation runs
                self.toDelegate?.transitionDidEndWith(zoomAnimator: self)
                self.fromDelegate?.transitionDidEndWith(zoomAnimator: self)
        })
    }
    
    
    
    
    
    
    public func calculateZoomInImageFrame(image: UIImage, forView view: UIView) -> CGRect {
        
        let viewRatio = view.frame.size.width / view.frame.size.height
        let imageRatio = image.size.width / image.size.height
        let touchesSides = (imageRatio > viewRatio)
        
        if touchesSides {
            let height = view.frame.width / imageRatio
            let yPoint = view.frame.minY + (view.frame.height - height) / 2
            return CGRect(x: 0, y: yPoint, width: view.frame.width, height: height)
        } else {
            let width = view.frame.height * imageRatio
            let xPoint = view.frame.minX + (view.frame.width - width) / 2
            return CGRect(x: xPoint, y: 0, width: width, height: view.frame.height)
        }
    }
    
}


extension ZoomAnimator: UIViewControllerAnimatedTransitioning {
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return isPresenting ? 0.5 : 0.25
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isPresenting {
            animateZoomInTransition(using: transitionContext)
        } else {
            animateZoomOutTransition(using: transitionContext)
        }
    }
}
