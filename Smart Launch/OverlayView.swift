//
//  OverlayView.swift
//  SmartLaunch
//
//  Created by J. HOWARD SMART on 4/13/20.
//  Copyright © 2020 J. HOWARD SMART. All rights reserved.
//

import UIKit



class OverlayView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var angleLabel: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    private func commonInit(){
        Bundle.main.loadNibNamed("OverlayView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
    }
}
