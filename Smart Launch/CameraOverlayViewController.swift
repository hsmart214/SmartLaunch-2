//
//  CameraOverlayViewController.swift
//  SmartLaunch
//
//  Created by J. HOWARD SMART on 4/12/20.
//  Copyright © 2020 J. HOWARD SMART. All rights reserved.
//

import UIKit

class CameraOverlayViewController: UIViewController {
    // this class exists just to instantiate the overlayView
    // for the camera-assisted launch angle determination
    
    // once created, its overlayView will be placed in the UIImagePickerViewController as the cameraOverlayView
    // then we will have to hook up the target-action pairs
    @IBOutlet var overlayView: OverlayView!
    
}
