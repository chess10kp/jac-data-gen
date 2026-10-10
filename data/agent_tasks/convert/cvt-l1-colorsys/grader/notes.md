# cvt-l1-colorsys
Source: CPython v3.12.7 Lib/colorsys.py (PSF-2.0). Hidden tests = upstream test_colorsys.py
ported 1:1 (roundtrips over the 0..1 step 0.2 grid, value tables, gh-106498 near-white) + an
explicit clamp probe. Negatives: hsv sector swap, gh-106498 regression, dropped clamp, hue offset.
Fidelity: all 6 functions must be defined in the workspace; `import colorsys` is forbidden.
