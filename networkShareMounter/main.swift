//
//  main.swift
//  networkShareMounter
//
//  Created by Kett, Oliver on 20.03.17.
//  Copyright © 2017 Kett, Oliver. All rights reserved.
//

import Foundation
import NetFS
import SystemConfiguration
import OpenDirectory

// create subfolder in home to mount shares in
let localizedFolder = config.translation[Locale.current.languageCode!] ?? config.translation["en"]!
let mountpath = NSString(string: "~/\(localizedFolder)").expandingTildeInPath
do {
    let fm = FileManager.default
    if !fm.fileExists(atPath: mountpath) {
        try fm.createDirectory(atPath: mountpath, withIntermediateDirectories: false, attributes: nil)
        NSLog("\(mountpath): created")
    }
} catch {
    NSLog("error creating folder: \(mountpath)")
    NSLog(error.localizedDescription)
    exit(2)
}

var shares: [String] = UserDefaults(suiteName: config.defaultsDomain)?.array(forKey: "networkShares") as? [String] ?? []
// replace %USERNAME with local username - must be the same as directory service username!
shares = shares.map {
    $0.replacingOccurrences(of: "%USERNAME%", with: NSUserName())
}
// append SMBHomeDirectory attribute to list of shares to mount
do {
    let node = try ODNode(session: ODSession.default(), type: ODNodeType(kODNodeTypeAuthentication))
    let query = try ODQuery(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeRecordName, matchType: ODMatchType(kODMatchEqualTo), queryValues: NSUserName(), returnAttributes: kODAttributeTypeSMBHome, maximumResults: 1).resultsAllowingPartial(false) as! [ODRecord]
    if let result = query[0].value(forKey: kODAttributeTypeSMBHome) as? [String] {
        var homeDirectory = result[0]
        homeDirectory = homeDirectory.replacingOccurrences(of: "\\\\", with: "smb://")
        homeDirectory = homeDirectory.replacingOccurrences(of: "\\", with: "/")
        shares.append(homeDirectory)
    }
}
// eliminate duplicates
shares = NSOrderedSet(array: shares).array as! [String]

if shares.count == 0 {
    NSLog("no shares configured!")
} else {
    for share in shares {
        guard let encodedShare = share.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed) else { continue }
        guard let url = NSURL(string: encodedShare) else { continue }
        guard let host = url.host else { continue }
        
        // check if we have network connectivity
        var flags = SCNetworkReachabilityFlags(rawValue: 0)
        let hostReachability = SCNetworkReachabilityCreateWithName(nil, (host as NSString).utf8String!)
        guard SCNetworkReachabilityGetFlags(hostReachability!, &flags) == true else { NSLog("could not determine reachability for host \(host)"); continue }
        guard flags.contains(.reachable) == true else { NSLog("\(host): target not reachable"); continue }
        
        let rc = NetFSMountURLSync(url, NSURL(string: mountpath), nil, nil, config.open_options, config.mount_options, nil)
        
        switch rc {
        case 0:
            NSLog("\(url): successfully mounted")
        case 2:
            NSLog("\(url): does not exist")
        case 17:
            NSLog("\(url): already mounted")
        case 65:
            NSLog("\(url): no route to host")
        case -6003:
            NSLog("\(url): share does not exist")
        default:
            NSLog("\(url) unknown return code: \(rc)")
        }
    }
}

