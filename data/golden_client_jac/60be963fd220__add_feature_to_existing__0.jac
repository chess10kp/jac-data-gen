enum Unit { PIECE, LB, OZ, CUP, TBSP, TSP, BUNCH, GRAM, ML }

obj Ingredient {
    has name: str,
        quantity: float,
        unit: Unit,
        cost: float,
        carby: bool,
        organic: bool = False;
}
