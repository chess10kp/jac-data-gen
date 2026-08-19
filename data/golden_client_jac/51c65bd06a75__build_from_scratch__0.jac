import pandas as pd;
import numpy as np;
import from sklearn.linear_model { LinearRegression }

with entry {
    arr = np.array([1, 2, 3, 4, 5]);
    print(f"Mean: {np.mean(arr)}");
    model = LinearRegression();
}
