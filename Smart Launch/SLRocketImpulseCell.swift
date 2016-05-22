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
    @IBOutlet weak var numberOfFlightsLabel: UILabel!
    @IBOutlet weak var rocketNameLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!

    var rocket : Rocket? {
        didSet {
            rocketNameLabel.text = rocket?.name
            avatarImageView.image = UIImage(named: rocket!.avatar)
            numberOfFlightsLabel.text = "\(rocket!.recordedFlights!.count)"
            totalImpulseLabel.text = String(format: "%1.1f Ns", rocket!.totalFlownImpulse())
        }
    }

}
