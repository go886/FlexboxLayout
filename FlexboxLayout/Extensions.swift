//
//  Extensions.swift
//  FlexboxLayout
//
//  Created by Alex Usbergo on 30/03/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//


#if os(iOS)
    
    import UIKit
        
    extension FlexboxView where Self: ViewType {
        
        /// Called before the configure block is called
        /// - Note: Subclasses to implement this method if required
        internal func preRender() {
            
            // The volatile component view will recreate is subviews at every render call
            // Therefore the old subviews have to be removed
            if let volatileComponentView = self as? VolatileComponentView {
                volatileComponentView.__preRender()
            }
        }
        
        /// Called before the layout is performed
        /// - Note: Subclasses to implement this method if required
        internal func postRender() {
            
            // content-size calculation for the scrollview should be applied after the layout
            if let scrollView = self as? UIScrollView {
                
                //failsafe
                if let _ = self as? UITableView { return }
                if let _ = self as? UICollectionView { return }
                
                scrollView.__postRender()
            }
        }
    }

    extension UIScrollView {
        
        /// Calculates the new 'contentSize'
        func __postRender() {
            
            var x: CGFloat = 0
            var y: CGFloat = 0
            
            for subview in self.subviews {
                x = CGRectGetMaxX(subview.frame) > x ? CGRectGetMaxX(subview.frame) : x
                y = CGRectGetMaxY(subview.frame) > y ? CGRectGetMaxY(subview.frame) : y
            }
            
            self.contentSize = CGSize(width: x, height: y)
            self.scrollEnabled = true
        }
    }
            
    private var __internalStoreHandle: UInt8 = 0
    private var __cacheHandle: UInt8 = 0

    extension UITableView {
        
        /// Refreshes the component at the given index path
        public func refreshComponentAtIndexPath(indexPath: NSIndexPath) {
            self.beginUpdates()
            self.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            self.endUpdates()
        }
        
        /// Internal store for this view
        private var prototypes: [String: ComponentView] {
            get {
                guard let store = objc_getAssociatedObject(self, &__internalStoreHandle) as? [String: ComponentView] else {
                    
                    //lazily creates the node
                    let store = [String: ComponentView]()
                    objc_setAssociatedObject(self, &__internalStoreHandle, store, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                    return store
                }
                return store
            }
            set {
                objc_setAssociatedObject(self, &__internalStoreHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                
            }
        }
        
        /// Register the component for the given identifier
        public func registerPrototype(reuseIdentifier: String, component: ComponentView) {
            self.prototypes[reuseIdentifier] = component
        }
        
        /// Rerturns the height for the component with the given reused identifier
        public func heightForCellWithState(reuseIdentifier: String, state: ComponentStateType) -> CGFloat {
            
            guard let prototype = prototypes[reuseIdentifier] else {
                return 0
            }
            
            prototype.state = state
            prototype.render(CGSize(width: self.bounds.size.width, height: CGFloat(Undefined)))
            
            var size = prototype.bounds.size
            size.height += prototype.frame.origin.y + CGFloat(prototype.style.margin.top) + CGFloat(prototype.style.margin.bottom)
            let height = size.height
            
            return height
        }
    
    }


#endif