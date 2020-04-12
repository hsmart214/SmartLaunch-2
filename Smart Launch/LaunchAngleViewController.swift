//
//  LaunchAngleViewController.swift
//  SmartLaunch
//
//  Created by J. HOWARD SMART on 4/5/20.
//  Copyright © 2020 J. HOWARD SMART. All rights reserved.
//

import UIKit
import CoreMotion

class LaunchAngleViewController: UIViewController, SLLaunchAngleViewDataSource {
    func angle(for sender: SLLaunchAngleView!) -> CGFloat {
        return CGFloat(self.angleSlider.value)
    }
    
    let xyCalibrationKey = "com.smartsoftware.launchsafe.xyCalibrationValue"

    var motionManager = CMMotionManager()
    var motionQueue = OperationQueue()
    var nf = NumberFormatter()
    var delegate : AnyObject?
    
    @IBOutlet weak var angleLabel: UILabel!
    @IBOutlet weak var angleView: SLLaunchAngleView!
    @IBOutlet weak var angleSlider: UISlider!
    @IBOutlet weak var calibrateButton: UIBarButtonItem!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var motionButton: UIBarButtonItem!

    var xyCalibrationAngle : Float = 0.0
    var xAccel : Float = 0.0
    var yAccel : Float = 0.0
    var zAccel : Float = 0.0
    let accelerometerInterval = 0.1 // seconds between updates
    let filterConstant : Float = 0.2       // smaller number gives smoother, slower response
    let tolerance : Float = 0.002
    
    func update(accel: CMAcceleration){
        // this is running on motionQueue - a background thread with QOS = .userInteractive

        xAccel = Float(accel.x) * filterConstant + xAccel * (1.0 - filterConstant);
        yAccel = Float(accel.y) * filterConstant + yAccel * (1.0 - filterConstant);
        zAccel = Float(accel.z) * filterConstant + zAccel * (1.0 - filterConstant);
        let xyAngle = self.yAccel != 0.0 ? atanf(self.xAccel/self.yAccel) - self.xyCalibrationAngle : 0.0
        let angle = Float(xyAngle)
        let angleRadians = NSNumber.init(floatLiteral: Double(xyAngle) * Double(DEGREES_PER_RADIAN))
        OperationQueue.main.addOperation { [weak self] in
            
            self?.angleLabel.text = self?.nf.string(from: angleRadians)
            
            if let currentAngle = self?.angleSlider.value, let tol = self?.tolerance, fabsf(angle - currentAngle) > tol{
                self?.angleSlider.setValue(angle, animated: true)
                self?.angleView.setNeedsDisplay()
            }
        }
    }
    
    @IBAction func calibrate(_ sender: Any) {
        xyCalibrationAngle = atanf(xAccel/yAccel)
        let setts = UserDefaults.standard.object(forKey: SETTINGS_KEY) as! NSDictionary
        let settings = setts.mutableCopy() as! NSMutableDictionary
        settings[xyCalibrationKey] = NSNumber(floatLiteral: Double(xyCalibrationAngle))
        UserDefaults.standard.set(settings, forKey: SETTINGS_KEY)
    }
    
    @IBAction func angleSliderChanged(_ sender: UISlider) {
        let newAngle = sender.value
        let angleRadians = NSNumber.init(floatLiteral: Double(newAngle) * Double(DEGREES_PER_RADIAN))
        angleLabel.text = nf.string(from: angleRadians)
        angleView.setNeedsDisplay()
    }
    
    
    @IBAction func camera(_ sender: Any) {
        
    }
    
    @IBAction func toggleMotion(_ sender: UIBarButtonItem) {
        if sender.title == "Motion Off"{
            motionManager.stopAccelerometerUpdates()
            calibrateButton.isEnabled = false
            sender.title = "Motion On"
        }else{
            sender.title = "Motion Off"
            calibrateButton.isEnabled = true
            motionManager.startAccelerometerUpdates(to: motionQueue){
                [weak self] (data, error) in
                if let validData = data{
                    self?.update(accel: validData.acceleration)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        motionQueue.qualityOfService = .userInteractive
        motionManager.accelerometerUpdateInterval = accelerometerInterval
        if !motionManager.isAccelerometerAvailable{
            self.motionButton.isEnabled = false
        }
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 1
        
        // check for camera availability and permission
        cameraButton.isEnabled = UIImagePickerController.isCameraDeviceAvailable(.rear)
        let settings = UserDefaults.standard.object(forKey: SETTINGS_KEY) as! NSDictionary
        xyCalibrationAngle = (settings[xyCalibrationKey] as! NSNumber).floatValue
        let launchAngle = (settings[LAUNCH_ANGLE_KEY] as! NSNumber).floatValue // radians
        let launchAngleNSNumber = NSNumber.init(floatLiteral: Double(launchAngle))
        let angleString = nf.string(from: launchAngleNSNumber)
        angleLabel.text = angleString
        angleSlider.setValue(launchAngle, animated: true)
        angleView.dataSource = self
        
        calibrateButton.isEnabled = false   // this is enabled during motion updates only
    }
}
