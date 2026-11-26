//
//  FirebaseClient.swift
//  Mustage
//
//  Created by Oleg Baidalka on 28/02/2018.
//  Copyright © 2018 Bossly. All rights reserved.
//

import Foundation
import UIKit
import FirebaseStorage

import Firebase
import FirebaseRemoteConfig
import SDWebImage

class FirebaseClient : Client {
    
    func setup() -> Self {
        
        // load configs
        //        FirebaseApp.configure()   // already in appDelegate
        
        // set maximum concurrent downloads
        //        SDWebImageManager.shared.imageDownloader?.maxConcurrentDownloads = kMaxConcurrentImageDownloads
        
        
        // enable notification in application
        setupNotification()
        
        // enable ads
        if kAdMobEnabled {
            //GADMobileAds.configure(withApplicationID: kAdMobApplicationID)
            trackAdmobLoading(appId: kAdMobApplicationID)
        }
        
        return self
    }
}

extension FirebaseClient : Analytica {
    
    // MARK: - User properties
    func trackAdmobLoading(appId: String) {
        Analytics.setUserProperty(appId, forName: "admob_enabled")
    }
    func trackRemoteConfig(loaded: Bool) {
        Analytics.setUserProperty(String(loaded), forName: "remote_config_loading")
    }
    func trackCrashlogEnabled() {
        Analytics.setUserProperty(String(true), forName: "crashlog_enabled")
    }
    
    // MARK: - Events
    func trackOpenCamera() {
        Analytics.logEvent("camera_opened", parameters: nil)
    }
    func trackError(message: String) {
        Analytics.logEvent("Error", parameters: [AnalyticsParameterValue:message])
    }
}

extension FirebaseClient : NotificationClient { }

extension FirebaseClient : AuthClient {
    
    func saveUser(userId:String, name:String, photo:String, override:Bool = true) {
        
        let ref = Database.database().reference().child(kUsersKey).child(userId)
        
        if (override) {
            ref.updateChildValues(["User Name": name, "photo": photo])
        } else {
            // check if data exist
            ref.observeSingleEvent(of: .value, with: { (data) in
                if data.exists(), let values = data.value as? [String:Any] {
                    let newname = values["User Name"] as? String ?? name
                    let newphoto = values["photo"] as? String ?? photo
                    
                    ref.updateChildValues(["User Name": newname, "photo": newphoto])
                } else if !data.exists() {
                    ref.updateChildValues(["User Name": name, "photo": photo])
                }
            })
        }
    }
}


/// A fresh JPEG bitmap removes source metadata and never exceeds the upload limit.
enum ApplazImagePayload {
    static let maximumBytes = 20_000

    static func jpeg(from image: UIImage) -> Data? {
        guard image.size.width.isFinite, image.size.height.isFinite,
              image.size.width > 0, image.size.height > 0 else { return nil }
        var longest = min(CGFloat(1024), max(image.size.width, image.size.height))
        while longest >= 1 {
            let scale = longest / max(image.size.width, image.size.height)
            let size = CGSize(width: max(1, floor(image.size.width * scale)), height: max(1, floor(image.size.height * scale)))
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = true
            let bitmap = UIGraphicsImageRenderer(size: size, format: format).image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: size))
                image.draw(in: CGRect(origin: .zero, size: size))
            }
            for quality in [CGFloat(0.85), 0.7, 0.55, 0.4, 0.25, 0.12] {
                if let data = bitmap.jpegData(compressionQuality: quality), data.count <= maximumBytes { return data }
            }
            if longest == 1 { break }
            longest = max(1, floor(longest * 0.75))
        }
        return nil
    }
}

/// Both image flows use the authenticated app's configured Firebase bucket.
enum ApplazImageUploader {
    static func upload(_ data: Data, path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        func finish(_ result: Result<URL, Error>) { DispatchQueue.main.async { completion(result) } }
        guard !data.isEmpty, data.count <= ApplazImagePayload.maximumBytes,
              data.starts(with: [0xff, 0xd8]) else {
            finish(.failure(NSError(domain: "ApplazImage", code: 1, userInfo: [NSLocalizedDescriptionKey: "The image couldn't be converted to a JPEG under 20 KB."])))
            return
        }
        guard let app = FirebaseApp.app(), Auth.auth(app: app).currentUser != nil,
              let bucket = app.options.storageBucket, !bucket.isEmpty else {
            finish(.failure(NSError(domain: "ApplazImage", code: 2, userInfo: [NSLocalizedDescriptionKey: "Sign in to upload an image."])))
            return
        }
        let reference = Storage.storage(app: app).reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.cacheControl = "no-cache, max-age=0"
        reference.putData(data, metadata: metadata) { _, error in
            if let error { finish(.failure(error)); return }
            reference.downloadURL { url, error in
                if let error { finish(.failure(error)); return }
                guard let url, url.scheme == "https" else {
                    finish(.failure(NSError(domain: "ApplazImage", code: 3, userInfo: [NSLocalizedDescriptionKey: "Firebase didn't return an image URL."])))
                    return
                }
                finish(.success(url))
            }
        }
    }
}
