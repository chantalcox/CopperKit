//
//  C29AppSessionDataSource.swift
//  Copper
//
//  Created by Doug Williams on 3/22/16.
//  Copyright © 2016 Copper Technologies, Inc. All rights reserved.
//

import Foundation

public let C29SessionIdentityDidUpdateNotification = "C29SessionIdentityDidUpdateNotification"

public protocol C29SessionDataSource {
    var userId: String? { get }
    var requestStack:C29RequestStack { get }
    var applicationCache:C29CopperworksApplicationCache { get }
    var recordCache:C29RecordCache { get }
    var imageCache:C29ImageCache { get }
    var api: C29API { get }
    var user: C29User? { get }
    var appGroupIdentifier: String { get }
}