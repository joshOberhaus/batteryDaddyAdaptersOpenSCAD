// Parametric Cylindrical Battery Adapter
// For storing small cylindrical batteries (A27, AAAA, etc.) in larger battery holders

/* [Host Battery Dimensions] */
// Type of host battery (D, C, AA)
host_battery_type = "D"; // [D, C, AA]
// Extra height for the adapter itself
extra_height = 5; // [0:0.25:5]
// Extra height to match clearance in holder
extra_height_clearance = 20; // [0:0.25:30]

/* [Stored Battery Dimensions] */
// Battery type selector
battery_type = "A27"; // [A27, AAAA, Custom]
// Custom diameter (only used if battery_type is "Custom")
custom_diameter = 8.3; // [5:0.1:15]
// Custom length (only used if battery_type is "Custom")
custom_length = 28.0; // [10:0.5:50]
// Custom label text (only used if battery_type is "Custom")
custom_label = "E96";

/* [Design Parameters] */
// Clearance from outer wall
wall_clearance = 1.0; // [0:0.1:4]
// Clearance between batteries
battery_spacing = 1.0; // [0.5:0.1:3]
// Extra radial clearance for battery holes
hole_clearance = 0.05; // [0:0.05:0.8]
// Percentage of battery length inside holder (0.8 = 80% inside, 20% sticking out)
battery_insertion_depth = 0.8; // [0.2:0.1:1]

/* [Advanced] */
// Resolution for curves
$fn = 100;

// Stored battery specifications [name, diameter, length]
stored_battery_specs = [
    ["A27",  7.75, 28.0],
    ["AAAA", 8.3, 42.5]
];

// Host battery holder dimensions [name, diameter, height]
host_battery_specs = [
    ["D",  34.2, 40.36],
    ["C",  26.2, 28.45],
    ["AA", 14.5, 23.15]
];

// Function to get battery spec by type
function get_battery_spec(type, specs, index) = 
    let (matching = [for (spec = specs) if (spec[0] == type) spec])
    len(matching) > 0 ? matching[0][index] : specs[0][index];

// Function to get battery spec with custom support
function get_battery_spec_custom(type, specs, index) = 
    let (matching = [for (spec = specs) if (spec[0] == type) spec])
    len(matching) > 0 ? matching[0][index] : 
    (type == "Custom" ? (index == 1 ? custom_diameter : custom_length) : specs[0][index]);

// Get host battery dimensions
host_diameter = get_battery_spec(host_battery_type, host_battery_specs, 1);
host_height = get_battery_spec(host_battery_type, host_battery_specs, 2) + extra_height;

// Get stored battery dimensions
stored_diameter = get_battery_spec_custom(battery_type, stored_battery_specs, 1);
stored_length = get_battery_spec_custom(battery_type, stored_battery_specs, 2);
display_label = battery_type == "Custom" ? custom_label : battery_type;

// Calculate circular packing
available_radius = (host_diameter / 2) - wall_clearance - ((stored_diameter + hole_clearance) / 2);
min_angle = 2 * asin((stored_diameter + battery_spacing) / (2 * available_radius));
num_slots = floor(360 / min_angle);
actual_angle = 360 / num_slots;

// Calculate insertion depths
battery_depth_inside = stored_length * battery_insertion_depth;
battery_depth_outside = stored_length * (1 - battery_insertion_depth);
total_height = host_height + battery_depth_outside;

// Display calculations
echo(str("========================================"));
echo(str("HOST BATTERY"));
echo(str("  Type: ", host_battery_type));
echo(str("  Diameter: ", host_diameter, " mm"));
echo(str("  Height: ", host_height, " mm"));
echo(str(""));
echo(str("STORED BATTERY"));
echo(str("  Type: ", display_label));
echo(str("  Diameter: ", stored_diameter, " mm"));
echo(str("  Length: ", stored_length, " mm"));
echo(str(""));
echo(str("CIRCULAR PACKING"));
echo(str("  Available radius: ", available_radius, " mm"));
echo(str("  Number of slots: ", num_slots));
echo(str("  Angle between slots: ", actual_angle, "°"));
echo(str(""));
echo(str("INSERTION DEPTH"));
echo(str("  Battery inside holder: ", battery_depth_inside, " mm"));
echo(str("  Battery sticking out: ", battery_depth_outside, " mm"));
echo(str("  Total height: ", total_height, " mm"));
echo(str("========================================"));

module battery_adapter() {
    difference() {
        // Main cylinder
        cylinder(h = host_height, d = host_diameter, center = false);
        
        // Create all battery slots in circular pattern
        for (i = [0 : num_slots - 1]) {
            angle = i * actual_angle;
            x_pos = available_radius * cos(angle);
            y_pos = available_radius * sin(angle);
            translate([x_pos, y_pos, host_height * battery_insertion_depth])
                cylinder(h = stored_length, d = stored_diameter + hole_clearance, center = true);
        }
    }
    
    // Label embossed on top
    embossed_label();
}

// Add embossed label on top
module embossed_label() {
    // Calculate inner safe radius (center area not occupied by batteries)
    inner_safe_radius = available_radius - (stored_diameter / 2);
    // Calculate maximum text width (diameter of safe circle, with margin)
    max_text_width = inner_safe_radius * 2 * 0.8; // 80% of diameter for margin
    
    // Calculate text size based on character count and available space
    char_width_ratio = 0.8; // Approximate width/height ratio for characters
    estimated_width = len(display_label) * host_diameter * 0.15 * char_width_ratio;
    scale_factor = min(1, max_text_width / estimated_width);
    final_text_size = host_diameter * 0.15 * scale_factor;
    
    translate([0, 0, host_height])
        linear_extrude(height = 0.6)
            text(display_label, 
                 size = final_text_size, 
                 halign = "center", 
                 valign = "center",
                 font = "Liberation Sans:style=Bold");
}

// Main assembly
battery_adapter();
