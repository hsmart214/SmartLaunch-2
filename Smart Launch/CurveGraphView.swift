//
//  CurveGraphView.swift
//  Smart Launch
//
//  Created by J. HOWARD SMART on 6/17/17.
//  Copyright © 2017 J. HOWARD SMART. All rights reserved.
//

import UIKit

protocol CurveGraphViewDelegate{
    func shouldDisplayMachOneLine() -> Bool
    func numberOfVerticalDivisions() -> Int
}
protocol CurveGraphViewDatasource{
    func dataValueRange() -> CGFloat
    func dataValueMinimumValue() -> CGFloat
    func timeValueRange() -> CGFloat
    func dataValueFor(timeIndex : CGFloat) -> CGFloat
}

class CurveGraphView: UIView {
    
    struct Const{
        static let widthFraction : CGFloat = 0.8
        static let secOffset : CGFloat = 7.0
        static let maxHorizDivs : CGFloat = 20.0
    }

    var delegate : CurveGraphViewDelegate?
    var dataSource : CurveGraphViewDatasource?
    
    var hrange : CGFloat {
        get{
            if _hrange == 0.0{
                let btime = dataSource?.timeValueRange() ?? 0.0
                _hrange = CGFloat(ceil(Double(btime)))
                hStepSize = 1.0
                if btime > Const.maxHorizDivs{
                    hStepSize = 2.0
                }
            }
            return _hrange
        }
    }
    var _hrange : CGFloat = 0.0
    var vrange : CGFloat {
        get{
            if _vrange == 0.0{
                let fmax = Double((dataSource?.dataValueRange() ?? 0.0) - (dataSource?.dataValueMinimumValue() ?? 0.0))
                if fmax == 0.0{
                    return 0.0
                }else{
                    let ex = floor(log10(fmax))
                    let mag = pow(10.0, ex)
                    let mant = fmax/mag
                    _vrange = CGFloat(ceil(mant * 10.0)/10.0)
                    fullrange = _vrange * CGFloat(mag)
                }
            }
            return _vrange
        }
    }
    var _vrange : CGFloat = 0.0
    var fullrange : CGFloat = 0.0
    var verticalUnits : String = "N"
    var verticalUnitsFormat = "%1.0f %@"
    var verticalDivisions : Int {
        get{
            return delegate?.numberOfVerticalDivisions() ?? Int(CURVEGRAPHVIEW_DEFAULT_VERTICAL_DIVISIONS)
        }
    }
    var hStepSize : CGFloat = 0.0
    var timeSlice : CGFloat {
        get {
            return hrange / frame.size.width * Const.widthFraction
        }
    }
    
    func setVerticalUnits(_ units: String, withFormatString formatString: String){
        verticalUnits = units
        verticalUnitsFormat = "\(formatString) %@"
    }
    
    func resetAxes(){
        _hrange = 0.0;
        _vrange = 0.0;
    }
    
    override func draw(_ rect: CGRect) {
        if dataSource == nil{
            return
        }
        let tmax = dataSource!.timeValueRange()
        let fmax = dataSource!.dataValueRange()
        if tmax * fmax == 0.0{
            return
        }
        let fmin = dataSource!.dataValueMinimumValue()
        let graphWidth = bounds.size.width * Const.widthFraction
        let margin = (bounds.size.width - graphWidth) / 2.0
        let graphHeight = bounds.size.height - 2*margin;
        let origin = CGPoint(x: margin, y: bounds.size.height - margin);
        let hscale = hrange == 0.0 ? 0.0 : graphWidth/hrange;
        let vscale = (vrange == 0.0) ? 0.0 : graphHeight/vrange;
        let ppp = UIScreen.main.scale;
        
        // draw the axes
        
        let path = UIBezierPath()
        path.lineWidth = 1.5
        UIColor.black.setStroke()
        path.move(to: origin)
        path.addLine(to: CGPoint(x:origin.x, y:margin))
        path.move(to: origin)
        path.addLine(to: CGPoint(x:origin.x+graphWidth, y:origin.y))
        path.stroke()
    
        path.removeAllPoints()
        
        // if fmin is not zero (as on accel graph) add a x axis line
        
        if fmin < 0.0{
            let ex = floor(log10(fmax-fmin))
            let mant = 1.0/pow(10.0, ex)
            let yValue = origin.y - mant * vscale
            path.move(to: CGPoint(x:origin.x, y:yValue))
            path.addLine(to: CGPoint(x:origin.x + graphWidth, y:yValue))
            path.stroke()
            path.removeAllPoints()
        }
        
        // if the delegate wants us to draw a mach one line, do so
        
        if delegate!.shouldDisplayMachOneLine() && fmax >= 1.0{
            let ex = fmax - fmin <= 0.0 ? 0.0 : floor(log10(fmax - fmin))
            let mant = 1.0/pow(10.0, ex)
            let yValue = origin.y - mant * vscale
            SLCustomUI.machLineColor().setStroke()
            path.move(to: CGPoint(x:origin.x, y:yValue))
            path.addLine(to: CGPoint(x:origin.x + graphWidth, y:yValue))
            path.stroke()
            path.removeAllPoints()
        }
        
        // draw the hash grid, and seconds along x axis
        
        path.lineWidth = 1.0
        UIColor.lightGray.setStroke()
        
        for i in 1..<verticalDivisions{
            let ind = CGFloat(i)
            let yOffset = (vrange/CGFloat(verticalDivisions))*vscale
            path.move(to: CGPoint(x: origin.x + 1.0,y: origin.y - ind*yOffset))
            path.addLine(to: CGPoint(x: origin.x + graphWidth,y: origin.y - ind*yOffset))
        }
        var i = hStepSize
        while i <= floor(hrange){
            path.move(to: CGPoint(x: origin.x + i*hscale, y: origin.y - 1.0))
            path.addLine(to: CGPoint(x:origin.x+i*hscale, y:margin))
            let sec = "\(Int(i))"
            let attSec = NSAttributedString(string: sec,
                                            attributes: [NSForegroundColorAttributeName:SLCustomUI.graphTextColor(),
                                                         NSFontAttributeName: UIFont.systemFont(ofSize: 10.0)])
            let secPt = CGPoint(x:origin.x + i*hscale - 3, y:origin.y + Const.secOffset)
            attSec.draw(at: secPt)
            i += hStepSize
        }
        path.stroke()
        path.removeAllPoints()
        
        // add the notation of the max at the top of the y axis
        
        let maxValueNotation = String(format: verticalUnitsFormat, fullrange, verticalUnits)
        let notation = NSAttributedString(string: maxValueNotation, attributes: [NSForegroundColorAttributeName:SLCustomUI.graphTextColor(),
                                                                                 NSFontAttributeName:UIFont.systemFont(ofSize: 10.0)])
        notation.draw(at: CGPoint(x:10.0,y:10.0))
        
        // draw the curve itself
        path.lineWidth = 2.0
        SLCustomUI.curveGraphCurveColor().setStroke()
        // The next four lines correct the starting point if the graph's 0,0 origin is not in the lower left corner
        let ex = floor(log10(fmax-fmin))
        let mant = -fmin/pow(10.0, ex)
        let yValue = origin.y - mant * vscale
        path.move(to: CGPoint(x: origin.x, y:yValue))
        
        var time : CGFloat = 0.0
        let incr = 1.0/(ppp*hscale)
        
        while time < tmax{
            time += incr
            let datum = dataSource!.dataValueFor(timeIndex: time) - fmin
            let ex = fmax - fmin <= 0.0 ? 0.0 : floor(log10(fmax - fmin))
            let mant = datum/pow(10.0,ex)
            let yValue = origin.y - mant * vscale
            let xValue = origin.x + time * hscale
            path.addLine(to: CGPoint(x:xValue, y:yValue))
        }
        path.stroke()
    }

}
