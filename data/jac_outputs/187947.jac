"""
Generate trotterization coefficients for a given number of Trotter steps.

U = exp(A + B) is approximated as exp(w1*o1)exp(w2*o2)... This method returns
a list [(w1, o1), (w2, o2), ... , (wm, om)] of tuples where o=0 corresponds
to the A operator, o=1 corresponds to the B operator, and w is the
coefficient in the exponential. For example, a second order Suzuki-Trotter
approximation to exp(A + B) results in the following
[(0.5/trotter_steps, 0), (1/trotteri_steps, 1),
(0.5/trotter_steps, 0)] * trotter_steps.
"""
def suzuki_trotter(trotter_order: int, trotter_steps: int) -> list[tuple[float, int]] {
    p1 = p2 = p4 = p5 = 1.0 / (4 - (4 ** (1.0 / 3)));
    p3 = 1 - (4 * p1);
    trotter_dict = {
        1: [(1, 0), (1, 1)],
        2: [(0.5, 0), (1, 1), (0.5, 0)],
        3: [
            ((7.0 / 24), 0),
            ((2.0 / 3.0), 1),
            ((3.0 / 4.0), 0),
            ((-2.0 / 3.0), 1),
            ((-1.0 / 24), 0),
            (1.0, 1)
        ],
        4: [
            ((p5 / 2), 0),
            (p5, 1),
            ((p5 / 2), 0),
            ((p4 / 2), 0),
            (p4, 1),
            ((p4 / 2), 0),
            ((p3 / 2), 0),
            (p3, 1),
            ((p3 / 2), 0),
            ((p2 / 2), 0),
            (p2, 1),
            ((p2 / 2), 0),
            ((p1 / 2), 0),
            (p1, 1),
            ((p1 / 2), 0)
        ]
    };
    order_slices = [
        ((x0 / trotter_steps), x1) for (x0, x1) in trotter_dict[trotter_order]
    ];
    return order_slices * trotter_steps;
}