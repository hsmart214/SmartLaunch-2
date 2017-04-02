//
//  PhysicsModel.swift
//  Smart Launch
//
//  Created by J. HOWARD SMART on 3/31/17.
//  Copyright © 2017 J. HOWARD SMART. All rights reserved.
//

import Foundation

struct FlightDataPoint{
    var time : Double = 0.0
    var alt : Double = 0.0
    var trav : Double = 0.0
    var vel : Double = 0.0
    var accel :Double = 0.0
    var mach : Double = 0.0
    var drag : Double = 0.0
}

struct  CurrentEnvironment{
    var altMSL : Double
    var pressure : Double
    var rho_ratio : Double
    var mach_one : Double
}


@objc public protocol PhysicsModelDatasource : class{
    func hasValidData() -> Bool
    func quickFFVelocityAt(launchAngle: Float, andGuideLength: Float) -> Float
    func rocketName() -> String
    func burnoutVelocity() -> Float
    func maxVelocity() -> Float
    func maxAcceleration() -> Float
    func maxDeceleration() -> Float
    func maxDrag() -> Float
    func coastTime() -> Float
    func apogeeAltitude() -> Float
    func maxMachNumber() -> Float
    func totalTime() -> Float
    func dataAt(time:Float) -> SLFlightDataPoint
    func motorDescription() -> String
}

final class PhysicsModel : NSObject, PhysicsModelDatasource{
    var launchGuideLength : Double = 2.0
    var launchGuideAngle : Double = 0.0 {
        didSet{
            let limit = Double(MAX_LAUNCH_GUIDE_ANGLE)
            if launchGuideAngle > limit{
                launchGuideAngle = limit
            }else if launchGuideAngle < -limit{
                launchGuideAngle = -limit
            }
        }
    }
    var launchGuideDirection : LaunchDirection = CrossWind
    var windVelocity : Double = 0.0
    weak var rocket : Rocket? = nil{
        didSet{
            resetFlight()
        }
    }
    var launchAltitude : Double {
        get{
            return 0.0
        }
    }
    var version : Double {
        get {
            return SMART_LAUNCH_VERSION
        }
    }
    var topAltitude : Double = 0.0
    var currentStdAtmSegment : Int = 0
    var currentStdAtmBaseAlt : Double = 0.0
    var currentStdAtmCeilingAlt : Double = 0.0
    var currentBaseRhoRatio : Double = 0.0
    var currentCeilingRhoRatio : Double = 0.0
    var currentBaseMach : Double = 0.0
    var currentCeilingMach : Double = 0.0
    
    /* This is the opposing acceleration from gravity, the component of g along the axis of the launch guide */
    var altitude : Double = 0.0      // y component of the rocket's position
    var travel : Double = 0.0        // x component of the rocket's position
    var velocity : Double = 0.0      // magnitude of the rocket's velocity vector
    var machNumber : Double = 0.0
    var brnoutVelocity : Double = 0.0
    var timeIndex : Double = 0.0
    var _maxValues : FlightDataPoint?
    var _flightProfile = [FlightDataPoint]()
    var flightProfile : [FlightDataPoint]{
        get{
            if _flightProfile.count != 0{
                return _flightProfile
            }else{
                topAltitude = stdAtmosphere.last!.altMSL
                currentStdAtmSegment = 0
                currentStdAtmBaseAlt = 0.0
                currentStdAtmCeilingAlt = stdAtmosphere[1].altMSL
                currentBaseMach = stdAtmosphere[0].mach_one
                currentCeilingMach = stdAtmosphere[1].mach_one
                currentBaseRhoRatio = stdAtmosphere[0].rho_ratio
                currentCeilingRhoRatio = stdAtmosphere[1].rho_ratio
                integrateToEndOfLaunchGuide()
                integrateToBurnout()
                integrateBurnoutToApogee()
                return _flightProfile
            }
        }
    }
    var _stdAtmosphere = [CurrentEnvironment]()
    var stdAtmosphere : [CurrentEnvironment]{
        get{
            if _stdAtmosphere.count != 0{
                return _stdAtmosphere
            }else{
                var build = [CurrentEnvironment]()
                let mainBundle = Bundle.main
                if let atmosphereURL = mainBundle.url(forResource: "atmosphere", withExtension: "txt"){
                    do{
                        let atmosphere = try String(contentsOf: atmosphereURL)
                        var textLines = atmosphere.components(separatedBy: CharacterSet(charactersIn:"\n\r"))
                        while textLines.count > 0 {
                            if !textLines[0].hasPrefix(";"){
                                let inputLine = textLines[0].components(separatedBy: "\t")
                                let stratification = CurrentEnvironment(altMSL: Double(inputLine[0])!,
                                                                        pressure: Double(inputLine[1])!,
                                                                        rho_ratio: Double(inputLine[2])!,
                                                                        mach_one: Double(inputLine[3])!)
                                build.append(stratification)
                            }
                            textLines.removeFirst()
                        }
                    } catch {
                        Swift.print("Error reading atmosphere.txt")
                    }
                    _stdAtmosphere = build
                }
                return _stdAtmosphere
            }
        }
    }
    var angle : Double = 0.0         // current 2D angle of flight


    /* The first public method returns the velocity that the rocket will attain at the end of the launch guide */
    
    func velocityAtEndOfLaunchGuide() -> Double{
        if liftMass() == 0.0{
            return 0.0
        }
        let altitudeAtEndOfLaunchGuide : Double = launchGuideLength * cos(launchGuideAngle)
        return velocityAt(altitude: altitudeAtEndOfLaunchGuide)
    }
    
    /* This will give the resulting angle of attack of the rocket in the air mass at when it leaves the launch guide */
    
    func freeFlightAngleOfAttack() -> Double{         // AOA when the rocket leaves the launch guide - RADIANS
        if liftMass() == 0.0{
            return 0.0
        }
        let velocity = velocityAtEndOfLaunchGuide()
        var alpha1, alpha2, opposite, adjacent : Double
        switch launchGuideDirection {
        case CrossWind:
            return asin(windVelocity/velocity)
        case WithWind:
            alpha1 = launchGuideAngle
            opposite = velocity*sin(alpha1)-windVelocity
            adjacent = velocity*cos(alpha1)
            alpha2 = atan(opposite/adjacent)
            return alpha1-alpha2
        case IntoWind:
            alpha1 = launchGuideAngle
            opposite = velocity*sin(alpha1)+windVelocity
            adjacent = velocity*cos(alpha1)
            alpha2 = atan(opposite/adjacent)
            return alpha2-alpha1
        default:
            return 0.0
        }
    }
    
    func velocityAt(altitude alt:Double) -> Double{   // from the profile, returns the velocity (METERS/SEC) at a given altitude (METERS)
        if alt < 0{
            return 0.0
        }
        var stop_counter : Int = -1
        for counter in 0...flightProfile.count{
            if flightProfile[counter].alt > alt{
                stop_counter = counter
                break
            }
        }
        if stop_counter == -1{
            return 0.0
        }
        let curPoint = flightProfile[stop_counter]
        let prevPoint : FlightDataPoint
        if stop_counter == 0{
            prevPoint = FlightDataPoint()
        }else{
            prevPoint = flightProfile[stop_counter-1]
        }
        let v0 = prevPoint.vel
        let v1 = curPoint.vel
        let d0 = prevPoint.alt
        let d1 = curPoint.alt
        let slope = (v1-v0)/(d1-d0)
        return v0 + slope * (alt - d0)
    }
    
    func resetFlight(){                        // reset the flight profile
        _flightProfile.removeAll()
        _maxValues = nil
    }
    
    func fastApogee() -> Float{                       // to be used in the estimations for calculating the best Cd
        return apogeeAltitude()
    }
    
    func burnoutToApogee() -> Float{                  // SECONDS from burnout to apogee - the ideal motor delay
        return totalTime() - rocket!.burnoutTime()
    }
    
    func hasValidData() -> Bool {
        return flightProfile.count > 0
    }
    
    func atmosphereDataAt(altitudeAGL altAGL : Double) -> CurrentEnvironment{
        let altMSL  = altAGL + launchAltitude
        if altMSL > topAltitude{
            return stdAtmosphere.last!
        }else{
            if altMSL > currentStdAtmCeilingAlt{ // rachet up the atmosphere ladder
                currentStdAtmSegment += 1
                if currentStdAtmSegment == stdAtmosphere.count{
                    return stdAtmosphere.last!
                }
                currentStdAtmBaseAlt = currentStdAtmCeilingAlt
                currentStdAtmCeilingAlt = stdAtmosphere[currentStdAtmSegment + 1].altMSL
                currentBaseRhoRatio = currentCeilingRhoRatio
                currentCeilingRhoRatio = stdAtmosphere[currentStdAtmSegment + 1].rho_ratio
                currentBaseMach = currentCeilingMach
                currentCeilingMach = stdAtmosphere[currentStdAtmSegment + 1].mach_one
            }
            let fraction  = (altMSL - currentStdAtmBaseAlt) / (currentStdAtmCeilingAlt - currentStdAtmBaseAlt)
            let rho_ratio = fraction * (currentCeilingRhoRatio - currentBaseRhoRatio) + currentBaseRhoRatio
            let mach_one = fraction * (currentCeilingMach - currentBaseMach) + currentBaseMach
            return CurrentEnvironment(altMSL: altMSL,
                                         pressure: 0.0,
                                         rho_ratio: rho_ratio,
                                         mach_one: mach_one)
        }
    }
    
    func dragAt(velocity v: Double, time : Double, andAltitude altAGL: Double) -> Double{
        if v == 0.0 || rocket == nil{
            return 0.0
        }
        let atmosphereData = atmosphereDataAt(altitudeAGL: altAGL)
        let rho = Double(STANDARD_RHO) * atmosphereData.rho_ratio
        let cd = Double(rocket!.cd(atTime: Float(time)))
        let mach = v / atmosphereData.mach_one
        machNumber = mach
        var ccd : Double
        if mach < 0.9{
            ccd = cd
        }else if mach < 1.0{
            ccd = cd * 2.0 * (mach - 0.8) / (1.0 - 0.8)
        }else if mach < 1.2{
            ccd = cd * (2.0 - ((mach - 1.0) / (1.2 - 1.0)))
        }else{
            ccd = cd
        }
        let area = Double(rocket!.area(atTime: Float(time)))
        return 0.5*rho*v*v*ccd*area
    }
    
    func liftMass() -> Float{
        if let r = rocket{
            return r.mass(atTime: 0.0)
        }else{
            return 1.0
        }
    }
    
    func integrateToEndOfLaunchGuide(){
        if rocket == nil{
            return
        }
        altitude = 0.0
        travel = 0.0
        velocity = 0.0
        timeIndex = 0.0
        var totalDistanceTravelled : Double = 0.0
        var distanceTravelled : Double = 0.0
        let g = Double(GRAV_ACCEL) * cos(launchGuideAngle)
        let dt = 1.0/Double(DIVS_DURING_BURN)
        
        while totalDistanceTravelled < Double(launchGuideLength){
            timeIndex += dt
            let mass = Double(rocket!.mass(atTime: Float(timeIndex)))
            let drag = dragAt(velocity: velocity, time: timeIndex, andAltitude: altitude)
            var a = Double(rocket!.thrust(atTime: Float(timeIndex)))/mass - g - drag/mass
            if a > 0.0{
                distanceTravelled = velocity * dt + 0.5  * a * dt * dt
                altitude += distanceTravelled * cos(Double(launchGuideAngle))
                travel += distanceTravelled * sin(Double(launchGuideAngle))
                velocity += a * dt
            }else{
                a = 0.0
            }
            let dataPoint = FlightDataPoint(time: timeIndex,
                                            alt: altitude,
                                            trav: travel,
                                            vel: velocity,
                                            accel: a,
                                            mach: machNumber,
                                            drag: drag)
            _flightProfile.append(dataPoint)
            totalDistanceTravelled += distanceTravelled
            if Float(timeIndex) >= rocket!.burnoutTime() && velocity <= 0.0{
                break
            }
        }
    }
    func integrateToBurnout(){
        if Float(timeIndex) >= rocket!.burnoutTime() && velocity <= 0.0{
            return
        }
        if rocket == nil{
            return
        }
        angle = launchGuideAngle
        let dt = 1.0/Double(DIVS_DURING_BURN)
        let dt_sq = dt * dt
        let burnoutTime = Double(rocket!.burnoutTime())
        while timeIndex <= burnoutTime{
            timeIndex += dt
            let g = Double(GRAV_ACCEL) * cos(angle)
            let mass = Double(rocket!.mass(atTime: Float(timeIndex)))
            let drag = dragAt(velocity: velocity, time: timeIndex, andAltitude: altitude)
            let acc = Double(rocket!.thrust(atTime: Float(timeIndex)))/mass - drag/mass
            
            let y_accel = acc * cos(angle) - Double(GRAV_ACCEL)
            let x_accel = acc * sin(angle)
            let y_dist = velocity * cos(angle) * dt + 0.5 * y_accel * dt_sq
            let x_dist = velocity * sin(angle) * dt + 0.5 * x_accel * dt_sq
            altitude += y_dist
            travel += x_dist
            velocity += (acc - g) * dt
            angle = atan(x_dist/y_dist)
            
            let dataPoint = FlightDataPoint(time: timeIndex,
                                            alt: altitude,
                                            trav: travel,
                                            vel: velocity,
                                            accel: acc,
                                            mach: machNumber,
                                            drag: drag)
            _flightProfile.append(dataPoint)
        }
        brnoutVelocity = velocity
    }
    func integrateBurnoutToApogee(){
        if Float(timeIndex) >= rocket!.burnoutTime() && velocity <= 0.0{
            return
        }
        if rocket == nil{
            return
        }
        let dt = 1.0/Double(DIVS_AFTER_BURNOUT)
        let dt_sq = dt * dt
        let mass = Double(rocket!.burnoutMass())
        var deltaAlt = Double(1.0)
        while deltaAlt > 0.0{
            let g = Double(GRAV_ACCEL) * cos(angle)
            timeIndex += dt
            let drag = dragAt(velocity: velocity, time: timeIndex, andAltitude: altitude)
            let acc = -drag/mass
            let y_accel = acc * cos(angle) - Double(GRAV_ACCEL)
            let x_accel = acc * sin(angle)
            let y_dist = velocity * cos(angle) * dt + 0.5 * y_accel * dt_sq
            let x_dist = velocity * sin(angle) * dt + 0.5 * x_accel * dt_sq
            altitude += y_dist
            deltaAlt = y_dist
            travel += x_dist
            velocity += (acc - g) * dt
            angle = atan(x_dist/y_dist)
            
            let dataPoint = FlightDataPoint(time: timeIndex,
                                            alt: altitude,
                                            trav: travel,
                                            vel: velocity,
                                            accel: acc,
                                            mach: machNumber,
                                            drag: drag)
            _flightProfile.append(dataPoint)
        }
    }
    
    var maxValues : FlightDataPoint{
        get{
            if let mv = _maxValues{
                return mv
            }else{
                var mv = FlightDataPoint()
                for dp in flightProfile{
                    if dp.alt > mv.alt{
                        mv.alt = dp.alt
                    }
                    if dp.vel > mv.vel{
                        mv.vel = dp.vel
                    }
                    if dp.trav > mv.trav{
                        mv.trav = dp.trav
                    }
                    if dp.accel > mv.accel{
                        mv.accel = dp.accel
                    }
                    if dp.mach > mv.mach{
                        mv.mach = dp.mach
                    }
                    if dp.drag > mv.drag{
                        mv.drag = dp.drag
                    }
                }
                _maxValues = mv
                return mv
            }
        }
    }
    
    func rocketName() -> String{
        return rocket?.name ?? ""
    }
    
    func motorDescription() -> String {
        return rocket?.motorDescription ?? ""
    }
    
    func apogeeAltitude() -> Float {
        if let dp = flightProfile.last{
            return Float(dp.alt)
        }else{
            return 0.0
        }
    }
    
    func coastTime() -> Float {
        return burnoutToApogee()
    }
    
    func totalTime() -> Float {
        if let dp = flightProfile.last{
            return Float(dp.time)
        }else{
            return 0.0
        }
    }
    
    func burnoutVelocity() -> Float {
        return Float(brnoutVelocity)
    }
    
    func maxDrag() -> Float {
        return Float(maxValues.drag)
    }
    
    func maxVelocity() -> Float {
        return Float(maxValues.vel)
    }
    
    func maxMachNumber() -> Float {
        return Float(maxValues.mach)
    }
    
    func maxAcceleration() -> Float {
        return Float(maxValues.accel)
    }
    
    func maxDeceleration() -> Float {
        var decelMax = Double(0.0)
        for dp in flightProfile{
            if dp.accel < decelMax{
                decelMax = dp.accel
            }
        }
        return Float(decelMax)
    }
    
    func dataIndexFor(timeIndex: Double) -> Int{
        var pivot : Int = flightProfile.count/2
        var move : Int = pivot/2
        while move > 1{
            let dp = flightProfile[pivot]
            let time = dp.time
            if time > timeIndex{
                pivot -= move
                move /= 2
            }else{
                pivot += move
                move /= 2
            }
        }
        return pivot
    }
    
    func dataAt(time: Float) -> SLFlightDataPoint{
        let t = Double(time)
        let dp = flightProfile[dataIndexFor(timeIndex: t)]
        let sldp = SLFlightDataPoint()
        sldp.updateTime(t, velocity: dp.vel, altitude: dp.alt, travel: dp.trav, accel: dp.accel, mach: dp.mach, andDrag: dp.drag)
        return sldp
    }
    
    func quickFFVelocityAt(launchAngle angle: Float, andGuideLength length: Float) -> Float {
        let len = Double(length)
        let g = Double(GRAV_ACCEL) * cos(Double(angle))
        let dt = 1.0/Double(DIVS_DURING_BURN)
        let dt_sq = dt * dt
        var dist : Double = 0.0
        var timeDex : Double = 0.0
        var v : Double = 0.0
        while dist < len{
            timeDex += dt
            let mass = Double(rocket!.mass(atTime: Float(timeDex)))
            let a = Double(rocket!.thrust(atTime: Float(timeDex)))/mass - g - dragAt(velocity: v, time: timeDex, andAltitude: dist)
            if a > 0.0{
                dist += v * dt + 0.5 * a * dt_sq
                v += a * dt
            }
        }
        return Float(v)
    }
    
}
