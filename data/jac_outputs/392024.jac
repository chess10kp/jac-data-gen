"""Convert the b1_gradient (T/m) attribute for a quad into SLAC BACT kG units"""
def quad_gradient_to_BACT(b1_gradient: float, l: float) -> float {
    -b1_gradient * 10.0 * l
}