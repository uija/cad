// Parametrische MX-Keycap mit seitlichem LED-Fenster und verlängertem Stem
// Druck: Oberseite nach unten aufs Bett legen (Stem zeigt nach oben).
//
// part = "body"   -> Kappe (Fenster ausgespart)
// part = "insert" -> nur das Fenster-Stück (in klarem/weißem Filament drucken)
// part = "both"   -> beides zusammen (Vorschau)
// Multi-Material: body + insert als zwei Teile eines Objekts in den Slicer laden.
// Ohne Multi-Material: nur "body" drucken -> Fenster bleibt offen.


// EXPORT:
// openscad -o keycap_body.stl   -D 'part="body"'   keycap.scad
// openscad -o keycap_insert.stl -D 'part="insert"' keycap.scad

part = "both"; // [both, body, insert]

$fn = 48;

/* [Außenform] */
bottom     = 18.0;  // Kantenlänge unten (mm)  – bitte nachmessen
top        = 13.5;  // Kantenlänge Oberseite (mm) – bitte nachmessen
height     = 8.0;   // Höhe Unterkante Rand bis Oberseite (mm)
corner_r   = 1.0;   // Eckenradius
wall       = 1.5;   // Wandstärke
top_thick  = 1.5;   // Deckelstärke
top_r      = 1.0;   // Rundung Kante Oberseite/Schrägen (0 = eckig, max. ~corner_r)

/* [Fenster (an +Y-Kante)] */
win_w      = 3.2;   // Breite des Streifens
win_in     = 3.2;   // wie weit es in die Oberseite reicht (ab Oberkante der Schräge)
win_frac   = 0.5;   // Anteil der Wandhöhe (von oben), den das Fenster abdeckt (1 = ganze Wand)
win_z0     = height * (1 - win_frac);
win_top    = 0.4;   // Dicke des Fensters auf der Oberseite (Lagen: 0.2 = 1 Lage bei 0.2er Schichthöhe)
win_side   = 0.45;  // Dicke des Fensters an der Seitenwand (≈ 1 Linienbreite)

/* [Stem] */
stem_extra  = 2.0;   // wie weit der Stem unter den Rand hinausragt (mm)
stem_d      = 5.5;   // Außendurchmesser Stem-Zylinder
cross_len   = 4.15;  // Länge der Kreuzarme (MX: 4.0 + Toleranz)
cross_w     = 1.35;  // Breite der Kreuzarme (MX: 1.17–1.3 + Toleranz)
cross_depth = 4.0;   // Tiefe des Kreuzlochs

module rsq(s, cr = corner_r) offset(r = cr) square(s - 2*cr, center = true);

slope = (bottom - top) / 2 / height;   // Einzug pro mm Höhe

// Kegelstumpf mit Unterkante b, Höhe h, Oberkante oben mit Radius r verrundet
module rounded_frustum(b, h, r, c = corner_r) {
    if (r <= 0) frustum(b, b - 2*slope*h, h, 0, c);
    else {
        sh = r * sqrt(1 + slope*slope);     // horizontaler Versatz der Schräge
        cr = max(c - r, 0.01);
        intersection() {
            minkowski() {
                hull() {
                    translate([0, 0, -r])
                        linear_extrude(0.01) rsq(2*(b/2 - sh + slope*r), cr);
                    translate([0, 0, h - r])
                        linear_extrude(0.01) rsq(2*(b/2 - sh - slope*(h - r)), cr);
                }
                sphere(r = r, $fn = 24);
            }
            translate([-b, -b, 0]) cube([2*b, 2*b, h]);
        }
    }
}

module outer() rounded_frustum(bottom, height, top_r);

// Außenform, um die Fensterdicke nach innen versetzt
module skin_inner() {
    s = win_side * sqrt(1 + slope*slope);
    rounded_frustum(bottom - 2*s, height - win_top,
                    max(top_r - win_side, 0), max(corner_r - s, 0.01));
}

module frustum(b, t, h, z0 = 0, c = corner_r)
    hull() {
        translate([0, 0, z0])     linear_extrude(0.01) rsq(b, c);
        translate([0, 0, z0 + h]) linear_extrude(0.01) rsq(t, c);
    }

module cavity()
    frustum(bottom - 2*wall, top - 2*wall, height - top_thick + 0.01, -0.01);

module stem()
    difference() {
        translate([0, 0, -stem_extra])
            cylinder(d = stem_d, h = stem_extra + height - top_thick + 0.01);
        translate([0, 0, -stem_extra - 0.01]) {
            translate([-cross_len/2, -cross_w/2, 0]) cube([cross_len, cross_w, cross_depth]);
            translate([-cross_w/2, -cross_len/2, 0]) cube([cross_w, cross_len, cross_depth]);
        }
    }

module solid() difference() { outer(); cavity(); }

module win_region()
    translate([-win_w/2, top/2 - win_in, win_z0])
        cube([win_w, bottom, height + 1]);

module body()   union() { difference() { solid(); win_region(); } stem(); }
module insert() difference() { intersection() { solid(); win_region(); } skin_inner(); }

translate([0, 0, height]) rotate([180, 0, 0]) {
    if (part == "body"   || part == "both") color("dimgray") body();
    if (part == "insert" || part == "both") color("white", 0.7) insert();
}
