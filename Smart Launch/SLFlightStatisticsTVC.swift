//
//  SLFlightStatisticsTVC.swift
//  Smart Launch
//
//  Created by J. HOWARD SMART on 5/21/16.
//  Copyright © 2016 J. HOWARD SMART. All rights reserved.
//

import UIKit

extension Rocket{
    func totalFlownImpulse() -> Double{
        var impulse = 0.0
        if self.recordedFlights != nil{
            for flight in self.recordedFlights!{
                if let settings = flight[FLIGHT_SETTINGS_KEY] as? [String : AnyObject]{
                    impulse += SLClusterMotor.totalImpulseFromFlightSettings(settings)
                }
            }
        }
        return impulse
    }
}

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
            if let flights = rocket.recordedFlights{
                launches += flights.count
            }
            totalImpulse += rocket.totalFlownImpulse()
        }
        totalImpulseLabel.text = String(format: "%1.1f Ns", totalImpulse)
        numberOfLaunchesLabel.text = "\(launches)"
        averageImpulseLabel.text = String(format: "%1.1f Ns", totalImpulse/Double(launches))
    }
    
    func updateRocketList(){
        flownRockets.removeAll()
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if let allRockets = defaults.objectForKey(FAVORITE_ROCKETS_KEY) as? [String: [String: AnyObject]]{
            for (_, rocketPlist) in allRockets{
                if let rocket = Rocket(properties: rocketPlist){
                    if let flights = rocket.recordedFlights where flights.count != 0{
                        flownRockets.append(rocket)
                    }
                }
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let dvc = segue.destinationViewController as? SLRocketsLaunchedTVC{
            dvc.rockets = flownRockets
        }
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
        
        updateRocketList()
        updateUI()
    }
}
