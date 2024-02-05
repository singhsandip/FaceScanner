//
//  FaceDetectionViewController+Extras.swift
//  Face Scanner
//
//  Created by sandeepsing-maclaptop on 05/02/24.
//

import Foundation
import UIKit
import AVFoundation

extension FaceDetectionViewController {
    //MARK:- View Setup
    func setupView(){
       view.backgroundColor = .black
    }
    
    //MARK:- Permissions
    func checkPermissions() {
        let cameraAuthStatus =  AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch cameraAuthStatus {
          case .authorized:
            return
          case .denied:
            abort()
          case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:
            { (authorized) in
              if(!authorized){
                abort()
              }
            })
          case .restricted:
            abort()
          @unknown default:
            fatalError()
        }
    }
}
