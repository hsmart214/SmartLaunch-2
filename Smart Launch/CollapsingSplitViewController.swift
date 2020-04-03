//
//  CollapsingSplitViewViewController.swift
//  SmartLauch
//
//  Created by J. Howard Smart on 10/13/19.
//  Copyright © 2019 J. HOWARD SMART. All rights reserved.
//
//  The reason I now have to subclass UISplitViewController here is that when presented in
//  a horizontally compact environment the master view controller is no longer loaded.
//  I am sure this speeds up presentation of the detail view (when that is what is intended)
//  but now you cannot set the UISplitViewDelegate in viewDidLoad() on the master, and you
//  cannot set it in Xcode in the storyboard, even though there is a control for that.

//  So now I set it as its OWN delegate since it will be loaded first, even if the master is
//  not. The master cannot serve as delegate unless it is always in the stack, which is no
//  longer true.

import UIKit

extension UIViewController {
    var contentViewController: UIViewController {
        get{
            if let nav = self as? UINavigationController{
                return nav.visibleViewController ?? self
            }else{
                return self
            }
        }
    }
}

class CollapsingSplitViewViewController: UISplitViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.preferredDisplayMode = .allVisible
    }
    // MARK: - UISplitViewControllerDelegate
    
    // we "fake out" iOS here - thanks to Paul Hegarty at Stanford
    // this delegate method of UISplitViewController
    // allows the delegate to do the work of collapsing the primary view controller (the master)
    // on top of the secondary view controller (the detail)
    // this happens whenever the split view wants to show the detail
    // but the master is on screen in a spot that would be covered up by the detail
    // the return value of this delegate method is a Bool
    // "true" means "yes, Mr. UISplitViewController, I did collapse that for you"
    // "false" means "sorry, Mr. UISplitViewController, I couldn't collapse so you do it for me"
    // if our secondary (detail) is a ChapterDetailViewController with a nil detailText
    // then we will return true even though we're not actually going to do anything
    // that's because when detailText is nil, we do NOT want the detail to collapse on top of the master
    
    func splitViewController(
        _ splitViewController: UISplitViewController,
        collapseSecondary secondaryViewController: UIViewController,
        onto primaryViewController: UIViewController
        ) -> Bool {
        if primaryViewController.contentViewController == self.viewControllers.first?.contentViewController {
            if let first = secondaryViewController.contentViewController as? SLFlightProfileViewController{
                first.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
                return true
            }
        }
        secondaryViewController.navigationItem.rightBarButtonItem = splitViewController.displayModeButtonItem
        return false
    }

}
