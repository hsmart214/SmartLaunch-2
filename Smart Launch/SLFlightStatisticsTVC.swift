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
            for flight in self.recordedFlights! {
                if let flightData = flight as? [String : AnyObject]{
                    impulse += SLClusterMotor.totalImpulse(fromFlight: flightData)
                }
            }
        }
        return impulse
    }
}

class SLFlightStatisticsTVC: UITableViewController {

    @IBOutlet weak var numberOfLaunchesLabel: UILabel!
    @IBOutlet weak var totalImpulseLabel: UILabel!
    @IBOutlet weak var totalImpulseClassLabel: UILabel!
    @IBOutlet weak var averageImpulseLabel: UILabel!
    @IBOutlet weak var averageImpulseClassLabel: UILabel!
    @IBOutlet weak var avgImpulsePerRocketLabel: UILabel!
    @IBOutlet weak var uniqueRocketsLaunchedLabel: UILabel!
    weak var delegate : AnyObject?
    //This is the model of this TVC
    //Here we are guaranteed not to be able to edit any of the Rockets
    //They may be changed underneath us so we should register for update notifications
    //TODO: observe for changes in user defaults
    var flownRockets = [Rocket]()
    var nf : NumberFormatter?
    
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
        
        totalImpulseLabel.text = nf?.string(from: NSNumber(value:totalImpulse))
        totalImpulseClassLabel.text = RocketMotor.impulseClass(forTotalImpulse: Float(totalImpulse))
        numberOfLaunchesLabel.text = "\(launches)"
        let averageImpulse = Float(totalImpulse/Double(launches))
        averageImpulseLabel.text = nf?.string(from: NSNumber(value:averageImpulse))
        averageImpulseClassLabel.text = RocketMotor.impulseClass(forTotalImpulse: averageImpulse)
        let avgPerRocket = totalImpulse/Double(flownRockets.count)
        avgImpulsePerRocketLabel.text = nf?.string(from: NSNumber(value:avgPerRocket))
    }
    
    func updateRocketList(){
        flownRockets.removeAll()
        let defaults = UserDefaults.standard
        
        if let allRockets = defaults.object(forKey: FAVORITE_ROCKETS_KEY) as? [String: [String: AnyObject]]{
            for (_, rocketPlist) in allRockets{
                if let rocket = Rocket(properties: rocketPlist){
                    if let flights = rocket.recordedFlights, flights.count != 0{
                        flownRockets.append(rocket)
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dvc = segue.destination as? SLRocketsLaunchedTVC{
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
            self.tableView.backgroundColor = UIColor.clear
        }else{
            let backgroundView = UIImageView(frame: self.view.frame)
            let backgroundImage = UIImage(named: BACKGROUND_FOR_IPAD_MASTER_VC)
            backgroundView.image = backgroundImage
            self.tableView.backgroundView = backgroundView
            self.tableView.backgroundColor = UIColor.clear
        }
        
        nf = NumberFormatter()
        nf?.usesGroupingSeparator = true
        nf?.numberStyle = .decimal
        nf?.maximumFractionDigits = 1
        updateRocketList()
        updateUI()
    }
}
