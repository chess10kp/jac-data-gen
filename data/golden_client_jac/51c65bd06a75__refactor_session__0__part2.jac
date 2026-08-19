# analyzer.jac
import pandas as pd;
import numpy as np;
import from sklearn.linear_model { LinearRegression }

def analyze_numpy() {
    arr = np.array([1, 2, 3, 4, 5]);
    print(f"Mean: {np.mean(arr)}");
}

def analyze_pandas() {
    df = pd.DataFrame({"a": [1, 2, 3], "b": [4, 5, 6]});
    print(df.describe());
}

def build_model() -> object {
    return LinearRegression();
}

with entry {
    analyze_numpy();
    analyze_pandas();
    model = build_model();
}
