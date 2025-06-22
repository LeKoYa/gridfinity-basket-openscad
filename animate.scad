include <gridfinityBasket.scad>;

Render = true;

// Gridsize
GridSize = [1+floor($t*360/120), 1+floor($t*360/120), 1+floor($t*360/60)];

// Pattern feature size
PatternSize = 3+floor($t*360/5%15); // [4:0.5:15]

// Wall Pattern
WallPattern = floor($t*360/120); // [0:None, 1:HexGrid, 2:Grid]

$fa = 2;
$fs = 0.2;
$vpt = [0, 0, 20];
$vpr = [70, 0, 45+360 * $t];
$vpd = 350;
