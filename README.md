# TimeMAtricks Plugin for GrandMA3
A powerful GrandMA3 plugin that automatically controls MAtricks timing based on master faders, enabling dynamic MAtricks synchronized with timing or speed masters.  

## Overview
TimeMAtricks allows you to create time-based MAtricks effects that respond dynamically to master faders. The plugin monitors timing or speed masters and automatically adjusts MAtricks fade and delay values in real-time, creating smooth, scalable sweeps.  

## Features
Master Fader Control: Link MAtricks to timing or speed masters for real-time control  
Multiple MAtricks Support: Control up to 9 different MAtricks simultaneously with 3 individual rates  
Speed Master Integration: BPM-based control with automatic time conversion  
Fade/Delay Split: Adjustable fade amount with visual slider control  
Global Scaling: Overall rate scaling with half-time/double-time buttons  
Prefix System: Organize MAtricks with custom naming prefixes  
Auto-Creation: Automatically creates MAtricks triplets (3 variations per group)  

## Installation
Copy TimeMAtricks.lua and TimeMAtricks.xml to your GrandMA3 plugins folder  
Import the plugin in GrandMA3 via the Plugin Pool  

## Quick Start
### Start the plugin
Launch: Click the TimeMAtricks icon in the command line  
Configure Storage: Press "Settings" and set the MAtricks pool start number  
Set Master: Enter a master number and select "Timing Master" or "Speed Master"  

#### Add MAtricks:  
Toggle "MAtricks 1" on  
Enter a name (e.g., "in, out and long")  
Set rate (0.25 = quarter speed, 1 = normal, 2 = double speed)  
Start Plugin: Click "Plugin On"  
Control: Move your master fader to see the effects respond in real-time  
How It Works  
MAtricks Triplets  
For each named MAtricks, the plugin creates 3 variations:  

YourName 1  
YourName 2  
YourName 3  

#### Timing Calculation  
Timing Master: Direct time values (0-10 seconds)  
Speed Master: BPM to quarter note conversion  
Rate Multipliers: Individual rates per MAtricks (0.01x - 9.99x)  
Overall Scale: Global scaling factor (0.125× to 8×)  
Fade Split: Configurable fade/delay ratio  

## Interface Guide
### Main Window  
Plugin On/Off: Enable/disable the plugin loop  
Master Section:  
Master number input  
Timing/Speed master toggle buttons  

MAtricks Section:  
3 toggleable MAtricks with name and rate inputs  
Prefix toggle for organized naming  
Fade Control:  

Visual slider for fade amount  
Hold buttons to disable fading  

Overall Scale:  
Half-time (HT) and double-time (DT) buttons  
Reset to 1× button  

### Settings Window  
MAtricks Pool Start: Starting number for auto-created MAtricks  
Refresh Rate: Plugin loop update frequency (seconds)  

Enable the prefix system to organize MAtricks with a common prefix:  
Prefix: "tm_"  
MAtricks Name: "in"  
Creates: "tm_in 1", "tm_in 2", "tm_in 3"  
Fade Amount Control  

The fade slider controls the split between fade and delay:  
Left (Fade Less): More delay, less fade  
Right (Fade More): More fade, less delay  
Hold to Toggle: Long-press to disable fading entirely  

Rate Examples  
0.25: Quarter speed (4× slower)  
0.5: Half speed (2× slower)  
1.0: Normal speed  
2.0: Double speed (2× faster)  

## Technical Details

For BETA use the plugin automatically creates a "TimeMAtricks Reset" macro that clears all global variables for clean uninstallation.

Troubleshooting
Common Issues
MAtricks not found: Verify MAtricks names match exactly (case-sensitive)

## Performance Tips
Use refresh rates of 0.5-1 seconds for smooth operation. Higher values sync less so MAtricks are not always at correct time. Lower values might spam the System Monitor and 
Choose unused pool numbers to avoid scattered MAtricks in your pool

## Version History
BETA 0.9.3 (Current)

## Requirements
GrandMA3 software (version 2.3+)

## Support
For issues, feature requests, or contributions, please visit the GitHub repository.

License
This plugin is provided as-is for the GrandMA3 community. Use at your own discretion in production environments.
