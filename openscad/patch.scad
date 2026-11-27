// =====================================================
//  Klett-Patch  –  2 Farben, 2 Layer PETG
//  part = "basis"  -> Platte mit ausgestanzter Schrift
//  part = "text"   -> nur die Schrift (passt exakt rein)
//  part = "beide"  -> Vorschau
// =====================================================

part = "beide";             // "basis" | "text" | "beide"

// ---- Form & Größe (mm) ----
form    = "rechteck";       // "rechteck" | "oval"
breite  = 100;
hoehe   = 50;
radius  = 6;                // Eckenradius (nur Rechteck)

// ---- Schichten ----
layer_hoehe = 0.2;          // = Layerhöhe im Slicer!
layers      = 2;
dicke       = layer_hoehe * layers;

// true  = Schrift geht durch beide Layer (beidseitig sichtbar)
// false = unterster Layer bleibt durchgehend Basisfarbe,
//         Schrift nur im oberen Layer (stabiler, empfohlen)
text_durch = false;

// ---- Text ----
zeilen        = ["MEIN", "PATCH"];  // eine oder mehrere Zeilen
schrift       = "Liberation Sans:style=Bold";
text_groesse  = 12;         // Buchstabenhöhe pro Zeile
zeilenabstand = 1.3;        // Faktor
rand          = 6;          // freier Rand zum Umnähen
an_breite_anpassen = false; // true = Text auf volle Breite strecken (Höhe prüfen!)

// ---------------------------------------------------
$fn = 64;
eps = 0.01;

module umriss() {
    if (form == "oval")
        scale([breite/2, hoehe/2]) circle(r = 1, $fn = 128);
    else
        offset(r = radius) offset(delta = -radius)
            square([breite, hoehe], center = true);
}

module text_roh() {
    n = len(zeilen);
    for (i = [0 : n-1])
        translate([0, ((n-1)/2 - i) * text_groesse * zeilenabstand])
            text(zeilen[i], size = text_groesse, font = schrift,
                 halign = "center", valign = "center");
}

module text_2d() {
    // beim Oval ist die nutzbare Breite etwas kleiner
    max_b = (form == "oval" ? breite * 0.75 : breite) - 2*rand;
    max_h = (form == "oval" ? hoehe  * 0.75 : hoehe ) - 2*rand;
    if (an_breite_anpassen)
        resize([max_b, 0], auto = [true, true]) text_roh();
    else
        text_roh();
    // Hinweis: Wird der Text zu hoch, text_groesse/zeilen anpassen.
    echo(str("Max. Textfläche: ", max_b, " x ", max_h, " mm"));
}

// Höhe des Textbereichs
text_z0 = text_durch ? 0 : layer_hoehe;
text_h  = dicke - text_z0;

module basis() {
    difference() {
        linear_extrude(dicke) umriss();
        translate([0, 0, text_z0 - (text_durch ? eps : 0)])
            linear_extrude(text_h + 2*eps) text_2d();
    }
}

module schrift_teil() {
    translate([0, 0, text_z0])
        linear_extrude(text_h) text_2d();
}

if (part == "basis")  basis();
if (part == "text")   schrift_teil();
if (part == "beide") {
    color("navy")  basis();
    color("gold")  schrift_teil();
}
