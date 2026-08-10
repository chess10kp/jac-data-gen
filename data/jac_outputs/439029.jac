"""Transpose a ttx classDef

    {glyph_name: idx, glyph_name: idx} --> {idx: [glyph_name, glyph_name]}

    Classdef 0 is not defined in the font. It is created by subtracting
    the glyphs found in the lookup coverage against all the glyphs used to
    define the other classes."""
def _kern_class(class_definition: Any, coverage_glyphs: Any) -> object {
    classes = {};
    seen_glyphs = `set();
    for (glyph, idx) in class_definition.items() {
        if (idx not in classes) {
            classes[idx] = [];
        }
        classes[idx].append(glyph);
        seen_glyphs.add(glyph);
    }
    classes[0] = `set(coverage_glyphs) - seen_glyphs;
    return classes;
}