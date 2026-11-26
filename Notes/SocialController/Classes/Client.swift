//
//  Client.swift
//  Mustage
//
//  Created by Oleg Baidalka on 23/02/2018.
//  Copyright © 2018 Bossly. All rights reserved.
//

protocol Client {
    func setup() -> Self
}

protocol Analytica {
    
    // user properties
    func trackRemoteConfig(loaded:Bool)
    func trackAdmobLoading(appId:String)
    func trackCrashlogEnabled()
    
    // events
    func trackError(message:String)
    func trackOpenCamera()
}
