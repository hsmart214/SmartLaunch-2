//
//  SLRocketsLaunchedTVC.swift
//  Smart Launch
//
//  Created by J. HOWARD SMART on 5/21/16.
//  Copyright © 2016 J. HOWARD SMART. All rights reserved.
//

import UIKit

class SLRocketsLaunchedTVC: UITableViewController {
    var rockets : [Rocket]?
    var nf : NumberFormatter?
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rockets?.count ?? 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Rocket Cell", for: indexPath)
        if let rocketCell = cell as? SLRocketImpulseCell{
            rocketCell.nf = nf
            rocketCell.rocket = rockets?[indexPath.row]
        }
        
        
        return cell
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dvc = segue.destination as? SLLaunchesTVC{
            if let senderCell = sender as? SLRocketImpulseCell{
                if let row = tableView.indexPath(for: senderCell)?.row{
                    dvc.rocket = rockets?[row]
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nf = NumberFormatter()
        nf?.usesGroupingSeparator = true
        nf?.numberStyle = .decimal
        nf?.maximumFractionDigits = 0
        
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
