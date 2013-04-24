//
//  SLUnitsConvertor.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/30/12.
//  Copyright (c) 2012 All rights reserved.
//

#import "SLUnitsConvertor.h"

@implementation SLUnitsConvertor

static SLUnitsConvertor *sUnitsConvertor;

+(void)initialize{
    NSAssert(self == [SLUnitsConvertor class], @"SLUnitsConvertor is not meant to be subclassed");
    sUnitsConvertor = [SLUnitsConvertor new];
}

+(SLUnitsConvertor *)sharedUnitsConvertor{
    return sUnitsConvertor;
}

+(NSString *)defaultUnitForKey:(NSString *)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *unitDefaults = [defaults objectForKey:UNIT_PREFS_KEY];
    return unitDefaults[key];
}

+(void)setDefaultUnit:(NSString *)unit forKey:(NSString *)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *unitDefaults = [[defaults objectForKey:UNIT_PREFS_KEY] mutableCopy];
    unitDefaults[key] = unit;
    [defaults setObject:unitDefaults forKey:UNIT_PREFS_KEY];
    [defaults synchronize];
}

#pragma mark - Class Methods
// measurements of the rocket (and motor) will always be stored in the metric units used for calculations
// but the user can ask to see them in US or non-standard units if desired
// This class method can be called to convert a dimension from the displayed units back to the metric for storage
// [SLUnitsConvertor metricStandardOf: [self.motorDiamLabel.text floatValue] forKey: MOTOR_SIZE_UNIT_KEY];
+(float)metricStandardOf:(float)dimension forKey:(NSString *)dimKey{
    NSDictionary *standards = @{LENGTH_UNIT_KEY: K_METERS,
                               DIAM_UNIT_KEY: K_METERS,
                               MOTOR_SIZE_UNIT_KEY: K_MILLIMETERS,
                               MASS_UNIT_KEY: K_KILOGRAMS,
                               TEMP_UNIT_KEY: K_CELSIUS,
                               VELOCITY_UNIT_KEY: K_METER_PER_SEC,
                               ALT_UNIT_KEY: K_METERS,
                               THRUST_UNIT_KEY: K_NEWTONS,
                               ACCEL_UNIT_KEY: K_M_PER_SEC_SQ,
                               MACH_UNIT_KEY: K_MACH};
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *unitPrefs = [defaults objectForKey:UNIT_PREFS_KEY];
    
    if ([unitPrefs[dimKey] isEqualToString: standards[dimKey]]) return dimension;
    
    if ([dimKey isEqualToString:LENGTH_UNIT_KEY]){      // standard is METERS
        if ([unitPrefs[dimKey] isEqualToString:K_FEET]){
            return dimension / FEET_PER_METER;
        }
        if ([unitPrefs[dimKey] isEqualToString:K_INCHES]){
            return dimension / (12 * FEET_PER_METER);
        }
        if ([unitPrefs[dimKey] isEqualToString:K_CENTIMETERS]){
            return dimension / 100;
        }
        if ([unitPrefs[dimKey] isEqualToString:K_MILLIMETERS]){   // who would do this??
            return dimension / 1000;
        }
    }
    if ([dimKey isEqualToString:DIAM_UNIT_KEY]){    // standard is METERS
        if ([unitPrefs[dimKey] isEqualToString:K_FEET]){          // seriously??
            return dimension / FEET_PER_METER;
        }
        if ([unitPrefs[dimKey] isEqualToString:K_INCHES]){
            return dimension / (12 * FEET_PER_METER);
        }
        if ([unitPrefs[dimKey] isEqualToString:K_CENTIMETERS]){   // not widely used
            return dimension / 100;
        }
        if ([unitPrefs[dimKey] isEqualToString:K_MILLIMETERS]){
            return dimension / 1000;
        }
    }
    if ([dimKey isEqualToString:MASS_UNIT_KEY]){         // standard is KILOGRAMS - others may be used frequently
        if ([unitPrefs[dimKey] isEqualToString:K_GRAMS]){
            return dimension / 1000;
        }
        if ([unitPrefs[dimKey] isEqualToString:K_POUNDS]){
            return dimension/ POUNDS_PER_KILOGRAM;
        }
        if ([unitPrefs[dimKey] isEqualToString:K_OUNCES]){
            return dimension / OUNCES_PER_KILOGRAM;
        }
    }
    if ([dimKey isEqualToString:TEMP_UNIT_KEY]){    // standard is CELSIUS
        if ([unitPrefs[dimKey] isEqualToString:K_FAHRENHEIT]){
            return (dimension-32)/1.8;
        }else{//must be Kelvin
            return dimension - ABSOLUTE_ZERO_CELSIUS;
        }
    }
    if ([dimKey isEqualToString:VELOCITY_UNIT_KEY]){    //standard is METERS / SEC
        if ([unitPrefs[dimKey]isEqualToString:K_MILES_PER_HOUR]){
            return dimension * MPH_TO_M_PER_SEC;
        }else{// must be FEET PER SEC
            return dimension / FEET_PER_METER;
        }
    }
    if ([dimKey isEqualToString:ALT_UNIT_KEY]){    //standard is METERS
        if ([unitPrefs[dimKey]isEqualToString:K_FEET]){
            return dimension / FEET_PER_METER;
        }
    }
    if ([dimKey isEqualToString:ACCEL_UNIT_KEY]){   //standard is METERS PER SEC^2
        if ([unitPrefs[dimKey] isEqualToString:K_GRAVITIES]){
            return dimension * GRAV_ACCEL;
        }
    }
    if ([dimKey isEqualToString:THRUST_UNIT_KEY]){   //standard is NEWTONS
        if ([unitPrefs[dimKey] isEqualToString:K_POUNDS]){
            return dimension * NEWTONS_PER_POUND;
        }
    }
    return dimension;
}

// and here is the inverse function to turn the measurement back into display units
// [LSRUnitsViewController displayUnitsOf: [self.rocket.mass floatValue] forKey: MASS_UNIT_KEY];
+(float)displayUnitsOf:(float)dimension forKey:(NSString *)dimKey{
    NSDictionary *standards = @{LENGTH_UNIT_KEY: K_METERS, 
                               DIAM_UNIT_KEY: K_METERS,
                               MOTOR_SIZE_UNIT_KEY: K_MILLIMETERS, 
                               MASS_UNIT_KEY: K_KILOGRAMS, 
                               TEMP_UNIT_KEY: K_CELSIUS, 
                               VELOCITY_UNIT_KEY: K_METER_PER_SEC,
                               ALT_UNIT_KEY: K_METERS,
                               THRUST_UNIT_KEY: K_NEWTONS,
                               ACCEL_UNIT_KEY: K_M_PER_SEC_SQ};
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *unitPrefs = [defaults objectForKey:UNIT_PREFS_KEY];
    
    if ([unitPrefs[dimKey] isEqualToString: standards[dimKey]]) return dimension;
    
    if ([dimKey isEqualToString:LENGTH_UNIT_KEY]){      // standard is METERS
        if ([unitPrefs[dimKey] isEqualToString:K_FEET]){
            return dimension * FEET_PER_METER;
        }
        if ([unitPrefs[dimKey] isEqualToString:K_INCHES]){
            return dimension * (12 * FEET_PER_METER);
        }
        if ([unitPrefs[dimKey] isEqualToString:K_CENTIMETERS]){
            return dimension * 100;
        }
        if ([unitPrefs[dimKey] isEqualToString:K_MILLIMETERS]){   // who would do this??
            return dimension * 1000;
        }
    }
    if ([dimKey isEqualToString:DIAM_UNIT_KEY]){    // standard is METERS
        if ([unitPrefs[dimKey] isEqualToString:K_FEET]){          // seriously??
            return dimension * FEET_PER_METER;
        }
        if ([unitPrefs[dimKey] isEqualToString:K_INCHES]){
            return dimension * (12 * FEET_PER_METER);
        }
        if ([unitPrefs[dimKey] isEqualToString:K_CENTIMETERS]){   // not widely used
            return dimension * 100;
        }
        if ([unitPrefs[dimKey] isEqualToString:K_MILLIMETERS]){
            return dimension * 1000;
        }
    }
    if ([dimKey isEqualToString:MASS_UNIT_KEY]){         // standard is KILOGRAMS - others may be used frequently
        if ([unitPrefs[dimKey] isEqualToString:K_GRAMS]){
            return dimension * 1000;
        }
        if ([unitPrefs[dimKey] isEqualToString:K_POUNDS]){
            return dimension * POUNDS_PER_KILOGRAM;
        }
        if ([unitPrefs[dimKey] isEqualToString:K_OUNCES]){
            return dimension * OUNCES_PER_KILOGRAM;
        }
    }
    if ([dimKey isEqualToString:TEMP_UNIT_KEY]){
        if ([unitPrefs[dimKey] isEqualToString:K_FAHRENHEIT]){ //standard is CELSIUS
            return dimension * 1.8 + 32;
        }else if([unitPrefs[dimKey] isEqualToString:K_KELVINS]){
            return dimension + ABSOLUTE_ZERO_CELSIUS;
        }
    }
    if ([dimKey isEqualToString:VELOCITY_UNIT_KEY]){ //standard in METERS PER SECOND
        if ([unitPrefs[dimKey]isEqualToString:K_MILES_PER_HOUR]){
            return dimension / MPH_TO_M_PER_SEC;
        }else if ([unitPrefs[dimKey] isEqualToString:K_FEET_PER_SEC]){
            return dimension * FEET_PER_METER;
        }
    }
    if ([dimKey isEqualToString:ALT_UNIT_KEY]){ //standard is METERS
        if ([unitPrefs[dimKey] isEqualToString:K_FEET]){
            return dimension * FEET_PER_METER;
        }
    }
    if ([dimKey isEqualToString:THRUST_UNIT_KEY]){ //standard is NEWTONS
        if ([unitPrefs[dimKey] isEqualToString:K_POUNDS]){
            return dimension / NEWTONS_PER_POUND;
        }
    }
    if ([dimKey isEqualToString:ACCEL_UNIT_KEY]){   //standard is METERS PER SEC^2
        if ([unitPrefs[dimKey] isEqualToString:K_GRAVITIES]){
            return dimension / GRAV_ACCEL;
        }
    }
    return dimension;
}

+ (NSString *)displayStringForKey:(NSString *)dimKey{
    NSDictionary *displayStrings = @{K_CELSIUS: @"°C",
                                    K_FAHRENHEIT: @"°F", 
                                    K_CENTIMETERS: @"cm",
                                    K_FEET: @"ft",
                                    K_FEET_PER_SEC: @"fps",
                                    K_GRAMS: @"g",
                                    K_INCHES: @"in",
                                    K_KELVINS: @"K",
                                    K_KILOGRAMS: @"kg",
                                    K_METER_PER_SEC: @"m/s",
                                    K_METERS: @"m",
                                    K_MILES_PER_HOUR: @"MPH",
                                    K_MILLIMETERS: @"mm",
                                    K_NEWTONS: @"N",
                                    K_OUNCES: @"oz",
                                    K_POUNDS: @"lbs",
                                    K_M_PER_SEC_SQ: @"m/s^2",
                                    K_GRAVITIES: @"g",
                                    K_MACH: @""};
    NSString *preferredUnit = [SLUnitsConvertor defaultUnitForKey:dimKey];
    return displayStrings[preferredUnit];
}

@end
