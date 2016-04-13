//
//  CUViewController
//  Copper
//
//  Created by Doug Williams on 3/2/16.
//  Copyright © 2016 Copper Technologies, Inc. All rights reserved.
//

import UIKit
import SafariServices

@available(iOS 9.0, *)
internal protocol C29ViewControllerDelegate: class {
    func openURLReceived(notification: NSNotification, withC29ViewController: C29ViewController)
    func trackEvent(event: C29Application.TrackingEvent)
    func finish(userInfo: C29UserInfo?, error: NSError?)
}

@available(iOS 9.0, *)
public class C29ViewController: SFSafariViewController, SFSafariViewControllerDelegate {

    var c29delegate: C29ViewControllerDelegate?

    override public func loadView() {
        self.c29delegate?.trackEvent(.LoginStarted)
        if c29delegate == nil {
            // not sure if this is set before or after so leavig this here to check
            C29Log(.Warning, "MOVE Login.Started to viewDidLoad")
        }
        super.loadView()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: #selector(C29ViewController.loginLinkReceived(_:)),
            name: C29ApplicationLinkReceivedNotification,
            object: nil)
    }
    
    public func safariViewController(controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        C29Log(.Debug, "safariViewController didCompleteInitialLoadSuccessfully? \(didLoadSuccessfully)")
        self.c29delegate?.trackEvent(.LoginPageLoadComplete)
    }
    
    public func safariViewControllerDidFinish(controller: SFSafariViewController) {
        c29delegate?.finish(nil, error: nil)
    }
    
    func loginLinkReceived(notification: NSNotification) {
        c29delegate?.openURLReceived(notification, withC29ViewController: self)
    }
    
}