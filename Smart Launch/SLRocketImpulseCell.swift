//
//  SLRocketImpulseCell.swift
//  Smart Launch
//
//  Created by J. HOWARD SMART on 5/22/16.
//  Copyright © 2016 J. HOWARD SMART. All rights reserved.
//

import UIKit

class SLRocketImpulseCell: UITableViewCell {

    @IBOutlet weak var totalImpulseLabel: UILabel!
    @IBOutlet weak var totalImpulseClassLabel: UILabel!
    @IBOutlet weak var averageImpulseClassLabel: UILabel!
    @IBOutlet weak var numberOfFlightsLabel: UILabel!
    @IBOutlet weak var rocketNameLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!

    var nf : NSNumberFormatter?
    var rocket : Rocket? {
        didSet {
            rocketNameLabel.text = rocket?.name
            avatarImageView.image = UIImage(named: rocket!.avatar)
            let flights = rocket!.recordedFlights!.count
            numberOfFlightsLabel.text = "\(flights)"
            totalImpulseLabel.text = nf?.stringFromNumber(rocket!.totalFlownImpulse())
            totalImpulseClassLabel.text = RocketMotor.impulseClassForTotalImpulse(Float(rocket!.totalFlownImpulse()))
            let avgImpulse = rocket!.totalFlownImpulse()/Double(flights)
            averageImpulseClassLabel.text = RocketMotor.impulseClassForTotalImpulse(Float(avgImpulse))
        }
    }

}
