// ============================================================
//  Rugged Case – parametrisch, reines OpenSCAD (keine Libraries)
//  Stil: Nanuk/Pelican – flacher Deckel, nur gerundete Kanten
//
//  Teile:  part = "assembly" | "base" | "lid" | "latch" | "handle"
//  Achsen: M3-Zylinderkopfschrauben, Kopf versenkt, Gewinde schneidet
//          sich ins Plastik (Längen siehe ECHO beim Rendern)
//  Export: openscad -D 'part="base"' -o base.stl rugged_case.scad
// ============================================================

part = "assembly";      // [assembly, base, lid, latch, handle, latch_test]
lid_open = 35;           // Öffnungswinkel in der Assembly-Ansicht (0..180)
latch_swing = 0;        // Verschluss in der Ansicht aufklappen (Grad, bei geschlossenem Deckel)

// ---------- Hauptmaße (Innenraum) ----------
inner_x    = 220;       // Innenlänge
inner_y    = 220;       // Innenbreite
base_in_h  = 65;        // Innenhöhe Unterteil
lid_in_h   = 25;        // Innenhöhe Deckel

// ---------- Schale ----------
wall       = 2.4;       // Wandstärke
floor_t    = 2.4;       // Boden-/Deckelstärke
corner_r   = 10;        // Radius der senkrechten Ecken (außen)
edge_r     = 5;         // Radius der Boden-/Deckelkanten (außen)

// ---------- Rand (Parting-Line-Wulst) ----------
rim        = 4;         // wie weit der Rand über die Wand ragt
rim_h      = 8;         // Höhe des Randes je Hälfte (unten 45° angefast)

// ---------- Dichtung: Nut (Unterteil) / Feder (Deckel) ----------
groove_w   = 2.2;
groove_d   = 3;
tongue_w   = 1.4;
tongue_h   = 2.5;       // < groove_d -> Platz für Dichtschnur/TPU

// ---------- Rippen ----------
rib_w      = 3;

// ---------- Schrauben (M3 Zylinderkopf, Gewinde schneidet ins Plastik) ----------
screw_len        = 30;   // Scharniere, Hebel-Drehpunkt, Querstift
handle_screw_len = 20;   // Griff
screw_clear_d    = 3.4;  // Durchgangsloch (drehende Teile, Kopfseite)
screw_tap_d      = 2.8;  // Kernloch – Schraube schneidet hier ihr Gewinde
screw_head_d     = 6.0;  // Senkung für den Kopf (DIN 912: 5,5 mm)
screw_head_h     = 3.0;  // Kopfhöhe – Senkung ergibt sich aus Spannweite - Länge

// ---------- Scharnier (hinten) ----------
hinge_r    = 5;         // Radius der Scharnierrollen
hinge_w    = 33;        // Breite eines Scharniers (3 Rollen)
hinge_gap  = 0.4;       // Spalt zwischen Rollen

// ---------- Verschlüsse (vorne): Exzenter / Kniehebel ----------
// Drehpunkt am Deckel, Haken greift unter einen Querstift am Unterteil.
// Beim Zudrücken läuft er über den Totpunkt -> rastet und bleibt zu.
latch_w        = 22;    // Breite eines Verschlusses
latch_t        = 3.2;   // Dicke des Hebels
latch_pr       = 4;     // Radius Drehpunkt (Deckel)
latch_gap      = 0.5;   // seitlicher Spalt Hebel <-> Ohren
ear_w          = 5;     // Breite der Lagerohren / Wangen
keeper_d       = 3;     // Querstift unten = M3-Schraube
keeper_wall    = 1;     // Material zwischen Schraubenkopf-Senkung und Wand
keeper_ear_r   = 4.5;   // Radius der Ohren um den Querstift (> Senkung/2 + 1)
keeper_drop    = 10;    // Trennebene -> Mitte Querstift
latch_overcenter = 8;   // Grad über den Totpunkt im geschlossenen Zustand
latch_preload  = 0.2;   // Vorspannung im geschlossenen Zustand (mm)
hook_t         = 3.5;   // Dicke des Hakens
hook_tip       = 1.0;   // Haken greift so weit über den Kontaktpunkt hinaus

// ---------- Griff (vorne, zwischen den Verschlüssen) ----------
handle          = "auto";  // [auto, yes, no]  auto = nur wenn Platz ist
handle_grip_max = 110;     // gewünschte lichte Griffweite (wird ggf. kleiner)
handle_grip_min = 80;      // darunter kein Griff (Hand passt nicht)
handle_arm      = 32;      // Drehpunkt -> Griffmitte (Platz für die Finger)
handle_r        = 5;       // Radius Drehpunkt = halbe Griffdicke
handle_kw       = 12;      // Breite der Griffarme (12 -> M3x20 passt)
handle_grip_h   = 14;      // Höhe des Griffholms

// Positionen (Abstand von der Mitte) – Scharniere & Verschlüsse
feature_x  = inner_x/2 + wall - corner_r - hinge_w/2 - 8;

// Anzahl Verschlüsse/Scharniere: "auto" = zwei, wenn Platz ist, sonst eins mittig
feature_count = "auto";  // [auto, 2, 1]
feature_w     = max(hinge_w, latch_w + 2*(latch_gap + ear_w));
two_fit       = feature_x - feature_w/2 >= rib_w/2 + 2;
single_feature = feature_count == "1" || (feature_count == "auto" && !two_fit);
feature_xs    = single_feature ? [0] : [-feature_x, feature_x];
n_feat        = len(feature_xs);
function side(x) = x < 0 ? -1 : 1;     // Schraubenkopf zeigt nach außen (mittig: +x)

assert(single_feature || two_fit, "Für 2 Verschlüsse zu schmal – feature_count = \"auto\" oder \"1\"");
assert(inner_x/2 + wall - corner_r >= feature_w/2,
       "Zu schmal: auch ein einzelner Verschluss passt nicht auf die gerade Wand");
if (single_feature) echo("Ein Verschluss + ein Scharnier (mittig)");

$fa = 6; $fs = 0.6;

// ============================================================
//  Abgeleitete Größen
// ============================================================
ox = inner_x + 2*wall;
oy = inner_y + 2*wall;
base_h = base_in_h + floor_t;
lid_h  = lid_in_h  + floor_t;
zp     = base_h;                          // Trennebene (Assembly)

seal_c = (rim - wall)/2;                  // Mitte der Dichtfläche, rel. Außenwand

hinge_y = oy/2 + rim + hinge_r + 0.6;     // Scharnierachse

// --- Verschluss (Assembly-Koordinaten, y/z-Ebene) ---
y_rim      = -(oy/2 + rim);                     // Außenkante Wulst
// Querstift so weit vor der Wand, dass die Kopf-Senkung nicht in die Wand schneidet
latch_K    = [-oy/2 - screw_head_d/2 - keeper_wall, zp - keeper_drop]; // Querstift (Unterteil)
latch_in   = min(y_rim - 0.6, latch_K[0] - keeper_d/2 - 0.5);         // Innenfläche Hebel
latch_P    = [y_rim - latch_pr - 0.5, zp + latch_pr + 0.5];          // Drehpunkt (Deckel)
latch_D    = norm(latch_K - latch_P);
latch_alpha= atan2(latch_K[0] - latch_P[0], latch_P[1] - latch_K[1]); // Winkel P->K zur Senkrechten
latch_phi  = latch_alpha + latch_overcenter;    // Hebelachse geschlossen
latch_u    = [sin(latch_phi), -cos(latch_phi)]; // entlang Hebel (nach unten/innen)
latch_v    = [cos(latch_phi),  sin(latch_phi)]; // quer dazu (nach innen/oben)
latch_h    = latch_D*cos(latch_overcenter) + keeper_d/2 - latch_preload; // P -> Hakenfläche
latch_pc   = -latch_D*sin(latch_overcenter);    // Kontaktpunkt quer (Stift liegt außerhalb der Hebelachse)
latch_bump = latch_D*(1 - cos(latch_overcenter)); // Überdrückung am Totpunkt
latch_p0   = ((latch_in - latch_t/2) - latch_P[0] - latch_h*latch_u[0]) / latch_v[0];
hook_A = latch_P + latch_h*latch_u + latch_p0*latch_v;
hook_B = latch_P + latch_h*latch_u + (latch_pc + hook_tip)*latch_v;
hook_C = hook_B + hook_t*latch_u;
hook_D = hook_A + hook_t*latch_u;
latch_bot = min(hook_C[1], hook_D[1]) - 1;
lid_ear_top = latch_P[1] + latch_pr + (-oy/2 - latch_P[0]);   // 45°-Stütze an der Wand

// --- Griff ---
handle_y  = -(oy/2 + handle_r + 1);       // Drehachse y (1 mm vor der Wand)
handle_zp = zp - rim_h - handle_r - 1;    // Drehachse z (unter dem Wulst)
// Platz zwischen den Lagerohren der Verschlüsse (pro Seite, ab Mitte)
handle_avail = feature_x - latch_w/2 - latch_gap - ear_w - 2;
handle_grip  = min(handle_grip_max, 2*(handle_avail - handle_kw - 0.5 - ear_w));
handle_fits_x = handle_grip >= handle_grip_min;
handle_fits_z = handle_zp - handle_arm - handle_grip_h/2 > edge_r + 1;
handle_on = !single_feature &&
            (handle == "yes" || (handle == "auto" && handle_fits_x && handle_fits_z));

if (handle == "auto" && !handle_on && !single_feature)
    echo(str("Kein Griff: ", !handle_fits_x
        ? str("zu wenig Breite (lichte Weite wäre ", handle_grip, " mm, min ", handle_grip_min, ")")
        : "Unterteil zu flach"));
if (handle_on) echo(str("Griff: lichte Weite ", handle_grip, " mm"));

assert(handle != "yes" || (handle_grip > 20 && handle_fits_z),
       "Griff erzwungen, passt aber nicht");
assert(corner_r > wall + 1, "corner_r zu klein");
assert(edge_r <= corner_r, "edge_r darf nicht größer als corner_r sein");
assert(lid_ear_top <= zp + lid_h - edge_r + 0.5,
       "Deckel zu flach für Verschluss-Lager – lid_in_h erhöhen");
assert(latch_K[1] - keeper_ear_r - 10 > edge_r, "Unterteil zu flach für Verschluss");
assert(keeper_ear_r >= screw_head_d/2 + 1, "keeper_ear_r zu klein für Schraubenkopf");
assert(latch_pr >= screw_head_d/2 + 0.8, "latch_pr zu klein für Schraubenkopf");
assert(hook_B[0] < -oy/2 - 0.5, "Haken stößt an die Wand – latch_overcenter/hook_tip kleiner");
echo(str("Verschluss: Überdrückung am Totpunkt ", latch_bump + latch_preload,
         " mm, geschlossen ", latch_preload, " mm"));

// ============================================================
//  Grundformen
// ============================================================
module rrect(sx, sy, r) {
    offset(r = r) square([sx - 2*r, sy - 2*r], center = true);
}

// Profil einer Ecke für rotate_extrude: rb = unterer, rt = oberer Kantenradius
module corner_profile(r, h, rb, rt) {
    intersection() {
    square([r, h]);
    hull() {
        square([0.01, h]);
        if (rb > 0) translate([r - rb, rb]) circle(rb);
        else square([r, 0.01]);
        if (rt > 0) translate([r - rt, h - rt]) circle(rt);
        else translate([0, h - 0.01]) square([r, 0.01]);
    }
    }
}

// Box zentriert in XY, z = 0..h, gerundete Ecken und Kanten
module rbox(sx, sy, h, r, rb = 0, rt = 0) {
    hull()
        for (ix = [-1, 1], iy = [-1, 1])
            translate([ix*(sx/2 - r), iy*(sy/2 - r), 0])
                rotate_extrude() corner_profile(r, h, rb, rt);
}

// Ring auf der Dichtfläche, c = Mittenversatz zur Außenwand
module seal_ring(c, w) {
    difference() {
        rrect(ox + 2*(c + w/2), oy + 2*(c + w/2), corner_r + c + w/2);
        rrect(ox + 2*(c - w/2), oy + 2*(c - w/2), corner_r + c - w/2);
    }
}

// 2D-Profil in (y,z) entlang X extrudieren, x von x0 bis x0+w
module extrude_x(x0, w) {
    translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(w) children();
}

// ============================================================
//  Halbschale (Unterteil und Deckel sind gleich aufgebaut)
//  lokale Koordinaten: z=0 Außenseite (Boden bzw. Deckeloberseite),
//  z=h Trennebene
// ============================================================
module rim_band(h) {
    hull() {
        translate([0, 0, h - rim_h]) linear_extrude(0.01) rrect(ox, oy, corner_r);
        translate([0, 0, h - rim_h + rim])
            linear_extrude(rim_h - rim) rrect(ox + 2*rim, oy + 2*rim, corner_r + rim);
    }
}

module ribs(h, front_center = true) {
    intersection() {
        rbox(ox + 2*rim, oy + 2*rim, h, corner_r + rim, edge_r + rim, 0);
        union() {
            // Schmalseiten: zwei Rippen
            for (y = [-oy/4, oy/4])
                translate([-ox, y - rib_w/2, 0]) cube([2*ox, rib_w, h]);
            // Längsseiten: eine Rippe mittig (vorne entfällt sie beim Griff,
            // beide entfallen, wenn Verschluss/Scharnier mittig sitzen)
            if (!single_feature) translate([-rib_w/2, 0, 0]) cube([rib_w, oy, h]);
            if (front_center && !single_feature) translate([-rib_w/2, -oy, 0]) cube([rib_w, oy, h]);
        }
    }
}

module half_shell(h, front_center_rib = true) {
    difference() {
        union() {
            rbox(ox, oy, h, corner_r, edge_r, 0);
            rim_band(h);
            ribs(h, front_center_rib);
        }
        translate([0, 0, floor_t])
            rbox(inner_x, inner_y, h, corner_r - wall, max(edge_r - wall, 0.5), 0);
    }
}

// ============================================================
//  Scharnier
// ============================================================
hseg_w = (hinge_w - 2*hinge_gap) / 3;

module knuckle(x0, w, h) {
    difference() {
        union() {
            hull() {
                translate([x0, oy/2 - wall/2, h - 3.5*hinge_r]) cube([w, wall/2, 3.5*hinge_r]);
                intersection() {
                    translate([x0, hinge_y, h]) rotate([0, 90, 0]) cylinder(r = hinge_r, h = w);
                    translate([x0 - 1, 0, 0]) cube([w + 2, oy, h]);
                }
            }
            translate([x0, hinge_y, h]) rotate([0, 90, 0]) cylinder(r = hinge_r, h = w);
        }
    }
}

// segs: welche Rollen (0,1,2) diese Hälfte bekommt
module hinges(h, segs) {
    for (hx = feature_xs, i = segs)
        knuckle(hx - hinge_w/2 + i*(hseg_w + hinge_gap), hseg_w, h);
}

// ============================================================
//  Verschluss: Lagerohren (Unterteil), Rastnase (Deckel), Bügel
//  alles in Assembly-Koordinaten
// ============================================================
// Lagerohr an der Vorderwand: x0..x0+ear_w, Achse (y,z), Radius r
module ear(x0, y, z, r) {
    difference() {
        hull() {
            translate([x0, -oy/2, z - r - 10]) cube([ear_w, wall/2, 10 + 2*r]);
            translate([x0, y, z]) rotate([0, 90, 0]) cylinder(r = r, h = ear_w);
        }
    }
}

// Ohren am Unterteil für den Querstift
module latch_ears() {
    for (lx = feature_xs, s = [-1, 1])
        ear((s < 0) ? lx - latch_w/2 - latch_gap - ear_w : lx + latch_w/2 + latch_gap,
            latch_K[0], latch_K[1], keeper_ear_r);
}

// Lagerohren am Deckel (Assembly-Koordinaten). Stütze zur Wand unter 45°,
// damit sie kopfüber ohne Support druckbar sind.
module lid_latch_ears() {
    for (lx = feature_xs, s = [-1, 1]) {
        x0 = (s < 0) ? lx - latch_w/2 - latch_gap - ear_w : lx + latch_w/2 + latch_gap;
        difference() {
            hull() {
                translate([x0, -oy/2, zp + 0.5]) cube([ear_w, wall/2, lid_ear_top - zp - 0.5]);
                translate([x0, latch_P[0], latch_P[1]]) rotate([0, 90, 0])
                    cylinder(r = latch_pr, h = ear_w);
            }
        }
    }
}

// Wangen (Rippen) links/rechts der Verschlüsse, lokale Koordinaten
// (z=0 Außenseite). Wie die Rippen an die gerundete Kontur angepasst.
module latch_cheeks(h) {
    intersection() {
        rbox(ox + 2*rim, oy + 2*rim, h, corner_r + rim, edge_r + rim, 0);
        for (lx = feature_xs, s = [-1, 1])
            translate([s < 0 ? lx - latch_w/2 - latch_gap - ear_w : lx + latch_w/2 + latch_gap,
                       -oy/2 - rim - 1, 0])
                cube([ear_w, rim + 1 + wall/2, h - 0.5]);
    }
}

// Hebelprofil (y/z), geschlossene Stellung
module latch_profile() {
    difference() {
        union() {
            hull() {
                translate(latch_P) circle(r = latch_pr);
                translate([latch_in - latch_t, latch_P[1] - latch_pr]) square([latch_t, latch_pr]);
            }
            translate([latch_in - latch_t, latch_bot])
                square([latch_t, latch_P[1] - latch_bot]);
            // Haken mit kleiner Einlauffase an der Spitze
            intersection() {
                polygon([hook_A, hook_B - 0.6*latch_v, hook_B + 0.6*latch_u, hook_C, hook_D]);
                translate([-oy, -1000]) square([oy/2 - 0.6, 2000]);   // nicht in die Wand
            }
            // Grifflasche unten nach außen
            translate([latch_in - latch_t - 4, latch_bot]) square([4.01, 5]);
        }
        translate(latch_P) circle(d = screw_clear_d);
    }
}

// angle: Hebel um seinen Drehpunkt nach außen aufgeklappt (Grad)
module latch_assembled(angle = 0) {
    for (lx = feature_xs)
        translate([0, latch_P[0], latch_P[1]]) rotate([-angle, 0, 0])
            translate([0, -latch_P[0], -latch_P[1]])
                extrude_x(lx - latch_w/2, latch_w) latch_profile();
}

// ============================================================
//  Klappgriff: hängt in Ruhe flach vor der Wand, klappt zum Tragen
//  heraus. Pro Seite ein Arm zwischen zwei Lagerohren (Stift wie
//  beim Verschluss, Länge ca. 2*ear_w + handle_kw + 1).
//  Assembly-Koordinaten, hängende Position.
// ============================================================
handle_xi = handle_grip/2;                 // Innenkante der Arme

module handle_ears() {
    for (s = [-1, 1]) {
        ear(s > 0 ? handle_xi - 0.5 - ear_w : -handle_xi + 0.5,
            handle_y, handle_zp, handle_r);
        ear(s > 0 ? handle_xi + handle_kw + 0.5 : -handle_xi - handle_kw - 0.5 - ear_w,
            handle_y, handle_zp, handle_r);
    }
}

module grip_section() {
    translate([handle_y, handle_zp - handle_arm])
        offset(r = 3) square([2*handle_r - 6, handle_grip_h - 6], center = true);
}

module handle_body() {
    difference() {
        union() {
            // Arme: Kreis um die Drehachse -> Griffholm
            for (x0 = [-handle_xi - handle_kw, handle_xi])
                extrude_x(x0, handle_kw) hull() {
                    translate([handle_y, handle_zp]) circle(r = handle_r);
                    grip_section();
                }
            // Griffholm
            extrude_x(-handle_xi - 0.01, handle_grip + 0.02) grip_section();
        }
        translate([-handle_xi - handle_kw - 1, handle_y, handle_zp]) rotate([0, 90, 0])
            cylinder(d = screw_clear_d, h = handle_grip + 2*handle_kw + 2);
    }
}

// ============================================================
//  Schraubenlöcher (Assembly-Koordinaten)
//  xh = Außenfläche auf der Kopfseite, dir = Richtung in die Schraube zeigt.
//  Kopfseite: Senkung + Durchgangsloch, letztes Element: Kernloch.
// ============================================================
module screw_cut(xh, dir, y, z, span, len, tap_len) {
    cb = span - len;
    translate([xh, y, z]) mirror([dir < 0 ? 1 : 0, 0, 0]) rotate([0, 90, 0]) {
        translate([0, 0, -1]) cylinder(d = screw_head_d, h = cb + 1);
        translate([0, 0, -1]) cylinder(d = screw_clear_d, h = span - tap_len + 1);
        cylinder(d = screw_tap_d, h = span + 1);
    }
}

latch_span  = latch_w + 2*(latch_gap + ear_w);
handle_span = 2*(ear_w + 0.5) + handle_kw;

// Kopf jeweils außen (Richtung Ecke) – dort kommt man mit dem Schraubendreher hin
module hinge_screw_cuts() {
    for (hx = feature_xs)
        screw_cut(hx + side(hx)*hinge_w/2, -side(hx), hinge_y, zp, hinge_w, screw_len, hseg_w);
}
module keeper_screw_cuts() {
    for (lx = feature_xs)
        screw_cut(lx + side(lx)*latch_span/2, -side(lx), latch_K[0], latch_K[1],
                  latch_span, screw_len, ear_w);
}
module pivot_screw_cuts() {
    for (lx = feature_xs)
        screw_cut(lx + side(lx)*latch_span/2, -side(lx), latch_P[0], latch_P[1],
                  latch_span, screw_len, ear_w);
}
// Griff: Kopf innen (von der Grifföffnung her zugänglich)
module handle_screw_cuts() {
    for (s = [-1, 1])
        screw_cut(s*(handle_xi - 0.5 - ear_w), s, handle_y, handle_zp,
                  handle_span, handle_screw_len, ear_w);
}

function cb_ok(span, len, first) = span - len >= 0 && span - len <= first - 1.5;
assert(cb_ok(hinge_w, screw_len, hseg_w),
       str("Scharnier: Spannweite ", hinge_w, " passt nicht zu M3x", screw_len));
assert(cb_ok(latch_span, screw_len, ear_w),
       str("Verschluss: Spannweite ", latch_span, " passt nicht zu M3x", screw_len));
assert(!handle_on || cb_ok(handle_span, handle_screw_len, ear_w),
       str("Griff: Spannweite ", handle_span, " passt nicht zu M3x", handle_screw_len));
echo(str("Schrauben M3 Zylinderkopf: ",
         n_feat, "x M3x", screw_len, " (Scharnier), ",
         n_feat, "x M3x", screw_len, " (Hebel-Drehpunkt), ",
         n_feat, "x M3x", screw_len, " (Querstift)",
         handle_on ? str(", 2x M3x", handle_screw_len, " (Griff)") : ""));

// ============================================================
//  Teile
// ============================================================
module base() {
    difference() {
        union() {
            half_shell(base_h, !handle_on);
            hinges(base_h, [0, 2]);
            latch_ears();
            latch_cheeks(base_h);
            if (handle_on) handle_ears();
        }
        translate([0, 0, base_h - groove_d]) linear_extrude(groove_d + 1)
            seal_ring(seal_c, groove_w);
        hinge_screw_cuts();
        keeper_screw_cuts();
        if (handle_on) handle_screw_cuts();
    }
}

// Deckel in Druckorientierung (Oberseite auf z=0)
module lid() {
    difference() {
        union() {
            half_shell(lid_h);
            hinges(lid_h, [1]);
            translate([0, 0, lid_h - 0.01]) linear_extrude(tongue_h + 0.01)
                seal_ring(seal_c, tongue_w);
            // Assembly -> lokal: z' = base_h + lid_h - z
            translate([0, 0, base_h + lid_h]) mirror([0, 0, 1]) lid_latch_ears();
            latch_cheeks(lid_h);
        }
        translate([0, 0, base_h + lid_h]) mirror([0, 0, 1]) {
            hinge_screw_cuts();
            pivot_screw_cuts();
        }
    }
}

module latch_print() {
    linear_extrude(latch_w) translate(-latch_P) latch_profile();
}

// ------------------------------------------------------------
// Verschluss-Test: Ausschnitt aus Unterteil und Deckel um einen
// Verschluss (rechts) + ein Hebel, alles in Druckorientierung.
// Schrauben: 2x M3x30 (Querstift + Drehpunkt).
// ------------------------------------------------------------
test_margin = 6;    // Rand links/rechts neben den Ohren
test_depth  = 20;   // so weit reicht Boden/Deckelfläche nach innen (Steifigkeit)

test_x = feature_xs[n_feat - 1];

module test_window(h) {
    translate([test_x - latch_span/2 - test_margin, -oy/2 - 30, -1])
        cube([latch_span + 2*test_margin, 30 + test_depth, h + 10]);
}

module latch_test() {
    w = latch_span + 2*test_margin;
    // Unterteil-Stück, aufrecht
    translate([-test_x, oy/2, 0])
        render() intersection() { base(); test_window(base_h); }
    // Deckel-Stück, kopfüber (wie der ganze Deckel)
    translate([-test_x + w + 10, oy/2, 0])
        render() intersection() { lid(); test_window(lid_h); }
    // Hebel, auf der Seite liegend
    translate([-w/2 - 25, 0, 0]) latch_print();
}

// flach liegend drucken (Griffebene aufs Bett)
module handle_print() {
    rotate([90, 0, 0]) translate([0, -(handle_y - handle_r), -handle_zp]) handle_body();
}

module assembly() {
    // render(): Teile vorab als Mesh berechnen, sonst wird der CSG-Baum
    // für die F5-Vorschau zu groß und OpenSCAD zeigt Booleans nicht mehr an.
    color("DimGray") render() base();
    translate([0, hinge_y, zp]) rotate([-lid_open, 0, 0]) translate([0, -hinge_y, -zp]) {
        color("SlateGray")
            translate([0, 0, base_h + lid_h]) mirror([0, 0, 1]) render() lid();
        color("Orange") latch_assembled(lid_open > 0 ? 40 : latch_swing);
    }
    // Querstift-Schrauben
    color("Silver") for (lx = feature_xs)
        translate([lx - latch_w/2 - latch_gap - ear_w, latch_K[0], latch_K[1]]) rotate([0, 90, 0])
            cylinder(d = keeper_d, h = latch_w + 2*(latch_gap + ear_w));
    if (handle_on) color("Orange") handle_body();
}

if      (part == "base")  render() base();
else if (part == "lid")   render() lid();
else if (part == "latch") latch_print();
else if (part == "latch_test") latch_test();
else if (part == "handle") { if (handle_on) handle_print(); }
else if (part == "assembly") assembly();
