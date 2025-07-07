/*
Some of the functions and calculations were adapted from the gridfinity-rebuilt-openscad project
See: https://github.com/kennetek/gridfinity-rebuilt-openscad
*/

$fa = 2;
$fs = 0.2;

// ===== Specification ===== //
// most of these are from: https://gridfinity.xyz/specification/

/* [Hidden] */

// x,y dimensions of a gridfinity cell
BASEPLATE_DIMENSIONS = [42, 42];

// height of a baseplate 
BASEPLATE_HEIGHT = 5;

// outer diameter of the baseplate
BASEPLATE_OUTER_DIAMETER = 8;

// side profile of the baseplate
BASEPLATE_PROFILE = [
    [0, 0], // Innermost bottom point
    [0.7, 0.7], // Up and out at a 45 degree angle
    [0.7, (0.7+1.8)], // Straight up
    [(0.7+2.15), (0.7+1.8+2.15)], // Up and out at a 45 degree angle
];

// some calculations...
BASEPLATE_OUTER_RADIUS = BASEPLATE_OUTER_DIAMETER / 2;
BASEPLATE_INNER_RADIUS = BASEPLATE_OUTER_RADIUS - BASEPLATE_PROFILE[3].x;
BASEPLATE_INNER_DIAMETER = BASEPLATE_INNER_RADIUS * 2;

// distance from center of magnet hole to edge of baseplate section
MAGNET_EDGE_DIST = 8;

// ===== Parameters ===== //

/* [Hidden]*/
// Minimum wall thickness
MinWallThickness = 0.4;

// Additional height from the bottom of the magnet holes to the top of the added floor.
// Necessary in case the AdditionalFloorHeight is set to zero.
MinMagnetFloorHeight = 0.4;

// only used for use with the animate.scad script. Don't change this here
// can also be set to true for developing or testing.
// turn off for export
Render = false;

/* [General Settings] */

// Add color to the model
UseMulticolor = false;

// Include a gridfinity base inside the basket?
UseGridfinityBase = true;

// Gridsize
GridSize = [3,3,6]; // [1:1:]

// Padding between edge of gridfinity base and the basket walls
Padding = 1; // [0:0.1:10]

// Wall Thickness of the Basket
WallThickness = 1.2; // [0.4:0.1:2]

// Additional floor height added to the bottom of the basket. 
AdditionalFloorHeight = 1; // [0:0.04:3]

// Solid floor? Requires AdditionalFloorHeight > 0 to work
SolidFloor = true;

// Diamenter of the magnets. If set to zero, no magnet holes will be created. Increase this value to add some tolerance for magnet insertion.
MagnetDiameter = 6.1; // [0:0.05:8]

// Height of the magnets. If set to zero, no magnet holes will be created. Increase this value to add some tolerance for magnet insertion.
MagnetHeight = 2.1; // [0:0.05:4]

// Add additional chamfers around magnet holes to help with insertion
AddMagnetChamfer = false;

/* [WallPattern Settings] */

// Wall Pattern
WallPattern = 1; // [0:None, 1:HexGrid, 2:Grid]

// Pattern feature size
PatternSize = 8; // [4:0.5:15]

// Minimum distance from the top of the pattern to the start of the stacking lip
PatternTopDist = 3; // [0:0.1:10]

// Minimum distance from the bottom of the pattern to the baseplate
PatternBotDist = 1.5; // [0:0.1:10]

// Minimum distance from the pattern sides to the start of the basket outer corner
PatternSideDist = 2; // [0:0.1:10]

// Minimum distance between patterns
PatternMinDist = 2; // [0.5:0.1:5]

// Outer radius of grid pattern (has no effect on other patterns)
GridPatternRadius = 3; // [0:0.5:10]

/* [Stacking Settings] */

// How far down a basket reaches into a basket under it. Increasing this value decreses wiggle when stacking baskets. 
Standoff = 1; // [1:0.1:2]

// extra room between top of any bin and bottom of another basket stacked on top
TopPadding = 2 ; // [0.5:0.1:5]

// XY tolerance (leave as-is in most cases)
XYTolerance = 0.5; // [0.2:0.05:1]

// Z tolerance (lave as-is in most cases)
ZTolerance = 0.25; 


// ===== Calculations ===== //

/* [Hidden] */

// Necessary height needed for magnets. 
magnet_clearance = (MagnetDiameter > 0 && MagnetHeight > 0 && UseGridfinityBase && SolidFloor) ? MagnetHeight + MinMagnetFloorHeight : 0;

total_grid_size_mm = [BASEPLATE_DIMENSIONS.x * GridSize.x, BASEPLATE_DIMENSIONS.y * GridSize.y];
total_inner_size_mm = foreach_add(total_grid_size_mm, 2 * Padding);
total_outer_size_mm = foreach_add(total_inner_size_mm, 2 * WallThickness);

// Total grid height: 5mm baseplate, 2mm for 1u, 4.4mm for stacking lip, nU*7mm
total_grid_height_mm = BASEPLATE_HEIGHT + 2 + 4.4 + 7*(GridSize.z-1); 

// another basket sits inside by standoff mm and even further by ztolerance, starting from the lowest point of the top stacking lip. 
// Added top padding increases distance between bins and top of another basket stacked on top
// Also add some height for magnets if necessary
total_height_mm = total_grid_height_mm + AdditionalFloorHeight + Standoff + ZTolerance + (WallThickness-MinWallThickness) + TopPadding + magnet_clearance;

// The total height of the bottom stacking lip
bottom_stacking_lip_height = Standoff + ZTolerance + WallThickness + XYTolerance;

// Total height from the bottom of the basket up untip the top of the baseplate
total_baseplate_height_mm = BASEPLATE_HEIGHT + AdditionalFloorHeight + magnet_clearance;


// ===== Helper functions and modules ===== //

/*
Adds a value to every element of a list
list: List to add values to
to_add: Value to add
*/
function foreach_add(list, to_add) = 
    [for (item = list) item + to_add];

/*
Affine translation with vector for use with `multmatrix()`
*/
function affine_translate(vector) = [
    [1, 0, 0, vector.x],
    [0, 1, 0, vector.y],
    [0, 0, 1, vector.z],
    [0, 0, 0, 1]
];

/*
Calculates the magnitude of a 2d or 3d vector
*/
function vector_magnitude(vector) =
    sqrt(vector.x^2 + vector.y^2 + (len(vector) == 3 ? vector.z^2 : 0));

/*
Converts a 2d vector into an angle
Just a wrapper around atan2
*/
function atanv(vector) = atan2(vector.y, vector.x);

function _affine_rotate_x(angle_x) = [
    [1,  0, 0, 0],
    [0, cos(angle_x), -sin(angle_x), 0],
    [0, sin(angle_x), cos(angle_x), 0],
    [0, 0, 0, 1]
];
function _affine_rotate_y(angle_y) = [
    [cos(angle_y),  0, sin(angle_y), 0],
    [0, 1, 0, 0],
    [-sin(angle_y), 0, cos(angle_y), 0],
    [0, 0, 0, 1]
];
function _affine_rotate_z(angle_z) = [
    [cos(angle_z), -sin(angle_z), 0, 0],
    [sin(angle_z), cos(angle_z), 0, 0],
    [0, 0, 1, 0],
    [0, 0, 0, 1]
];

/*
Affine transformation matrix equivalent to `rotate`
Equivalent to `rotate([0, angle, 0])`
For use with `multmatrix()`
*/
function affine_rotate(angle_vector) =
    _affine_rotate_z(angle_vector.z) * _affine_rotate_y(angle_vector.y) * _affine_rotate_x(angle_vector.x);


/*
Create a rectangle with rounded corners by sweeping a 2d object along a path
Centered on origin
Result is on the x,y plane
Expects children to be a 2D shape in Q1 of x,y plane
size: dimensions of the resulting object as [x,y]
*/
module sweep_rounded(size) {
    half_x = size.x/2;
    half_y = size.y/2;
    path_points = [
        [-half_x, -half_y],
        [-half_x, half_y],
        [half_x, half_y],
        [half_x, -half_y],
        [-half_x, -half_y]
    ];
    path_vectors = [
        path_points[1] - path_points[0],
        path_points[2] - path_points[1],
        path_points[3] - path_points[2],
        path_points[4] - path_points[3]
    ];

    // These contain the translations, but not the rotations
    // OpenSCAD requires this hacky for loop to get accumulate to work!
    first_translation = affine_translate([path_points[0].y, 0,path_points[0].x]);
    affine_translations = concat([first_translation], [
        for (i = 0, a = first_translation;
            i < len(path_vectors);
            a=a * affine_translate([path_vectors[i].y, 0, path_vectors[i].x]), i=i+1)
        a * affine_translate([path_vectors[i].y, 0, path_vectors[i].x])
    ]);

    // Bring extrusion to the xy plane
    affine_matrix = affine_rotate([90, 0, 90]);

    walls = [
        for (i = [0 : len(path_vectors) - 1])
        affine_matrix * affine_translations[i]
        * affine_rotate([0, atanv(path_vectors[i]), 0])
    ];
    union() {
        for (i = [0 : len(walls) - 1]){
            multmatrix(walls[i])
                linear_extrude(vector_magnitude(path_vectors[i]))
                    children();

            // Rounded Corners
            multmatrix(walls[i] * affine_rotate([-90, 0, 0]))
                rotate_extrude(angle = 90, convexity = 4)
                    children();
        }
    }
}

/*
Creates a square with rounded corners
size: 3d vector with size of [x,y] where z determines the depth of the linear extrude
radius: radius of the corners
*/
module round_square(size, radius, center=false) {
    linear_extrude(size.z)
    offset(r=radius)offset(delta=-radius)
    square([size.x, size.y], center);
}


// ===== Modules ===== //

/*
Creates the negative of a single baseplate
*/
module baseplate_cutter() {
    inner_dimensions = foreach_add(BASEPLATE_DIMENSIONS, -BASEPLATE_OUTER_DIAMETER);
    inner_size = foreach_add(BASEPLATE_DIMENSIONS, BASEPLATE_INNER_DIAMETER-BASEPLATE_OUTER_DIAMETER);
    cube_dimensions = [
        inner_size.x - BASEPLATE_INNER_RADIUS,
        inner_size.y - BASEPLATE_INNER_RADIUS,
        BASEPLATE_HEIGHT
    ];

    baseplate_clearance_height = BASEPLATE_HEIGHT - BASEPLATE_PROFILE[3].y;
    translated_line = foreach_add(BASEPLATE_PROFILE, [BASEPLATE_INNER_RADIUS, baseplate_clearance_height]);

    union() {
        sweep_rounded(inner_dimensions) {
            polygon(concat(translated_line, [
                [0, BASEPLATE_HEIGHT],  // Go in to form a solid polygon
                [0, 0],  // Straight down
                [translated_line[0].x, 0] // Out to the translated start.
            ]));
        }
        translate(v = [0,0,BASEPLATE_HEIGHT/2]) 
            cube(cube_dimensions, center=true);
    }
}

/* 
Module that creates a hole for a single magnet with optional chamfer
*/
module magnet_hole() {
    additional_chamfer_width = (magnet_clearance && AddMagnetChamfer) ? 0.2*MagnetHeight : 0;
    profile = [
        [MagnetDiameter/2, 0],
        [MagnetDiameter/2, 0.8*MagnetHeight],
        [MagnetDiameter/2+additional_chamfer_width, MagnetHeight],
        [0, MagnetHeight],
        [0, 0],
        [0, 0]
    ];
    // Use non zero size to make sure sweep_rounded works correctly
    sweep_rounded([0.001,0.001,0]) {
        polygon(profile);
    }
}

/* 
Creates a gridfinity baseplate with GridSize
*/
module gridfinity_baseplate(round_corner=true) { 
    radius = round_corner ? BASEPLATE_OUTER_RADIUS : 0;
    magnet_offset_x = BASEPLATE_DIMENSIONS.x - 2 * MAGNET_EDGE_DIST;
    magnet_offset_y = BASEPLATE_DIMENSIONS.y - 2 * MAGNET_EDGE_DIST;
    difference() {
        // Create square with size of outer dimensions
        round_square(size = concat(total_inner_size_mm, total_baseplate_height_mm), radius = radius, center=false);

        // substract GridSize baseplate cutters
        union() {
            for (i = [0:GridSize.x-1], j = [0:GridSize.y-1]) {
                translation = [(BASEPLATE_DIMENSIONS.x/2)+(i*BASEPLATE_DIMENSIONS.x)+Padding, 
                               (BASEPLATE_DIMENSIONS.y/2)+(j*BASEPLATE_DIMENSIONS.y)+Padding,
                               AdditionalFloorHeight+magnet_clearance];

                if (UseGridfinityBase) {
                    translate(translation)
                        baseplate_cutter();  
                }
                if(!SolidFloor) {
                    translate([translation.x, translation.y, 0])
                        round_square(size=concat(foreach_add(BASEPLATE_DIMENSIONS, BASEPLATE_INNER_DIAMETER-BASEPLATE_OUTER_DIAMETER), AdditionalFloorHeight), 
                                     radius=BASEPLATE_INNER_RADIUS,center=true);
                }
                // add holes for magnets
                if(magnet_clearance > 0) {
                    translate(translation)
                    translate([MAGNET_EDGE_DIST-BASEPLATE_DIMENSIONS.x/2, MAGNET_EDGE_DIST-BASEPLATE_DIMENSIONS.y/2, -MagnetHeight])  
                        union() {
                            magnet_hole();
                            translate([magnet_offset_x, 0]) magnet_hole();
                            translate([0, magnet_offset_y]) magnet_hole();
                            translate([magnet_offset_x, magnet_offset_y]) magnet_hole();
                        }
                }
            }
            if (!UseGridfinityBase) {
                translate([0,0,bottom_stacking_lip_height])
                    round_square(total_inner_size_mm, radius = BASEPLATE_INNER_RADIUS);; 
            }
        }
    }
}

/* 
Create the outer wall of the basket
Includes creating the top stacking lip
Does not create the bottom stacking lip
*/
module basket_wall() {
    slope_length = WallThickness+ZTolerance; // length in x and y direction of bottom slope
    top_slope_length = WallThickness - MinWallThickness; // x,y length of the slope at the top of the bin 

    // Profile of the basket wall without the bottom stacking lip
    basket_profile = [
        [0, 0],
        [0, total_height_mm-top_slope_length],
        [top_slope_length, total_height_mm],
        [WallThickness, total_height_mm],
        [WallThickness, 0],
        [0, 0]
    ];

    // prepartions to create the wall with `sweep_round`
    translated_line = foreach_add(basket_profile, [BASEPLATE_OUTER_RADIUS, 0]);
    inner_dimensions = [
        total_inner_size_mm.x - BASEPLATE_OUTER_DIAMETER,
        total_inner_size_mm.y - BASEPLATE_OUTER_DIAMETER,
        total_height_mm
    ];

    // Size and position of the patterns
    pattern_height = total_height_mm - total_baseplate_height_mm - (WallThickness-MinWallThickness);
    pattern_area_x = [  (GridSize.x*BASEPLATE_DIMENSIONS.x)-(2*BASEPLATE_OUTER_RADIUS)+2*Padding-2*PatternSideDist, 
                        pattern_height-(PatternTopDist+PatternBotDist)];
    pattern_area_y = [  (GridSize.y*BASEPLATE_DIMENSIONS.y)-(2*BASEPLATE_OUTER_RADIUS)+2*Padding-2*PatternSideDist, 
                        pattern_height-(PatternTopDist+PatternBotDist)];
    pattern_corner = [WallThickness+BASEPLATE_OUTER_RADIUS+PatternSideDist, total_baseplate_height_mm+PatternBotDist];

    difference() {
        // create the outer wall
        translate([total_outer_size_mm.x/2, total_outer_size_mm.y/2]) 
            sweep_rounded(inner_dimensions)
                polygon(translated_line);
        
        // apply optional wall pattern
        if(WallPattern == 1) {
            // x direction
            translate([pattern_corner.x, 0, pattern_corner.y])
                hex_pattern(pattern_area_x, axis=0);
            // y direction
            translate([0, pattern_corner.x, pattern_corner.y])
                hex_pattern(pattern_area_y, axis=1);
        } else if (WallPattern == 2){
            // x direction
            translate([pattern_corner.x, 0, pattern_corner.y])
                grid_pattern(pattern_area_x, axis=0);
            // y direction
            translate([0, pattern_corner.x, pattern_corner.y])
                grid_pattern(pattern_area_y, axis=1);     
        }
    }
}

/*
Create a hex pattern for the given area
size: valid area size for the pattern
axis: 0=x, 1=y
*/
module hex_pattern(size, axis) {
    // length for the hex negatives, increased to avoid having zero length walls
    length = axis == 0 ? 1.1 * total_outer_size_mm.y : 1.1 * total_outer_size_mm.x;
    
    // short side of the hexagon
    s = (PatternSize*sqrt(3))/2;
    
    // long side of the hexagon
    d = PatternSize;

    // maximum amount of hexagons that can be placed into the area
    n_hexagons = [floor((size.x)/(s+PatternMinDist)), 
                  floor((size.y)/(d+PatternMinDist))];

    // if area is too small for the pattern, do nothing
    if(n_hexagons.x > 0 && n_hexagons.y > 0) {

        // calculate the optimum distance between two hexes to place them evenly
        hex_dist = [n_hexagons.x > 1 ? (size.x-(n_hexagons.x*s))/(n_hexagons.x-1) : 0, 
                    n_hexagons.y > 1 ? (size.y-(n_hexagons.y*d))/(n_hexagons.y-1) : 0];

        // bottom left position for the first hexagon
        start = [
            n_hexagons.x > 1 ? -size.x/2 + s/2 : 0, 
            n_hexagons.y > 1 ? -size.y/2 + PatternSize/2 : 0, 
            -length/2];

        rotate([90,0,90*axis])  
            translate(size/2) 
                union() {
                    for (i=[0:n_hexagons.x-1], j=[0:n_hexagons.y-1]) {
                        translate([start.x + i *(hex_dist.x+s), start.y + j*(hex_dist.y+d), (-0.95+0.9*axis)*length]) 
                            rotate([0, 0, 90]) 
                                cylinder(r=PatternSize/2, h=length, $fn=6);
                    }
                }
    }
}

/* 
Create a grid pattern for the given area
size: valid area size for the pattern
axis: 0=x, 1=y 
Always uses PatternMinDist as distance between squares
*/
module grid_pattern(size, axis) {
    // length for the hex negatives, increased to avoid having zero length walls
    length = axis == 0 ? 1.1 * total_outer_size_mm.y : 1.1 * total_outer_size_mm.x;

    // maximum amount of hexagons that can be placed into the area
    n_squares = [floor((size.x)/(PatternSize+PatternMinDist))+2, 
                  floor((size.y)/(PatternSize+PatternMinDist))+2];

    rotate([90,0,90*axis])  
        translate(size/2) 
            intersection() {
                translate(concat(-size/2, (-0.95+0.9*axis)*length)) 
                    round_square(concat(size, length), GridPatternRadius);

                // use the center of the area as a reference and go to the left/right, top/bot
                union() {
                    for (i=[-floor(n_squares.x/2):floor(n_squares.x/2)], j=[-floor(n_squares.y/2):floor(n_squares.y/2)]) {
                        translate([i *(PatternMinDist+PatternSize), j*(PatternMinDist+PatternSize), (-0.95+0.9*axis)*length]) 
                            rotate([0, 0, 90]) 
                                cylinder(r=PatternSize/2, h=length, $fn=4);
                    }
                    for (i=[-floor(n_squares.x/2):floor(n_squares.x/2)], j=[-floor(n_squares.y/2):floor(n_squares.y/2)]) {
                        translate([(PatternMinDist+PatternSize)/2 + i *(PatternMinDist+PatternSize), 
                                   (PatternMinDist+PatternSize)/2+ j*(PatternMinDist+PatternSize), 
                                   (-0.95+0.9*axis)*length]) 
                            rotate([0, 0, 90]) 
                                cylinder(r=PatternSize/2, h=length, $fn=4);
                    }
                }
            }

}

/* 
Creates the negative of the bottom stacking lip
*/
module stacking_lip_cutter() {
    inner_dimensions = foreach_add(total_inner_size_mm, -BASEPLATE_OUTER_DIAMETER);
    inner_size = foreach_add(total_inner_size_mm, BASEPLATE_INNER_DIAMETER-BASEPLATE_OUTER_DIAMETER);
    cube_dimensions = [
        inner_size.x,
        inner_size.y,
        bottom_stacking_lip_height
    ];

    profile = [
        [0, 0],
        [0, Standoff + ZTolerance],
        [WallThickness+XYTolerance, bottom_stacking_lip_height],
    ];
    translated_line = foreach_add(profile, 
    [BASEPLATE_OUTER_RADIUS - XYTolerance, 0]);

    // makes the stacking_lip_cutter just a little bigger to the outside so we dont get walls with zero width
    stacking_lip_cut_scaler = 5;
    
    difference() {
        // create a round square the size of the basket and enlarge it a bit
        translate([-stacking_lip_cut_scaler/2, -stacking_lip_cut_scaler/2])  
            round_square(size = concat(foreach_add(total_outer_size_mm, stacking_lip_cut_scaler), bottom_stacking_lip_height), 
                         radius = BASEPLATE_OUTER_RADIUS, 
                         center=false);

        // substract the positive of the bottom stackip lip
        translate([total_outer_size_mm.x/2, total_outer_size_mm.y/2])
            union() {
                sweep_rounded(inner_dimensions) {
                    polygon(concat(translated_line, [
                        [0, bottom_stacking_lip_height],
                        [0, 0],
                        [translated_line[0].x, 0]
                    ]));
                }
                translate([0,0,bottom_stacking_lip_height/2]) 
                    cube(cube_dimensions, center=true);
            }
    }
}

/* 
Creates a single gridfinity hex basket with settings from the top of the file 
*/
module basket() {
    // center on origin
    translate(-[total_outer_size_mm.x/2, total_outer_size_mm.y/2])
        difference() {
            // combine baseplate and wall
            union() {
                translate([WallThickness, WallThickness])
                    gridfinity_baseplate(round_corner=true);
                basket_wall();
            }
            // translate([WallThickness, WallThickness, BASEPLATE_HEIGHT - BASEPLATE_PROFILE[3].y +])
            // round_square(total_inner_size_mm, radius = BASEPLATE_OUTER_RADIUS);

            // substract the bottom stacking lip
            stacking_lip_cutter();
        }
}

/* 
Adds color to the children starting at height y up until y+height
*/
module add_color(y, height, color) {
    color(color)
    intersection() {
        translate([0,0,y+height/2]) 
            cube(concat(total_outer_size_mm*2, height), center=true);
        children();
    }
}


// actually create a basket with the given settings
// Render is only changed by the animate.scad script.
// This is outside of a module so multi-color export works with openscad
if (Render) {
    render() {
        if (UseMulticolor) {
            cut1 = total_baseplate_height_mm;
            cut2 = total_height_mm-(WallThickness-MinWallThickness);

            add_color(0, cut1, "red")
                basket();

            add_color(cut1, cut2-cut1, "green")
                basket();

            add_color(cut2, WallThickness-MinWallThickness, "blue")
                basket();
        } else {
                basket();
        }
    }
} else {
    if (UseMulticolor) {
        cut1 = total_baseplate_height_mm;
        cut2 = total_height_mm-(WallThickness-MinWallThickness);

        add_color(0, cut1, "red")
            basket();

        add_color(cut1, cut2-cut1, "green")
            basket();

        add_color(cut2, WallThickness-MinWallThickness, "blue")
            basket();
    } else {
            basket();
    }
}
