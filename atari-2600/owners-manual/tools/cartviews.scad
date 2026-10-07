// The Rev1 cart shell's two halves in ASSEMBLED position (the shell file's
// part="rear" is the mirrored print layout).  Shell frame: X across the
// cart, Y = -(board y) with the open end at the bottom, Z from the label
// face (0) to the screw face (20.22).
// OPENSCADPATH=build/case:$HW/case openscad -D 'view="front"' -o x.stl tools/cartviews.scad
use <Fujiversal-Atari2600-CartShell.scad>
view = "front";
if (view == "front") front_half();
else if (view == "rear") rear_half();
