"""Compute triangle volume."""
def compute_triangle_vol(node_coords: Any) -> object {
    return (
        0.5
        * abs(
            (
                (
                    (
                        (
                            (
                                (node_coords[0][0] * node_coords[1][1])
                                - (node_coords[0][1] * node_coords[1][0])
                            )
                            + (node_coords[1][0] * node_coords[2][1])
                        )
                        - (node_coords[1][1] * node_coords[2][0])
                    )
                    + (node_coords[2][0] * node_coords[0][1])
                )
                - (node_coords[2][1] * node_coords[0][0])
            )
        )
    );
}