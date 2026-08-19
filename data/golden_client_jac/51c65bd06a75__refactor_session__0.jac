def analyze_numpy() {
    arr = np.array([1, 2, 3, 4, 5]);
    print(f"Mean: {np.mean(arr)}");
}

def analyze_pandas() {
    df = pd.DataFrame({"a": [1, 2, 3], "b": [4, 5, 6]});
    print(df.describe());
}

def build_model() {
    LinearRegression();
}
