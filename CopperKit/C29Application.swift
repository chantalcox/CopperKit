//
//  C29Application
//  Copper
//
//  Created by Doug Williams on 3/7/16.
//  Copyright © 2016 Copper Technologies, Inc. All rights reserved.
//

import Foundation

// TODO here for testing and debugging ... this should probably be removed in production
public let CopperKitHelloWorldAppId = "56FC63513259B250EC174C72B35697EB7C38B7B0"

internal let C29ApplicationLinkReceivedNotification = "C29ApplicationLinkReceivedNotification"
public typealias C29ApplicationUserInfoCompletionHandler = (userInfo: C29UserInfo?, error: NSError?)->()

@available(iOS 9.0, *)
public class C29Application: NSObject {
    
    // Our singleton
    public static let sharedInstance = C29Application()
    
    public enum TrackingEvent: String {
        case LoginStarted = "1. CULoginViewController - Login Started"
        case LoginPageLoadComplete = "2. CULoginViewController - Login Page Load Complete"
        case LoginRedirect = "3. CULoginViewController - Login Redirect"
        case LoginComplete = "4. CULoginViewController - Login Complete"
    }
    
    private let CopperKitApplicationType = "copperkit9"
    private static let OpenHostName = "login" // expected: cu1234://login?
    private var trackableParameters: [String:AnyObject] {
        get {
            return ["applicationId":(self._applicationId ?? "null")]
        }
    }
    private var _applicationId: String?
    private var coordinator: C29Coordinator? {
        didSet {
            self.mixpanel.identify(coordinator?.sessionId)
        }
    }
    private var mixpanel = Mixpanel(token: MixPanelToken)
    
    // Instance variables specific to a single request
    // TODO we may want to break these into their own struct if this gets more complicated
    private var c29ViewController: C29ViewController?
    private var completion: C29ApplicationUserInfoCompletionHandler?

    private var id: String? {
        get {
            return _applicationId
        }
    }
    
    public var scopes: [C29Scope] = C29Scope.DefaultScopes // defaults
    
    public func configure(withApplicationId applicationId:String) {
        C29Log(.Debug, "C29Application setting application id to \(applicationId)")
        _applicationId = applicationId
        coordinator = C29Coordinator(application: self)
    }

    
    public var baseURL: String = "https://open.withcopper.com"
    
    public var debug: Bool {
        didSet {
            if debug {
                if C29LoggerLevel.rawValue > C29LogLevel.Debug.rawValue {
                    C29LoggerLevel = .Debug
                }
            } else {
                if C29LoggerLevel.rawValue < C29LogLevel.Info.rawValue {
                    C29LoggerLevel = .Info
                }
            }
        }
    }
    
    enum QueryItems: String {
        case ClientId = "client_id"
        case Scope = "scope"
        case ApplicationType = "application_type"
    }
    
    override init() {
        self.debug = false
    }
    
    public func open(withViewController viewController: UIViewController, completion: C29ApplicationUserInfoCompletionHandler) {
        
        C29Log(.Debug, "C29Application open with applicationId \(_applicationId ?? "null") and scopes \(C29Scope.getCommaDelinatedString(fromScopes: scopes))")
        
        guard guaranteeConfigured() else {
            C29Log(.Error, Error.ApplicationIdNotSet.reason)
            completion(userInfo: nil, error: Error.ApplicationIdNotSet.nserror)
            return
        }
        
        // 1. check and see if we already have these records locally
        if let userInfo = coordinator?.userInfo,
            let records = userInfo.getRecords(forScopes: scopes) {
            C29Log(.Debug, "C29Application open() All \(records.count) requested records locally available.")
            completion(userInfo: userInfo, error: nil)
            return
        }
        
        // We don't have local copies of the records, so let's make sure we're configured correctly.
        guard let u =  NSURL(string: "\(baseURL)/\(CopperNetworkAPI.Path.OauthDialog.rawValue)") else {
            C29Log(.Error, "C29Application baseURL is invalid '\(baseURL)/\(CopperNetworkAPI.Path.OauthDialog.rawValue)'")
            completion(userInfo: nil, error: Error.InvalidConfiguration.nserror)
            return
        }
        
        // let's make the call
        let urlComponents = NSURLComponents(URL: u, resolvingAgainstBaseURL: true)
        let queryClientId = NSURLQueryItem(name: QueryItems.ClientId.rawValue, value: self._applicationId)
        let queryApplicationType = NSURLQueryItem(name: QueryItems.ApplicationType.rawValue, value: CopperKitApplicationType)
        let queryScope = NSURLQueryItem(name: QueryItems.Scope.rawValue, value: C29Scope.getCommaDelinatedString(fromScopes: scopes))
        urlComponents?.queryItems = [queryClientId, queryApplicationType, queryScope]
        let url = urlComponents?.URL!
        
        // 3. Store our request related variables
        self.completion = completion
        
        // 4. Display our view controller
        c29ViewController = C29ViewController(URL: url!)
        c29ViewController!.c29delegate = self
        c29ViewController!.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
        viewController.presentViewController(c29ViewController!, animated: true, completion: {
            // no op
        })
    }
    
    public func closeSession() {
        coordinator = C29Coordinator(application: self)
    }
    
    public func getPermittedScopes() -> [C29Scope]? {
        guard let scopes = coordinator?.userInfo?.getPermittedScopes() else {
            return nil
        }
        return scopes
    }
    
    public func openURL(url: NSURL, sourceApplication: String?) -> Bool {
        C29Log(.Debug, "Beginning attemptLogin for url '\(url)' and sourceApplication '\(sourceApplication ?? "null")'")
        // ensure we're coming from the right URL
        guard let customURL = getCustomURLScheme() else {
            C29Log(.Error, Error.ApplicationIdNotSet.reason)
            return false
        }
        guard url.scheme.uppercaseString == customURL.uppercaseString else {
            C29Log(.Debug, "Url Scheme '\(url.scheme)' does not match the expected value of '\(customURL)')")
            return false
        }
        // we expect responses from SafariViewService only
        guard let sa = sourceApplication where sa == "com.apple.SafariViewService" else {
            C29Log(.Debug, "sourceApplication '\(sourceApplication)' does not match the expected value of 'com.apple.SafariViewService'")
            return false
        }
        // ensure we are coming from the right host
        guard url.host == C29Application.OpenHostName else {
            C29Log(.Debug, "Url Host '\(url.host)' does not match the expected value of '\(C29Application.OpenHostName)')")
            return false
        }
        // ok -- dispatch the login if we get past the guantlet
        NSNotificationCenter.defaultCenter().postNotificationName(C29ApplicationLinkReceivedNotification, object: url)
        return true
    }
    
    private func getCustomURLScheme() -> String? {
        // our custom URL scheme is the concatination of "cu" + "application ID"
        guard let id = self.id else {
            return nil
        }
        return "cu\(id)"
    }
    
    private func guaranteeConfigured() -> Bool {
        guard let _ = _applicationId else {
            return false
        }
        return true
    }
}

@available(iOS 9.0, *)
extension C29Application: C29ViewControllerDelegate {
    internal func openURLReceived(notification: NSNotification, withC29ViewController viewController: C29ViewController) {
        C29Log(.Debug, "C29Application openURLReceived with notification \(notification)")
        self.trackEvent(.LoginRedirect)
        // we parse the returned URL from the notification
        guard let url = notification.object as? NSURL else {
            finish(nil, error: Error.LoginError.nserror)
            return
        }
        C29Log(.Debug, "openURLReceived with URL: \(url)")
        coordinator?.getUserInfo(withResponseURL: url, callback: { userInfo, error in
            self.trackEvent(.LoginComplete)
            self.finish(userInfo, error: error)
        })
    }
    internal func trackEvent(event: C29Application.TrackingEvent) {
        self.mixpanel.track(event.rawValue, parameters: self.trackableParameters)
    }
    internal func finish(userInfo: C29UserInfo?, error: NSError?) {
        self.c29ViewController?.dismissViewControllerAnimated(true, completion: {
            self.completion?(userInfo: userInfo, error: error)
            self.c29ViewController = nil
            self.completion = nil
        })
    }
}


@available(iOS 9.0, *)
extension C29Application {
    public enum Error: Int {
        case LoginError = 1
        case ApplicationIdNotSet = 2
        case InvalidConfiguration = 3

        
        public var reason: String {
            switch self {
            case .LoginError:
                return "There was a problem logging in."
            case .ApplicationIdNotSet:
                return "Copper Application Id is not set. You must call C29Application.configure(withApplicationId: \"<appId>\"), where <appId> is your application's ID found on Copperworks @ withcopper.com/apps"
            case .InvalidConfiguration:
                return "The C29Application class is not configured properly. Set debug=true for full error reports."
            }
        }
        public var description: String {
            switch self {
            case .LoginError:
                return "There is not url as expected."
            default:
                return self.reason
            }
        }
        var nserror: NSError {
            return NSError(domain: self.domain, code: self.rawValue, userInfo: [NSLocalizedFailureReasonErrorKey: self.reason])
        }
        var domain: String {
            return "\(NSBundle.mainBundle().bundleIdentifier!).C29Application"
        }
    }
}