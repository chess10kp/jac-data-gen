::py::
import numpy as np

def complex_calculation(data):
    arr = np.array(data)
    return arr.mean(), arr.std()
::py::

with entry {
    result = complex_calculation([1, 2, 3, 4, 5]);
    print(result);
}
