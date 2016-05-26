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

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rocket?.recordedFlights?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SavedFlightCell", forIndexPath: indexPath)
        let flightData = rocket?.recordedFlights![indexPath.row] as? [String: AnyObject]
        if let flightCell = cell as? SLFlightDataCell where flightData != nil{
            var altitude : Float = flightData![FLIGHT_ALTITUDE_KEY] as? Float ?? 0.0
            let cd : Double = flightData![FLIGHT_BEST_CD] as? Double ?? 0.0
            let motor : String = flightData![FLIGHT_MOTOR_LONGNAME_KEY] as? String ?? ""
            flightCell.cd.text = String(format: "%1.2f", cd)
            flightCell.motorName.text = motor
            altitude = SLUnitsConvertor.displayUnitsOf(altitude, forKey: ALT_UNIT_KEY)
            flightCell.altitude.text = String(format: "%1.0f", altitude)
            flightCell.altitudeUnitsLabel.text = SLUnitsConvertor.displayStringForKey(ALT_UNIT_KEY)
            if let settings = flightData![FLIGHT_SETTINGS_KEY] as? [String : AnyObject]{
                let impulse = SLClusterMotor.totalImpulseFromFlightSettings(settings)
                flightCell.motorImpulse.text = String(format: "%1.1f Ns", impulse)
            }
        }
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.splitViewController == nil{
            let backgroundView = UIImageView(frame: self.view.frame)
            let backgroundImage = UIImage(named: BACKGROUND_IMAGE_FILENAME)
            backgroundView.image = backgroundImage
            self.tableView.backgroundView = backgroundView
            self.tableView.backgroundColor = UIColor.clearColor()
        }else{
            let backgroundView = UIImageView(frame: self.view.frame)
            let backgroundImage = UIImage(named: BACKGROUND_FOR_IPAD_MASTER_VC)
            backgroundView.image = backgroundImage
            self.tableView.backgroundView = backgroundView
            self.tableView.backgroundColor = UIColor.clearColor()
        }
    }
}
