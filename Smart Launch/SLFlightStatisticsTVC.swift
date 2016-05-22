//
//  SLFlightStatisticsTVC.swift
//  Smart Launch
//
//  Created by J. HOWARD SMART on 5/21/16.
//  Copyright © 2016 J. HOWARD SMART. All rights reserved.
//

import UIKit

class SLFlightStatisticsTVC: UITableViewController {

    @IBOutlet weak var numberOfLaunchesLabel: UILabel!
    @IBOutlet weak var totalImpulseLabel: UILabel!
    @IBOutlet weak var averageImpulseLabel: UILabel!
    @IBOutlet weak var uniqueRocketsLaunchedLabel: UILabel!
    weak var delegate : AnyObject?
    //This is the model of this TVC
    //Here we are guaranteed not to be able to edit any of the Rockets
    //They may be changed underneath us so we should register for update notifications
    //TODO: observe for changes in user defaults
    var flownRockets = [Rocket]()
    
    func updateUI(){
        var launches = 0
        var totalImpulse = 0.0
        uniqueRocketsLaunchedLabel.text = "\(flownRockets.count)"
        for rocket in flownRockets{
            launches += rocket.recordedFlights.count
            var partialImpulse = 0.0
            for flight in rocket.recordedFlights{
                if let settings = flight[FLIGHT_SETTINGS_KEY] as? [String : AnyObject]{
                    partialImpulse += SLPhysicsModel.totalImpulseFromFlightSettings(settings)
                }
            }
            totalImpulse += partialImpulse
        }
        totalImpulseLabel.text = "\(totalImpulse)"
        numberOfLaunchesLabel.text = "\(launches)"
        averageImpulseLabel.text = "\(totalImpulse/Double(launches))"
    }
    
    func updateRocketList(){
        flownRockets.removeAll()
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if let allRockets = defaults.objectForKey(FAVORITE_ROCKETS_KEY) as? [String: [String: AnyObject]]{
            for (_, rocketPlist) in allRockets{
                let rocket = Rocket(properties: rocketPlist)
                if rocket.recordedFlights.count != 0{
                    flownRockets.append(rocket)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateRocketList()
        updateUI()
    }
}
