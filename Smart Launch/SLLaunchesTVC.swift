//
//  SLLaunchesTVC.swift
//  Smart Launch
//
//  Created by J. HOWARD SMART on 5/22/16.
//  Copyright © 2016 J. HOWARD SMART. All rights reserved.
//

import UIKit

class SLLaunchesTVC: UITableViewController {
    var rocket : Rocket?
    var nf = NumberFormatter()

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rocket?.recordedFlights?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavedFlightCell", for: indexPath)
        // find out if the saved record is an old one - pre-clusters
        // the settings has a complete motorPlist stashed away in it in SELECTED_MOTOR_KEY
        // if the version is 1.5 or higher, this will be an NSArray rather than a motorDict
        // versions 1.4 and previous did not have a SMART_LAUNCH_VERSION_KEY key at all, so it will be nil
        let flightData = rocket?.recordedFlights![indexPath.row] as? [String: AnyObject]
        if let flightCell = cell as? SLFlightDataCell, flightData != nil{
            var altitude : Float = flightData![FLIGHT_ALTITUDE_KEY] as? Float ?? 0.0
            let cd : Double = flightData![FLIGHT_BEST_CD] as? Double ?? 0.0
            let motorName : String = flightData![FLIGHT_MOTOR_LONGNAME_KEY] as? String ?? flightData![FLIGHT_MOTOR_KEY] as? String ?? ""
            flightCell.cd.text = String(format: "%1.2f", cd)
            flightCell.motorName.text = motorName
            altitude = SLUnitsConvertor.displayUnits(of: altitude, forKey: ALT_UNIT_KEY)
            flightCell.altitude.text = String(format: "%1.0f", altitude)
            flightCell.altitudeUnitsLabel.text = SLUnitsConvertor.displayString(forKey: ALT_UNIT_KEY)
            var impulse : Double
            if let _ = flightData![FLIGHT_SETTINGS_KEY] as? [String : AnyObject]{
                impulse = SLClusterMotor.totalImpulse(fromFlight: flightData)
            }else{
                // try to get an impulse value using only the motor short name.
                let motorShortName = flightData![FLIGHT_MOTOR_KEY] as! String
                impulse = RocketMotor.totalImpulseOfMotor(withName: motorShortName)
            }
            if let impulseString = nf.string(from: NSNumber(value:impulse)){
                flightCell.motorImpulse.text = impulseString + " Ns"
            }
        }
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nf.usesGroupingSeparator = true
        nf.maximumFractionDigits = 1
        nf.numberStyle = .decimal
        
        if self.splitViewController == nil{
            let backgroundView = UIImageView(frame: self.view.frame)
            let backgroundImage = UIImage(named: BACKGROUND_IMAGE_FILENAME)
            backgroundView.image = backgroundImage
            self.tableView.backgroundView = backgroundView
            self.tableView.backgroundColor = UIColor.clear
        }else{
            let backgroundView = UIImageView(frame: self.view.frame)
            let backgroundImage = UIImage(named: BACKGROUND_FOR_IPAD_MASTER_VC)
            backgroundView.image = backgroundImage
            self.tableView.backgroundView = backgroundView
            self.tableView.backgroundColor = UIColor.clear
        }
    }
}
