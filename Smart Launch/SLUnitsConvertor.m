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
    return [unitDefaults objectForKey:key];
}

+(void)setDefaultUnit:(NSString *)unit forKey:(NSString *)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *unitDefaults = [[defaults objectForKey:UNIT_PREFS_KEY] mutableCopy];
    [unitDefaults setObject:unit forKey:key];
    [defaults setObject:unitDefaults forKey:UNIT_PREFS_KEY];
    [defaults synchronize];
}

#pragma mark - Class Methods
// measurements of the rocket (and motor) will always be stored in the metric units used for calculations
// but the user can ask to see them in US or non-standard units if desired
// This class method can be called to convert a dimension from the displayed units back to the metric for storage
// [SLUnitsConvertor metricStandardOf: [self.motorDiamLabel.text floatValue] forKey: MOTOR_SIZE_UNIT_KEY];
+(NSNumber *)metricStandardOf:(NSNumber *)dimension forKey:(NSString *)dimKey{
    NSDictionary *standards = [NSDictionary dictionaryWithObjectsAndKeys:
                               K_METERS,        LENGTH_UNIT_KEY,
                               K_METERS,        DIAM_UNIT_KEY,
                               K_MILLIMETERS,   MOTOR_SIZE_UNIT_KEY,
                               K_KILOGRAMS,     MASS_UNIT_KEY,
                               K_CELSIUS,       TEMP_UNIT_KEY,
                               K_METER_PER_SEC, VELOCITY_UNIT_KEY,
                               K_METERS,        ALT_UNIT_KEY,
                               K_NEWTONS,       THRUST_UNIT_KEY,
                               K_GRAVITIES,     ACCEL_UNIT_KEY,
                               K_MACH,          MACH_UNIT_KEY,
                               nil];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *unitPrefs = [defaults objectForKey:UNIT_PREFS_KEY];
    
    if ([[unitPrefs objectForKey:dimKey] isEqualToString: [standards objectForKey:dimKey ]]) return dimension;
    
    if ([dimKey isEqualToString:LENGTH_UNIT_KEY]){      // standard is METERS
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_FEET]){
            return [NSNumber numberWithFloat:[dimension floatValue] / FEET_PER_METER];
        }
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_INCHES]){
            return [NSNumber numberWithFloat:[dimension floatValue] / (12 * FEET_PER_METER)];
        }
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_CENTIMETERS]){
            return [NSNumber numberWithFloat:[dimension floatValue] / 100];
        }
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_MILLIMETERS]){   // who would do this??
            return [NSNumber numberWithFloat:[dimension floatValue] / 1000];
        }
    }
    if ([dimKey isEqualToString:DIAM_UNIT_KEY]){    // standard is METERS
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_FEET]){          // seriously??
            return [NSNumber numberWithFloat:[dimension floatValue] / FEET_PER_METER];
        }
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_INCHES]){
            return [NSNumber numberWithFloat:[dimension floatValue] / (12 * FEET_PER_METER)];
        }
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_CENTIMETERS]){   // not widely used
            return [NSNumber numberWithFloat:[dimension floatValue] / 100];
        }
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_MILLIMETERS]){
            return [NSNumber numberWithFloat:[dimension floatValue] / 1000];
        }
    }
    if ([dimKey isEqualToString:MASS_UNIT_KEY]){         // standard is KILOGRAMS - others may be used frequently
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_GRAMS]){
            return [NSNumber numberWithFloat:[dimension floatValue] / 1000];
        }
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_POUNDS]){
            return [NSNumber numberWithFloat:[dimension floatValue] / POUNDS_PER_KILOGRAM];
        }
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_OUNCES]){
            return [NSNumber numberWithFloat:[dimension floatValue] / OUNCES_PER_KILOGRAM];
        }
    }
    if ([dimKey isEqualToString:TEMP_UNIT_KEY]){    // standard is CELSIUS
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_FAHRENHEIT]){
            return [NSNumber numberWithFloat:([dimension floatValue]-32)/1.8];
        }else{//must be Kelvin
            return [NSNumber numberWithFloat:[dimension floatValue] - ABSOLUTE_ZERO_CELSIUS];
        }
    }
    if ([dimKey isEqualToString:VELOCITY_UNIT_KEY]){    //standard is METERS / SEC
        if ([[unitPrefs objectForKey:dimKey]isEqualToString:K_MILES_PER_HOUR]){
            return [NSNumber numberWithFloat:[dimension floatValue] * MPH_TO_M_PER_SEC];
        }else{// must be FEET PER SEC
            return [NSNumber numberWithFloat:[dimension floatValue] / FEET_PER_METER];
        }
    }
    if ([dimKey isEqualToString:ALT_UNIT_KEY]){    //standard is METERS
        if ([[unitPrefs objectForKey:dimKey]isEqualToString:K_FEET]){
            return [NSNumber numberWithFloat:[dimension floatValue] / FEET_PER_METER];
        }
    }
    if ([dimKey isEqualToString:ACCEL_UNIT_KEY]){   //standard is GRAVITIES
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_M_PER_SEC_SQ]){
            return @([dimension floatValue] / GRAV_ACCEL);
        }
    }
    return dimension;
}

// and here is the inverse function to turn the measurement back into display units
// [LSRUnitsViewController displayUnitsOf: [self.rocket.mass floatValue] forKey: MASS_UNIT_KEY];
+(NSNumber *)displayUnitsOf:(NSNumber *)dimension forKey:(NSString *)dimKey{
    NSDictionary *standards = [NSDictionary dictionaryWithObjectsAndKeys:
                               K_METERS,        LENGTH_UNIT_KEY, 
                               K_METERS,        DIAM_UNIT_KEY,
                               K_MILLIMETERS,   MOTOR_SIZE_UNIT_KEY, 
                               K_KILOGRAMS,     MASS_UNIT_KEY, 
                               K_CELSIUS,       TEMP_UNIT_KEY, 
                               K_METER_PER_SEC, VELOCITY_UNIT_KEY,
                               K_METERS,        ALT_UNIT_KEY,
                               K_NEWTONS,       THRUST_UNIT_KEY,
                               K_GRAVITIES,     ACCEL_UNIT_KEY,
                               nil];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *unitPrefs = [defaults objectForKey:UNIT_PREFS_KEY];
    
    if ([[unitPrefs objectForKey:dimKey] isEqualToString: [standards objectForKey:dimKey]]) return dimension;
    
    if ([dimKey isEqualToString:LENGTH_UNIT_KEY]){      // standard is METERS
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_FEET]){
            return [NSNumber numberWithFloat:[dimension floatValue] * FEET_PER_METER];
        }
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_INCHES]){
            return [NSNumber numberWithFloat:[dimension floatValue] * (12 * FEET_PER_METER)];
        }
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_CENTIMETERS]){
            return [NSNumber numberWithFloat:[dimension floatValue] * 100];
        }
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_MILLIMETERS]){   // who would do this??
            return [NSNumber numberWithFloat:[dimension floatValue] * 1000];
        }
    }
    if ([dimKey isEqualToString:DIAM_UNIT_KEY]){    // standard is METERS
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_FEET]){          // seriously??
            return [NSNumber numberWithFloat:[dimension floatValue] * FEET_PER_METER];
        }
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_INCHES]){
            return [NSNumber numberWithFloat:[dimension floatValue] * (12 * FEET_PER_METER)];
        }
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_CENTIMETERS]){   // not widely used
            return [NSNumber numberWithFloat:[dimension floatValue] * 100];
        }
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_MILLIMETERS]){
            return [NSNumber numberWithFloat:[dimension floatValue] * 1000];
        }
    }
    if ([dimKey isEqualToString:MASS_UNIT_KEY]){         // standard is KILOGRAMS - others may be used frequently
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_GRAMS]){
            return [NSNumber numberWithFloat:[dimension floatValue] * 1000];
        }
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_POUNDS]){
            return [NSNumber numberWithFloat:[dimension floatValue] * POUNDS_PER_KILOGRAM];
        }
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_OUNCES]){
            return [NSNumber numberWithFloat:[dimension floatValue] * OUNCES_PER_KILOGRAM];
        }
    }
    if ([dimKey isEqualToString:TEMP_UNIT_KEY]){
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_FAHRENHEIT]){ //standard is CELSIUS
            return [NSNumber numberWithFloat:[dimension floatValue] * 1.8 + 32];
        }else if([[unitPrefs objectForKey:dimKey] isEqualToString:K_KELVINS]){
            return [NSNumber numberWithFloat:[dimension floatValue] + ABSOLUTE_ZERO_CELSIUS];
        }
    }
    if ([dimKey isEqualToString:VELOCITY_UNIT_KEY]){ //standard in METERS PER SECOND
        if ([[unitPrefs objectForKey:dimKey]isEqualToString:K_MILES_PER_HOUR]){
            return [NSNumber numberWithFloat:[dimension floatValue] / MPH_TO_M_PER_SEC];
        }else if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_FEET_PER_SEC]){
            return [NSNumber numberWithFloat:[dimension floatValue] * FEET_PER_METER];
        }
    }
    if ([dimKey isEqualToString:ALT_UNIT_KEY]){ //standard is METERS
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_FEET]){
            return [NSNumber numberWithFloat:[dimension floatValue] * FEET_PER_METER];
        }
    }
    if ([dimKey isEqualToString:THRUST_UNIT_KEY]){ //standard is NEWTONS
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_POUNDS]){
            return [NSNumber numberWithFloat:[dimension floatValue] * POUNDS_PER_KILOGRAM * GRAV_ACCEL];
        }
    }
    if ([dimKey isEqualToString:ACCEL_UNIT_KEY]){   //standard is GRAVITIES
        if ([[unitPrefs objectForKey:dimKey] isEqualToString:K_M_PER_SEC_SQ]){
            return @([dimension floatValue] * GRAV_ACCEL);
        }
    }
    return dimension;
}

+ (NSString *)displayStringForKey:(NSString *)dimKey{
    NSDictionary *displayStrings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"°C", K_CELSIUS,
                                    @"°F", K_FAHRENHEIT, 
                                    @"cm", K_CENTIMETERS,
                                    @"ft", K_FEET,
                                    @"fps", K_FEET_PER_SEC,
                                    @"g", K_GRAMS,
                                    @"in", K_INCHES,
                                    @"K", K_KELVINS,
                                    @"kg", K_KILOGRAMS,
                                    @"m/s", K_METER_PER_SEC,
                                    @"m", K_METERS,
                                    @"MPH", K_MILES_PER_HOUR,
                                    @"mm", K_MILLIMETERS,
                                    @"N", K_NEWTONS,
                                    @"oz", K_OUNCES,
                                    @"lbs", K_POUNDS,
                                    @"m/s^2", K_M_PER_SEC_SQ,
                                    @"g", K_GRAVITIES,
                                    @"", K_MACH, nil];
    NSString *preferredUnit = [SLUnitsConvertor defaultUnitForKey:dimKey];
    return [displayStrings objectForKey:preferredUnit];
}

@end
