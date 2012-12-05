//
//  SLDefinitions.h
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 Smart Software. All rights reserved.
//



/* The LaunchDirection constants will be used in the calculation of the angle of attack 
    This will tell us how to add the rocket velocity and wind vectors
 */

enum LaunchDirection : NSUInteger {
    WithWind = 0,
    CrossWind = 1,
    IntoWind = 2
};

#define BACKGROUND_IMAGE_FILENAME @"Vellum"
#define MOTOR_CACHE_FILENAME @"motorcache.plist"
#define VERTICAL_ROCKET_PIC_NAME @"Rocket"

#pragma mark Calculation constants

#define DIVS_DURING_BURN 1000                          //how fine-grained is the numerical integration
#define DIVS_AFTER_BURNOUT 500

#define MAX_LAUNCH_GUIDE_ANGLE 0.349066     //20 degrees in radians
#define DEFAULT_LAUNCH_GUIDE_LENGTH 1.83    //6 feet in meters
#define DEFAULT_CD 0.75                     //the typical Cd of a 3FNC/4FNC rocket
#define GRAV_ACCEL 9.80665
#define _PI_ 3.14159265359
#define T_LAPSE_RATE 0.0065
#define STANDARD_TEMP 288.15
#define STANDARD_PRESSURE 101.325
#define MOLAR_MASS 0.0289644
#define GAS_CONSTANT 8.31447
#define PRESSURE_EXPONENT 5.25578
#define MPH_TO_M_PER_SEC 0.44704
#define FEET_PER_METER 3.2808399
#define DEGREES_PER_RADIAN 57.2957
#define POUNDS_PER_KILOGRAM 2.2046226
#define OUNCES_PER_KILOGRAM 35.2739616
#define ABSOLUTE_ZERO_CELSIUS -272.15
#define STANDARD_RHO 1.22                 //kg per m^3

/* All calculations done in kilogram-meter-second metric measurements, and radians
 The maximum allowed launch guide angle is set by the Model Rocketry Safety Code and High Power Rocketry Safety Code
 The default launch guide length is six feet, given in meters
 GRAV is the acceleration of gravity at the Earth's surface in m/s^2
 DIVS is the number of divisions per second that will be used for the numeric integration step 
 */

#pragma mark Type definitions

typedef CGPoint ThrustPoint;
#define ThrustPointZero CGPointZero

#pragma mark Index constants

#define TIME_INDEX 0
#define ALT_INDEX 1
#define TRAV_INDEX 2
#define VEL_INDEX 3
#define ACCEL_INDEX 4

#pragma mark String literal constants

#define SETTINGS_KEY @"SmartLaunchSettingsDictionary"

#define ALL_MOTORS_KEY @"SmartLaunch_All_Motors"
#define LAST_MOTOR_SEARCH_KEY @"SmartLaunch_Last_Motor_Search"
#define FAVORITE_ROCKETS_KEY @"SmartLaunch_Favorite_Rockets"
#define UNIT_PREFS_KEY @"SmartLaunch_Unit_Preferences"
#define INTERFACE_PREFS_KEY @"SmartLaunch_Interface_Preferences"
#define LENGTH_UNIT_KEY @"SmartLaunch_Length_Unit"
#define ALT_UNIT_KEY @"SmartLaunch_Altitude_Unit"
#define DIAM_UNIT_KEY @"SmartLaunch_Diameter_Unit"
#define TEMP_UNIT_KEY @"SmartLaunch_Temperature_Unit"
#define VELOCITY_UNIT_KEY @"SmartLaunch_Velocity_Unit"
#define THRUST_UNIT_KEY @"SmartLaunch_Thrust_Unit"
#define MASS_UNIT_KEY @"SmartLaunch_Mass_Unit"
#define MOTOR_SIZE_UNIT_KEY @"SmartLaunch_Motor_Size_Unit"

#define ALT_MSL_KEY @"SmartLaunch_AltitudeMSL"
#define TEMPERATURE_KEY @"SmartLaunch_Temperature"
#define PRESSURE_KEY @"SmartLaunch_Pressure"
#define RHO_RATIO_KEY @"SmartLaunch_RhoRatio"
#define MACH_ONE_KEY @"SmartLaunch_SpeedOfSound"

#define MOTOR_SEARCH_1_KEY @"SmartLaunch_Motor_Search_Key1"
#define MOTOR_SEARCH_2_KEY @"SmartLaunch_Motor_Search_Key2"
#define MOTOR_SEARCH_PICKER_INDEX @"SmartLaunch_Motor_Picker_Index"
#define MOTOR_SEARCH_MATCH_DIAM_KEY @"SmartLaunch_Motor_Match_Diam_Key"

#pragma mark Settings dictionary keys

#define SELECTED_ROCKET_KEY @"SmartLaunch_Selected_Rocket"
#define SELECTED_MOTOR_KEY @"SmartLaunch_Selected_Motor"
#define LAUNCH_ANGLE_KEY @"SmartLaunch_Launch_Angle"
#define LAUNCH_GUIDE_LENGTH_KEY @"SmartLaunch_Rod_Length"
#define WIND_VELOCITY_KEY @"SmartLaunch_Wind_Velocity"
#define WIND_DIRECTION_KEY @"SmartLaunch_Wind_Direction"
#define LAUNCH_ALTITUDE_KEY @"SmartLaunch_Launch_Altitude"
#define LAUNCH_TEMPERATURE_KEY @"SmartLaunch_Launch_Temperature" 

// Interface prefs defines

#define CELL_DETAIL_DATA_KEY @"SmartLaunch_Cell_Data_Key"
#define MOTOR_PREFS_KEY @"SmartLaunch_Motor_Preferences_Key"

// had to add the K_ prefix to keep from grep'ing inappropriate things

#define K_METER_PER_SEC @"m/s"
#define K_FEET_PER_SEC @"fps"
#define K_MILES_PER_HOUR @"MPH"
#define K_METERS @"m"
#define K_CENTIMETERS @"cm"
#define K_INCHES @"in"
#define K_FEET @"ft"
#define K_MILLIMETERS @"mm"
#define K_FAHRENHEIT @"°F"
#define K_CELSIUS @"°C"
#define K_KELVINS @"K"
#define K_POUNDS @"lbs"
#define K_NEWTONS @"N"
#define K_KILOGRAMS @"kg"
#define K_OUNCES @"oz"
#define K_GRAMS @"g"




