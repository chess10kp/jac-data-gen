enum Unit { PIECE, LB, OZ, CUP, TBSP, TSP, BUNCH }

obj Ingredient {
    has name: str,
        quantity: float,
        unit: Unit,
        cost: float,
        carby: bool;
}
