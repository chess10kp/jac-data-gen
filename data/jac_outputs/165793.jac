""" extract_features function

    Taking one row, extracts all features deemed useful for logistic regression
    and returns them as a list.

    Args
    ----
    row : dict
        A single data point

    Returns
    -------
    list
    """
def extract_features(row: Any) -> object {
    pclass = float(row['Pclass']) if (row['Pclass'] != '') else 0;
    sex = 1 if (row['Sex'] == 'male') else 0;
    age = float(row['Age']) if (row['Age'] != '') else 0;
    sibsp = float(row['SibSp']) if (row['SibSp'] != '') else 0;
    parch = float(row['Parch']) if (row['Parch'] != '') else 0;
    return [pclass, sex, age, sibsp, parch];
}