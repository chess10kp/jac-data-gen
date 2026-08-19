# analyzer.jac
import pandas as pd;
import numpy as np;
import from sklearn.linear_model { LinearRegression }

with entry {
    # NumPy
    arr = np.array([1, 2, 3, 4, 5]);
    print(f"Mean: {np.mean(arr)}");

    # Pandas
    df = pd.DataFrame({"a": [1, 2, 3], "b": [4, 5, 6]});
    print(df.describe());

    # Scikit-learn
    model = LinearRegression();
}
