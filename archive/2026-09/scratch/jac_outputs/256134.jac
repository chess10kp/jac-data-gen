"""R10 Determining the surface pressure Pmax (Sec 5.5.4). Assembly state."""
def R10_assembly(FMzul: float, Apmin: float, PG: float) -> float {
    PMmax = min(FMzul / Apmin, PG);
    Sp = PG / PMmax;
    return PMmax;
}