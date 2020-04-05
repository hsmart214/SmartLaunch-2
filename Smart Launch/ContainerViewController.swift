//
//  ContainerViewController.swift
//  SmartLaunch
//
//  Created by J. HOWARD SMART on 4/3/20.
//  Copyright © 2020 J. HOWARD SMART. All rights reserved.
//

import UIKit

class ContainerViewController: UIViewController {

    weak var delegate : SLSimulationDelegate?
    weak var dataSource : SLSimulationDataSource?
    weak var modelDataSource : SLPhysicsModelDatasource?
    // TODO: Why are these two protocols different?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "embedThrustCurve":
            let dest = segue.destination as? SLClusterMotorViewController
            //dest?.delegate = self.delegate
            dest?.motorLoadoutPlist = self.modelDataSource?.motorLoadoutPlist()
        case "embedFlightProfile":
            let dest = segue.destination as? SLFlightProfileViewController
            dest?.dataSource = self.modelDataSource
        case "embedVectorView":
            let dest = segue.destination as? SLAnimatedViewController
            dest?.dataSource = self.dataSource
            dest?.delegate = self.delegate
        default:
            break
        }
    }

}
