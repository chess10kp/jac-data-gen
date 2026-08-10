"""Returns side or polygon definitions for simple solids."""
def getshapesidedict() -> dict[str, tuple[tuple[int, ...], ...]] {
    return {
        "tetrahedra": ((2, 1, 0), (2, 3, 1), (0, 3, 2), (3, 0, 1)),
        "cube": (
            (1, 2, 3, 0),
            (5, 6, 7, 4),
            (0, 3, 6, 5),
            (4, 7, 2, 1),
            (4, 1, 0, 5),
            (2, 7, 6, 3)
        ),
        "hexahedra": ((2, 3, 1), (0, 3, 2), (3, 0, 1), (1, 4, 2), (2, 4, 0), (1, 0, 4)),
        "octahedra": (
            (1, 2, 0),
            (4, 1, 0),
            (3, 4, 0),
            (2, 3, 0),
            (2, 1, 5),
            (1, 4, 5),
            (4, 3, 5),
            (3, 2, 5)
        )
    };
}