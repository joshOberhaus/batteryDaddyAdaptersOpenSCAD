// Parametric Button Cell to Cylindrical Battery Adapter
// Side-loading slots with compliant mechanism for secure battery retention

/* [Host Battery Dimensions] */
// Type of host battery (D, C, AA)
host_battery_type = "D"; // [D, C, AA]
// Extra height beyond standard battery (for case clearance)
extra_height = 24.25; // [0:0.25:30]

/* [Button Cell Dimensions] */
// Battery type selector
battery_label = "CR2450"; // [CR2450, CR2032, CR2016, CR1632, CR1616, Custom]
// Custom diameter (only used if battery_label is "Custom")
custom_diameter = 24.5; // [10:0.5:30]
// Custom thickness (only used if battery_label is "Custom")
custom_thickness = 5.0; // [1:0.1:10]
// Custom label text (only used if battery_label is "Custom")
custom_label = "CR2450";

// Coin cell battery specifications [name, diameter, thickness]
coin_cell_batteries = [
    ["CR2450",  24.5, 5.0],
    ["CR2032",  20.0, 3.2],
    ["CR2016",  20.0, 1.6],
    ["CR1632",  16.0, 3.2],
    ["CR1616",  16.0, 1.6]
];

// Function to get battery spec by type
function get_coin_cell_spec(type, specs, index) = 
    let (matching = [for (spec = specs) if (spec[0] == type) spec])
    len(matching) > 0 ? matching[0][index] : 
    (type == "Custom" ? (index == 1 ? custom_diameter : custom_thickness) : specs[0][index]);
// Get button cell dimensions based on selection
button_cell_diameter = get_coin_cell_spec(battery_label, coin_cell_batteries, 1);
button_cell_thickness = get_coin_cell_spec(battery_label, coin_cell_batteries, 2);
// Use custom label if battery type is Custom, otherwise use the selected type
display_label = battery_label == "Custom" ? custom_label : battery_label;

// Function to get battery spec by type
function get_battery_spec(type, specs, index) = 
    let (matching = [for (spec = specs) if (spec[0] == type) spec])
    len(matching) > 0 ? matching[0][index] : specs[0][index];
/* [Design Parameters] */
// Width multiplier for flat sides (0.5-0.7 typical, relative to button cell diameter)
flat_width_ratio = 0.57; // [0.4:0.01:0.8]
// Radial clearance around button cell diameter
radial_clearance = 2.7 ; // [0.5:0.1:5]
// Clearance for thickness (added to top and bottom of each slot)
thickness_clearance = 0.1; // [0.1:0.1:1]
// Spacing between battery slots
slot_spacing = 1.0; // [0.5:0.1:3]
// Wall thickness at top and bottom
end_wall_thickness = 1.25; // [1:0.25:5]
// Compliant mechanism thickness
compliant_thickness = 1.0; // [0.5:0.1:2]
// Gap between compliant mechanism and slot edges
compliant_gap = 0.3; // [0.2:0.05:1]

/* [Advanced] */
// Resolution for curves
$fn = 100;

// battery holder dimensions [diameter, height]
battery_specs = [
    ["D",  34.2, 40.36],
    ["C",  26.2, 28.45],
    ["AA", 14.5, 23.15]
];


// Get host battery dimensions
host_diameter = get_battery_spec(host_battery_type, battery_specs, 1);
host_height = get_battery_spec(host_battery_type, battery_specs, 2) + extra_height;

// Calculate derived dimensions
flat_width = button_cell_diameter * flat_width_ratio;
slot_diameter = button_cell_diameter + (radial_clearance * 2);
slot_thickness = button_cell_thickness + (thickness_clearance * 2);

// Calculate number of slots that fit
available_height = host_height - (2 * end_wall_thickness);
slot_pitch = slot_thickness + slot_spacing;
num_slots = floor(available_height / slot_pitch);
actual_used_height = (num_slots * slot_pitch) - slot_spacing;
bottom_offset = end_wall_thickness + (available_height - actual_used_height) / 2;

echo(str("========================================"));
echo(str("Host Battery: ", host_battery_type));
echo(str("Host Diameter: ", host_diameter, "mm"));
echo(str("Host Height: ", host_height, "mm"));
echo(str("Button Cell: ", display_label));
echo(str("Slot Diameter: ", slot_diameter, "mm"));
echo(str("Slot Thickness: ", slot_thickness, "mm"));
echo(str("Width of flat: ", flat_width, "mm"));
echo(str("NUMBER OF SLOTS: ", num_slots));
echo(str("Actual used height: ", actual_used_height, "mm"));
echo(str("========================================"));

module single_slot(z_position) {
    translate([0, 0, z_position]) {
        rotate([0, 0, 0]) {
            // Main slot with clearance for compliant mechanism
            cylinder(h = slot_thickness, d = slot_diameter, center = true);
            
        }
    }
}

module battery_adapter() {
    difference() {
        intersection() {
            // Main cylinder
            cylinder(h = host_height, d = host_diameter, center = false);
            
            // rectangley cut
            translate([-host_diameter/2, -flat_width/2, 0])
                cube([host_diameter, flat_width, host_height]);
        }
        
        // create all battery slots
        for (i = [0 : num_slots -1]) {
            z_pos = bottom_offset + (i * slot_pitch) + (slot_thickness / 2);
            single_slot(z_pos);
        }
        embossed_label();
    }
   
    
    // probably a smarter way to re-instantation this
    // cut the compliant mechanisms to be within the intersection from before
    intersection()
    {
        intersection() {
            // Main cylinder
            cylinder(h = host_height, d = host_diameter, center = false);
            // rectangley cut
            translate([-host_diameter/2, -flat_width/2, 0])
                cube([host_diameter, flat_width, host_height]);
        }
        for (i = [0 : num_slots -1]) {
            z_pos = bottom_offset + (i * slot_pitch) + (slot_thickness / 2);
            compliant_mechanism(z_pos);
        }
    
    }
    compliant_posts_2(host_height/2);
    extra_height_handle_label();
}

module compliant_posts_2(z_position)
{
    translate([0, 0, z_position]) {
        intersection()
        {
            difference()
            {
            cylinder(h = host_height, d = host_diameter, center =true);
            cylinder(h = host_height+0.1, d = button_cell_diameter, center =true);
            }
            echo(flat_width*0.25)
            translate([0, flat_width*0.4, 0])
            {
            cube([host_diameter,flat_width*(0.2),host_height], center=true);
            }
        }
    }
}

module compliant_mechanism(z_position) {
    translate([0, 0, z_position]) {
        difference() {
            cylinder(h = button_cell_thickness - 0.4, d = button_cell_diameter + compliant_thickness, center =true);
            cylinder(h = button_cell_thickness+0.2, d = button_cell_diameter, center = true);
            
        }
    }
}

module extra_height_handle_label()
{
    translate([sqrt((host_diameter/2)^2-(flat_width/2)^2), -flat_width/2, host_height])
    rotate([0,0,90])
    {
        translate([0,0,-extra_height/2])
        {
            // lol, I don't know what I'm doing
            rotate([90, -90, -90])
            {
                # linear_extrude(height = 0.4)
                    text(display_label, 
                         size = host_diameter * 0.12, 
                         halign = "center", 
                         valign = "top",
                         font = "Liberation Sans:style=Bold");
            }
        }
        rotate([-180, 0, 0]){
        rotate_extrude(angle=90) 
             square([5,extra_height]);
        }
    }
}

// Add embossed label on top
module embossed_label() {
    # translate([0, 0, host_height - 0.5])
        linear_extrude(height = 0.6)
            text(display_label, 
                 size = host_diameter * 0.15, 
                 halign = "center", 
                 valign = "center",
                 font = "Liberation Sans:style=Bold");
}

// Main assembly
rotate([-90,0,0])
battery_adapter();
