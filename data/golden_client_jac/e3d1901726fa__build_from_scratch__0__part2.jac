::py::
import numpy as np

def complex_calculation(data):
    """Pure Python for performance-critical code."""
    arr = np.array(data)
    return arr.mean(), arr.std()
::py::

with entry {
    (mean, std) = complex_calculation([1, 2, 3, 4, 5]);
    print(f"Mean: {mean}, Std: {std}");
}
