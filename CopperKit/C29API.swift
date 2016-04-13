//
//  CopperAPI.swift
//  Copper
//
//  Doug Williams on 12/9/14.
//

import Foundation
import SystemConfiguration

typealias DataDictionary = Dictionary<String, AnyObject>

public typealias C29APICallback = ((AnyObject?, NSError?) -> ())

public protocol C29API:class {
    
    var delegate: CopperNetworkAPIDelegate? { get set }
    var dataSource:CopperNetworkAPIDataSource? { get set }
    var URL: String { get set }

    // MARK: User Login and Registration
    func getJWT(userId: String, secret: String, callback: C29APICallback)
    func getUserInfo(callback: C29APICallback)
    
    // MARK: OAuth
    func oauthAuthorize(userId: String, applicationId: String, redirectUri: String, nonce: String, state: String, scope: String, responseMode: String, responseType: String, callback: C29APICallback)
    func getURLforCode(userId: String, code: String, callback: C29APICallback)

    // MARK: Users
    func getUserWithID(userID: String, callback: C29APICallback)
    func saveUserInfoForUserID(userID: String, key: C29User.Key, value: AnyObject, callback: C29APICallback)
    func deleteUserInfoForUserID(userID: String, key: C29User.Key, value: AnyObject, callback: C29APICallback)
    func deleteUserWithUserID(userID: String, secret: String, callback: C29APICallback)
    // verification
    func getVerificationCode(toPhoneNumber: String, secret: String, callback: C29APICallback)
    func postUserVerification(verificationCode: C29VerificationCode, digits: String, callback: C29APICallback)
    // records
    func saveUserRecordsForUserID(userID: String, records: [CopperRecord], callback: C29APICallback)
    func deleteUserRecordsForUserID(userId: String, records: [CopperRecord], callback: C29APICallback)
    func getUserRecordsForUserID(userId: String, since: NSDate?, callback: C29APICallback)
    // devices
    func getUserDevicesForUserID(userId: String, deviceId: String?, callback: C29APICallback)
    func getUserDeviceForUserID(userId: String, deviceId: String, callback: C29APICallback)
    func deleteUserDeviceForUserID(userId: String, deviceId: String, callback: C29APICallback)
    func updateUserDeviceForUserID(userId: String, deviceId: String, params: [String:AnyObject], callback: C29APICallback)

    // MARK: Applications
    func getUserApplicationsForUserID(userId: String, callback: C29APICallback)
    func getUserApplicationForUserID(userId: String, applicationId: String, callback: C29APICallback)
    func deleteUserApplicationForUserID(userId: String, applicationId: String, callback: C29APICallback)

    // MARK: Requests
    func getRequestForUserID(userId: String, requestId: String, callback: C29APICallback)
    func setRequestGrantForUserID(userId: String, request: C29Request, status: C29RequestStatus, records: [CopperRecord], forceRecordUpload: Bool, callback: C29APICallback)
    func setRequestAckForUserID(userID: String, request: C29Request, callback: C29APICallback)

    // MARK: C29CopperworksApplication Records
    func saveUserApplicationRecordsForUserID(userId: String, applicationId: String, records: [CopperRecord], callback: C29APICallback)
    func deleteUserApplicationRecordsForUserID(userId: String, applicationId: String, records: [CopperRecord], callback: C29APICallback)
    
    // MARK: Bytes and Files
    func createBytes(userID: String, fileID: String, file: NSData, callback: C29APICallback)
}


// MARK: Network API Implementation

public protocol CopperNetworkAPIDelegate:class {
    func authTokenForAPI(api: CopperNetworkAPI) -> String?
    func userIdentifierForLoggingErrorsInAPI(api: CopperNetworkAPI) -> AnyObject?
    func networkAPI(api: CopperNetworkAPI, recordAnalyticsEvent event:String, withParameters parameters:[String:AnyObject])
    func networkAPI(api: CopperNetworkAPI, attemptLoginWithCallback callback:(success:Bool, error:NSError?) -> ())
    func beganRequestInNetworkAPI(api: CopperNetworkAPI)
    func endedRequestInNetworkAPI(api: CopperNetworkAPI)
}

public protocol CopperNetworkAPIDataSource:class {
    func recordCacheForNetworkAPI(api:CopperNetworkAPI) -> C29RecordCache
}

public class CopperNetworkAPI: NSObject, C29API {
    public weak var delegate: CopperNetworkAPIDelegate?
    public weak var dataSource:CopperNetworkAPIDataSource?

    var authToken:String? {
        get {
            return delegate?.authTokenForAPI(self)
        }
    }
    
    public var URL: String = "https://api.withcopper.com"
    
    public enum Path: String {
        case OauthAuthorize = "oauth/authorize"
        case OauthUserinfo = "oauth/userinfo"
        case OauthDialog = "oauth/dialog"
        case Users = "users"
        case Verify = "verify"
        case UsersLogin = "users/login"
        case UsersGrant = "grant"
        case UsersRequests = "requests"
        case UsersRequestsAck = "ack"
        case UsersRecords = "records"
        case UsersApplications = "applications"
        case UserDevices = "devices"
        case Go = "go"
        case Bytes = "bytes"
    }
    
    enum APIMethod {
        case GET_JWT
        case GET_USERINFO
        case DIALOG_VERIFY
        case DIALOG_VERIFY_CODE
        case OAUTH_AUTHORIZE
        case GET_OAUTH_URL_FOR_CODE
        case GET_USER
        case CREATE_USER
        case DELETE_USER
        case SAVE_USER_INFO
        case DELETE_USER_INFO
        case SAVE_USER_RECORDS
        case GET_USER_RECORDS
        case DELETE_USER_RECORDS
        case SAVE_USER_APPLICATION_RECORDS
        case DELETE_USER_APPLICATION_RECORDS
        case GET_USER_DEVICES
        case GET_USER_DEVICE
        case DELETE_USER_DEVICE
        case UPDATE_USER_DEVICE
        case GET_USER_APPLICATIONS
        case GET_USER_APPLICATION
        case DELETE_USER_APPLICATION
        case GET_REQUEST
        case SET_REQUEST_GRANT
        case SET_REQUEST_ACKNOWLEDGED
        case CREATE_BYTES
    }
    
    enum HTTPMethod: String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
    }
    
    // Instance Variables
    var session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())

    // Our workhorse method, though you shouldn't need to call this directly.
    private func makeHTTPRequest(method: APIMethod, callback: C29APICallback, url: NSURL, httpMethod: CopperNetworkAPI.HTTPMethod, params: [String: AnyObject]! = nil, authentication: Bool = true, retries: Int = 1) {
        C29Log(.Debug, "CopperAPI >> HTTP \(httpMethod.rawValue) \(url)")
        
        guard Reachability.isConnectedToNetwork() else {
            dispatch_async(dispatch_get_main_queue()) {
                callback(nil, CopperAPIError.Disconnected.nserror)
            }
            return ()
        }
        
        // Request setup
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = httpMethod.rawValue
        
        if authentication {
            // If we have our authToken, proceed
            if let token = self.authToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                // If there are authentication retries left, then let's use them
            } else if retries > 0 {
                attemptLoginThenRetryHTTPRequest(method, callback: callback, url: url, httpMethod: httpMethod, params: params, authentication: authentication, retries: retries)
                return
                // No retries left and we're still unauthed
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    C29LogWithRemote(.Error, error: CopperAPIError.Auth.nserror, infoDict: params)
                    callback(nil, CopperAPIError.Auth.nserror)
                }
            }
        }

        if params != nil {
            do {
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                let json = try NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions())
                request.HTTPBody = json
                // Uncomment for more debugging output
                //if let json = NSString(data: json, encoding: NSUTF8StringEncoding) {
                //    CopperLog(.Debug, "CopperAPI request body \(json)")
                //}
            } catch {
                let error = CopperAPIError.JsonInvalid.nserror
                C29LogWithRemote(.Error, error: error, infoDict: params)
                dispatch_async(dispatch_get_main_queue()) {
                    callback(nil, error)
                }
            }
        }
        
        // Make the call
        delegate?.beganRequestInNetworkAPI(self)
        let task = session.dataTaskWithRequest(request) { data, response, error in
            self.delegate?.endedRequestInNetworkAPI(self)
            // attempt to serialize the data from json
            var dataDict = NSDictionary?()
            if let data = data {
                do {
                    dataDict = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as? NSDictionary
                } catch {
                    // no op
                }
            }
            
            // exit early with any error
            guard error == nil else {
                dispatch_async(dispatch_get_main_queue()) {
                    callback(nil, self.handleError(dataDict, statusCode: error!.code))
                }
                return ()
            }
            
            // otherwise attempt to parse our request
            if let httpResponse = response as? NSHTTPURLResponse {
                var result:AnyObject?
                var error:NSError?
                var shouldLogAPIError = false
                switch(httpResponse.statusCode, method) {
                    //Success handling
                case (200, APIMethod.GET_JWT):
                    result = self.handleJWTResponse(dataDict)
                case (200, APIMethod.GET_USERINFO):
                    result = dataDict
                case (200, APIMethod.DIALOG_VERIFY):
                    result = C29VerificationCode.fromDictionary(dataDict!)
                case (200, APIMethod.DIALOG_VERIFY_CODE), (201, APIMethod.DIALOG_VERIFY_CODE):
                    result = C29VerificationResult.fromDictionary(dataDict!)
                case (200, APIMethod.OAUTH_AUTHORIZE):
                    let res = C29Request.fromDictionary(dataDict!)
                    result = res.request
                    error = res.error
                case (200, APIMethod.GET_OAUTH_URL_FOR_CODE):
                    result = C29QRCode.fromDictionary(dataDict!)
                case (200, APIMethod.GET_USER):
                    result = C29User.fromDictionary(dataDict!)
                case (200, APIMethod.CREATE_USER):
                    result = self.handleCreateUserResponse(dataDict)
                case (200, APIMethod.DELETE_USER):
                    result = true
                case (200, APIMethod.SAVE_USER_INFO):
                    result = self.handleEditUser(dataDict)
                case (200, APIMethod.DELETE_USER_INFO):
                    result = self.handleEditUser(dataDict)
                case (200, APIMethod.GET_USER_APPLICATIONS):
                    result = dataDict
                case (200, APIMethod.GET_USER_APPLICATION):
                    result = C29CopperworksApplication.fromDictionary(dataDict!)
                case (200, APIMethod.DELETE_USER_APPLICATION):
                    result = true
                case (200, APIMethod.SAVE_USER_RECORDS):
                    result = true
                case (200, APIMethod.GET_USER_RECORDS):
                    result = dataDict!
                case (200, APIMethod.DELETE_USER_RECORDS):
                    result = true
                case (200, APIMethod.SAVE_USER_APPLICATION_RECORDS):
                    result = true
                case (200, APIMethod.DELETE_USER_APPLICATION_RECORDS):
                    result = true
                case (200, APIMethod.GET_USER_DEVICES):
                    result = dataDict!
                case (200, APIMethod.GET_USER_DEVICE):
                    result = dataDict!
                case (200, APIMethod.DELETE_USER_DEVICE):
                    result = true
                case (200, APIMethod.UPDATE_USER_DEVICE):
                    result = dataDict!
                case (200, APIMethod.SET_REQUEST_GRANT):
                    result = C29RequestGrant.fromDictionary(dataDict!)
                case (200, APIMethod.SET_REQUEST_ACKNOWLEDGED):
                    result = true
                case (200, APIMethod.GET_REQUEST):
                    let res = C29Request.fromDictionary(dataDict!)
                    result = res.request
                    error = res.error
                case (200, APIMethod.CREATE_BYTES), (201, APIMethod.CREATE_BYTES):
                    result = C29Bytes.fromDictionary(dataDict!)
                    
                // TODO add more statusCode cases, as required
                    
                // Verification errors
                case (401, APIMethod.DIALOG_VERIFY_CODE):
                    error = CopperAPIError.DialogCodeInvalid.nserror
                case (419, APIMethod.DIALOG_VERIFY_CODE):
                    error = CopperAPIError.DialogCodeExpired.nserror
                case (429, APIMethod.DIALOG_VERIFY_CODE):
                    error = CopperAPIError.DialogCodeLocked.nserror
                // General catch all, unknown and undexpected
                case (400, _):
                    shouldLogAPIError = true
                    error = self.handleError(dataDict, statusCode: httpResponse.statusCode)
                case (401, _):
                    if retries > 0 && method != .GET_JWT {
                        self.attemptLoginThenRetryHTTPRequest(method, callback: callback, url: url, httpMethod: httpMethod, params: params, authentication: authentication, retries: retries)
                        return
                    } else {
                        shouldLogAPIError = true
                        error = CopperAPIError.Auth.nserror
                    }
                default:
                    shouldLogAPIError = true
                    error = self.handleError(dataDict, statusCode: httpResponse.statusCode)
                }
                dispatch_async(dispatch_get_main_queue()) {
                    callback(result, error)
                    if shouldLogAPIError {
                        self.logAPIError(httpResponse, httpMethodRaw: httpMethod.rawValue, url: url, error: error, params: params, dataDict: dataDict, authentication: authentication, authToken: self.authToken, delegate: self.delegate, api: self)
                    }
                }
            }
        }
        task.resume()
    }
    
    private func attemptLoginThenRetryHTTPRequest(method: APIMethod, callback: C29APICallback, url: NSURL, httpMethod: CopperNetworkAPI.HTTPMethod, params: [String: AnyObject]! = nil, authentication: Bool = true, retries: Int = 1) {
        C29Log(.Debug, "CopperAPI >> attemping C29User.login with \(retries) retries")
        let tries = retries - 1
        delegate!.networkAPI(self, attemptLoginWithCallback: { (success, error) -> () in
            if success {
                self.makeHTTPRequest(method, callback: callback, url: url, httpMethod: httpMethod, params: params, authentication: authentication, retries: tries)
            } else {
                C29Log(.Debug, "CopperAPI >> error retrieving authToken")
                dispatch_async(dispatch_get_main_queue()) {
                    callback(nil, error)
                }
            }
        })
    }
    // MARK: - API Methods

    // LOGIN and REGISTRATION
    public func getJWT(userId: String, secret: String, callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.UsersLogin.rawValue)")!
        let params: [String:String] = ["user_id" : userId,
            "secret" : secret]
        makeHTTPRequest(APIMethod.GET_JWT, callback: callback, url: url, httpMethod: HTTPMethod.POST, params: params, authentication: false)
    }
    func handleJWTResponse(data: NSDictionary?) -> String? {
        if let token = data?["token"] {
            return token as? String
        }
        return String?()
    }
    public func getUserInfo(callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.OauthUserinfo.rawValue)")!
        makeHTTPRequest(APIMethod.GET_USERINFO, callback: callback, url: url, httpMethod: HTTPMethod.GET, authentication: true)
    }

    
    // OAUTH
    public func oauthAuthorize(userId: String, applicationId: String, redirectUri: String, nonce: String, state: String, scope: String, responseMode: String, responseType: String, callback: C29APICallback) {
        var url = "\(URL)/\(Path.OauthAuthorize.rawValue)"
        url += "?\(C29OAuth.Key.UserId.rawValue)=\(userId)"
        url += "&\(C29OAuth.Key.ApplicationId.rawValue)=\(applicationId)"
        url += "&\(C29OAuth.Key.RedirectUri.rawValue)=\(redirectUri)"
        url += "&\(C29OAuth.Key.Nonce.rawValue)=\(nonce)"
        url += "&\(C29OAuth.Key.State.rawValue)=\(state)"
        url += "&\(C29OAuth.Key.Scope.rawValue)=\(scope)"
        url += "&\(C29OAuth.Key.ResponseMode.rawValue)=\(responseMode)"
        url += "&\(C29OAuth.Key.ResponseType.rawValue)=\(responseType)"
        let encoded = url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        let _url = NSURL(string: encoded)!
        makeHTTPRequest(APIMethod.OAUTH_AUTHORIZE, callback: callback, url: _url, httpMethod: HTTPMethod.GET, authentication: true)
    }
    
    // CODE
    public func getURLforCode(userId: String, code: String, callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.Go.rawValue)?code=\(code)")!
        makeHTTPRequest(APIMethod.GET_OAUTH_URL_FOR_CODE, callback: callback, url: url, httpMethod: HTTPMethod.GET, authentication: true)
    }
    
    // USERS
    func createUserWithID(userID: String, secret: String, callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.Users.rawValue)")!
        let params: [String:String] = ["user_id" : userID,
            "secret" : secret]
        makeHTTPRequest(APIMethod.CREATE_USER, callback: callback, url: url, httpMethod: HTTPMethod.POST, params: params, authentication: false)
    }
    public func getUserWithID(userID:String, callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.Users.rawValue)/\(userID)")!
        makeHTTPRequest(APIMethod.GET_USER, callback: callback, url: url, httpMethod: HTTPMethod.GET)
    }
    func handleCreateUserResponse(data: NSDictionary?) -> String? {
        if let access_token = data?["access_token"] {
            // TODO handle data?["verification_id"]
            return access_token as? String
        }
        return String?()
    }
    public func saveUserInfoForUserID(userID:String, key: C29User.Key, value: AnyObject, callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.Users.rawValue)/\(userID)/\(key.rawValue)?embed=user")!
        let params = [key.rawValue: value]
        makeHTTPRequest(APIMethod.SAVE_USER_INFO, callback: callback, url: url, httpMethod: HTTPMethod.POST, params: params)
    }
    public func deleteUserInfoForUserID(userID:String, key: C29User.Key, value: AnyObject, callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.Users.rawValue)/\(userID)/\(key.rawValue)/\(value)?embed=user")!
        makeHTTPRequest(APIMethod.DELETE_USER_INFO, callback: callback, url: url, httpMethod: HTTPMethod.DELETE)
    }
    public func deleteUserWithUserID(userID:String, secret: String, callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.Users.rawValue)/\(userID)")!
        let params: [String:String] = ["secret" : secret]
        makeHTTPRequest(APIMethod.DELETE_USER, callback: callback, url: url, httpMethod: HTTPMethod.DELETE, params: params)
    }
    func handleEditUser(data: NSDictionary?) -> C29User? {
        if let userDict = data?["user"] as! NSDictionary? {
            return C29User.fromDictionary(userDict)
        }
        // Note there is also a data?["deleted"] and data?["updated"] dict that we're not currently inspecting
        return C29User?()
    }
    
    // USERS / Verification
    
    public func getVerificationCode(toPhoneNumber: String, secret: String, callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.Users.rawValue)/\(Path.Verify.rawValue)")!
        let params: [String:String] = ["to" : toPhoneNumber, "secret" : secret]
        makeHTTPRequest(APIMethod.DIALOG_VERIFY, callback: callback, url: url, httpMethod: HTTPMethod.POST, params: params, authentication: false)
    }
    public func postUserVerification(verificationCode: C29VerificationCode, digits: String, callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.Users.rawValue)/\(Path.Verify.rawValue)/\(verificationCode.code)")!
        let params: [String:String] = ["digits" : digits]
        makeHTTPRequest(APIMethod.DIALOG_VERIFY_CODE, callback: callback, url: url, httpMethod: HTTPMethod.POST, params: params, authentication: false)
    }
    
    // USERS / Records
    public func saveUserRecordsForUserID(userID:String, records: [CopperRecord], callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.Users.rawValue)/\(userID)/\(Path.UsersRecords.rawValue)")!
        var params = [String:AnyObject]()
        for record in records {
            var recordsOfScope = [AnyObject]()
            if let current = params[record.scope.value!] as? [AnyObject] {
                recordsOfScope = current
            }
            recordsOfScope.append(record.dictionary)
            params[record.scope.value!] = recordsOfScope
        }
        makeHTTPRequest(APIMethod.SAVE_USER_RECORDS, callback: callback, url: url, httpMethod: HTTPMethod.PUT, params: params)
    }
    public func getUserRecordsForUserID(userID:String, since: NSDate?, callback: C29APICallback) {
        var _url = "\(URL)/\(Path.Users.rawValue)/\(userID)/\(Path.UsersRecords.rawValue)"
        if let since = since {
            _url += "?since=\(since.timeIntervalSince1970)"
        }
        let url = NSURL(string: _url)!
        makeHTTPRequest(APIMethod.GET_USER_RECORDS, callback: callback, url: url, httpMethod: HTTPMethod.GET)
    }
    public func deleteUserRecordsForUserID(userId: String, records: [CopperRecord], callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.Users.rawValue)/\(userId)/\(Path.UsersRecords.rawValue)/")!
        var params = [String:[[String:String]]]()
        for record in records {
            var recordsOfScope = [[String:String]]()
            if let current = params[record.scope.value!] {
                recordsOfScope = current
            }
            recordsOfScope.append(["id":record.id])
            params[record.scope.value!] = recordsOfScope
        }
        makeHTTPRequest(APIMethod.DELETE_USER_RECORDS, callback: callback, url: url, httpMethod: HTTPMethod.DELETE, params: params)
    }
    
    // USERS / Applications
    public func getUserApplicationsForUserID(userID:String, callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.Users.rawValue)/\(userID)/\(Path.UsersApplications.rawValue)")!
        makeHTTPRequest(APIMethod.GET_USER_APPLICATIONS, callback: callback, url: url, httpMethod: HTTPMethod.GET)
    }
    public func getUserApplicationForUserID(userID:String, applicationId: String, callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.Users.rawValue)/\(userID)/\(Path.UsersApplications.rawValue)/\(applicationId)")!
        makeHTTPRequest(APIMethod.GET_USER_APPLICATION, callback: callback, url: url, httpMethod: HTTPMethod.GET)
    }
    public func deleteUserApplicationForUserID(userId:String, applicationId: String, callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.Users.rawValue)/\(userId)/\(Path.UsersApplications.rawValue)/\(applicationId)")!
        makeHTTPRequest(APIMethod.DELETE_USER_APPLICATION, callback: callback, url: url, httpMethod: HTTPMethod.DELETE)
    }
    
    // USERS / Devices
    public func getUserDevicesForUserID(userID: String, deviceId: String?, callback: C29APICallback) {
        var _url = "\(URL)/\(Path.Users.rawValue)/\(userID)/\(Path.UserDevices.rawValue)"
        if let deviceId = deviceId {
            _url = "\(_url)?device=\(deviceId)"
        }
        let url = NSURL(string: _url)!
        makeHTTPRequest(APIMethod.GET_USER_DEVICES, callback: callback, url: url, httpMethod: HTTPMethod.GET)
    }
    public func getUserDeviceForUserID(userID: String, deviceId: String, callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.Users.rawValue)/\(userID)/\(Path.UserDevices.rawValue)/\(deviceId)")!
        makeHTTPRequest(APIMethod.GET_USER_DEVICE, callback: callback, url: url, httpMethod: HTTPMethod.GET)
    }
    public func deleteUserDeviceForUserID(userId:String, deviceId: String, callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.Users.rawValue)/\(userId)/\(Path.UserDevices.rawValue)/\(deviceId)")!
        makeHTTPRequest(APIMethod.DELETE_USER_DEVICE, callback: callback, url: url, httpMethod: HTTPMethod.DELETE)
    }
    public func updateUserDeviceForUserID(userId: String, deviceId: String, params: [String:AnyObject], callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.Users.rawValue)/\(userId)/\(Path.UserDevices.rawValue)/\(deviceId)")!
        makeHTTPRequest(APIMethod.UPDATE_USER_DEVICE, callback: callback, url: url, httpMethod: HTTPMethod.POST, params: params)
    }
    
    // USERS / Request
    public func getRequestForUserID(userId:String, requestId: String, callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.Users.rawValue)/\(userId)/\(Path.UsersRequests.rawValue)/\(requestId)")!
        makeHTTPRequest(APIMethod.GET_REQUEST, callback: callback, url: url, httpMethod: HTTPMethod.GET)
    }
    public func setRequestGrantForUserID(userId:String, request: C29Request, status: C29RequestStatus, records: [CopperRecord], forceRecordUpload: Bool, callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.Users.rawValue)/\(userId)/\(Path.UsersGrant.rawValue)")!
        var params = [String:AnyObject]()
        // 1: add the request && status
        params[C29Request.Key.RequestId.rawValue] = request.id
        params[C29Request.Key.Status.rawValue] = status.rawValue
        if status == .Approved {
            // 2: add the application_records
            var applicationRecordIds = [String:[String]]()
            for record in records {
                var recordsOfScope = [String]()
                if let current = applicationRecordIds[record.scope.value!] {
                    recordsOfScope = current
                }
                recordsOfScope.append(record.id)
                applicationRecordIds[record.scope.value!] = recordsOfScope
            }
            if applicationRecordIds.count > 0 {
                params["application_records"] = applicationRecordIds
            }
            // 3: add any records
            var recordsToSend = [String:AnyObject]()
            for record in records {
                if !record.uploaded || forceRecordUpload {
                    var recordsOfScope = [AnyObject]()
                    if let current = recordsToSend[record.scope.value!] as? [AnyObject] {
                        recordsOfScope = current
                    }
                    recordsOfScope.append(record.dictionary)
                    recordsToSend[record.scope.value!] = recordsOfScope
                }
            }
            if recordsToSend.count > 0 {
                params["records"] = recordsToSend
            }
        }
        // All set... let's send it
        makeHTTPRequest(APIMethod.SET_REQUEST_GRANT, callback: callback, url: url, httpMethod: HTTPMethod.POST, params: params)
    }
    public func setRequestAckForUserID(userID:String, request: C29Request, callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.Users.rawValue)/\(userID)/\(Path.UsersRequests.rawValue)/\(request.id)/\(Path.UsersRequestsAck.rawValue)")!
        makeHTTPRequest(APIMethod.SET_REQUEST_ACKNOWLEDGED, callback: callback, url: url, httpMethod: HTTPMethod.POST)
    }
    // USERS / Application / Records
    public func saveUserApplicationRecordsForUserID(userId:String, applicationId: String, records: [CopperRecord], callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.Users.rawValue)/\(userId)/\(Path.UsersApplications.rawValue)/\(applicationId)/\(Path.UsersRecords.rawValue)")!
        var params = [String:[String]]()
        for record in records {
            var recordsOfScope = [String]()
            if let current = params[record.scope.value!] {
                recordsOfScope = current
            }
            recordsOfScope.append(record.id)
            params[record.scope.value!] = recordsOfScope
        }
        makeHTTPRequest(APIMethod.SAVE_USER_APPLICATION_RECORDS, callback: callback, url: url, httpMethod: HTTPMethod.PUT, params: params)
    }
    // NOTE: Use with caution per the docs -- since this could inadvertently delete a record used by a Client and should probably be avoided
    public func deleteUserApplicationRecordsForUserID(userId:String, applicationId: String, records: [CopperRecord], callback: C29APICallback) {
        let url = NSURL(string: "\(URL)/\(Path.Users.rawValue)/\(userId)/\(Path.UsersApplications.rawValue)/\(Path.UsersRecords.rawValue)")!
        var params = [String:[[String:String]]]()
        for record in records {
            var recordsOfScope = [[String:String]]()
            if let current = params[record.scope.value!] {
                recordsOfScope = current
            }
            recordsOfScope.append(["id":record.id])
            params[record.scope.value!] = recordsOfScope
        }
        makeHTTPRequest(APIMethod.DELETE_USER_APPLICATION_RECORDS, callback: callback, url: url, httpMethod: HTTPMethod.DELETE, params: params)
    }
    
    // IMAGES and FILEs
    public func createBytes(userID: String, fileID: String, file: NSData, callback: C29APICallback) {
        let _url = "\(URL)/\(Path.Bytes.rawValue)"
        let url = NSURL(string: _url)
        let base64EncodedFile = file.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        let params = ["file_id":fileID, "file":base64EncodedFile]
        makeHTTPRequest(APIMethod.CREATE_BYTES, callback: callback, url: url!, httpMethod: HTTPMethod.POST, params: params)
    }
    
    
    // Create and return an NSError message that is expected and meaningful to the caller
    func handleError(data: NSDictionary! = nil, statusCode: Int = 500) -> NSError {
        var errorMsg = "We're having technical problems. Please try again soon." // our default
        if let returnedMsg = data?["message"] {
            errorMsg = returnedMsg as! String
        }
        // TODO capture the {code: internal_code} sub-json
        return NSError(domain: CopperAPIError.HTTPStatusCode.domain, code: statusCode, userInfo:["message": errorMsg])
    }

}

public class Reachability {
    
    // credit: http://stackoverflow.com/questions/25623272/how-to-use-scnetworkreachability-in-swift/25623647#25623647
    public class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(&zeroAddress, {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }) else {
            return false
        }
        
        var flags : SCNetworkReachabilityFlags = []
        if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) == false {
            return false
        }
        
        let isReachable = flags.contains(.Reachable)
        let needsConnection = flags.contains(.ConnectionRequired)
        return (isReachable && !needsConnection)
    }
    
}


public enum CopperAPIError: Int {
    case Disconnected = 0
    case Auth = 1
    // case UserConflict = 2
    case JsonInvalid = 3
    case CopperAPIDown = 4
    case HTTPStatusCode = 5
    
    // Dialog errors
    case DialogCodeExpired = 22
    case DialogCodeLocked = 23
    case DialogCodeInvalid = 24
    
    var reason: String {
        switch self {
        case Disconnected:
            return "Your device appears to be disconnected from the Internet."
        case Auth:
            return "You are no longer authenticated with Copper. For security, we need you to be authenticated before we can complete this request. You may need to restart the app to fix this error."
        //case UserConflict:
        //    return "This user id was previously registered."
        case JsonInvalid:
            return "We were unable to process that request."
        case CopperAPIDown:
            return "Copper is down"
        case HTTPStatusCode:
            return "Unexpected HTTP Status code"
        case DialogCodeExpired:
            return "That code is expired. Try again."
        case DialogCodeLocked:
            return "That code is locked. Try again."
        case DialogCodeInvalid:
            return "Wrong code."
        }
    }
    var description: String {
        switch self {
        case .CopperAPIDown:
            return "Check @withcopper for our status. Otherwise, please try again soon."
        default:
            return self.reason
        }
    }
    var nserror: NSError {
        return NSError(domain: self.domain, code: self.rawValue, userInfo: ["message": self.reason, NSLocalizedFailureReasonErrorKey: self.reason])
    }
    var domain: String {
        return "\(NSBundle.mainBundle().bundleIdentifier!).CopperAPI"
    }
}


extension C29API {
    func logAPIError(httpResponse: NSHTTPURLResponse, httpMethodRaw: String, url: NSURL, error: NSError?, params: [String:AnyObject]?, dataDict: NSDictionary?, authentication: Bool, authToken: String?, delegate: CopperNetworkAPIDelegate?, api: CopperNetworkAPI) {
        if httpResponse.statusCode >= 300 {
            C29Log(.Error, "CopperAPI statusCode was not 200 -> code \(httpResponse.statusCode) with this error from the server: \(error?.localizedDescription) for \(httpMethodRaw) \(url) with data \(dataDict) with authentication \(authentication)")
        }
        
        var parameters = [String:AnyObject]()
        parameters["HTTP"] = httpMethodRaw
        parameters["Status Code"] = httpResponse.statusCode
        parameters["URL"] = "\(url)"
        let identifer = delegate?.userIdentifierForLoggingErrorsInAPI(api) ?? ""
        parameters["id"] = "\(identifer))"
        parameters["error_message"] = error?.localizedDescription
        parameters["error_code"] = error?.code
        if let params = params {
            for (key, value) in params {
                parameters["param_\(key)"] = value
            }
        }
        parameters["authentication"] = authentication
        if let token = authToken {
            parameters["auth_token"] = token
        } else {
            parameters["auth_token"] = "nil"
        }
        delegate?.networkAPI(api, recordAnalyticsEvent: "API non-200 Error", withParameters: parameters)
        if error != nil {
            C29LogWithRemote(.Error, error: error!, infoDict: parameters)
        }
        
    }
}
