"""Apple varieties grown in the orchard and their yield curves."""

enum Variety {
    GALA,
    FUJI,
    BRAEBURN,
    HONEYCRISP
}

sem Variety = "Apple cultivar planted in a row; drives the expected yield per tree.";

"""Expected kg of fruit from a fully mature tree of each variety."""
glob MATURE_KG: dict[str, float] = {
    "GALA": 40.0,
    "FUJI": 50.0,
    "BRAEBURN": 35.0,
    "HONEYCRISP": 30.0
};

"""Fraction of the mature yield a tree gives at a given age in years."""
def age_factor(age: int) -> float {
    if age < 3 {
        return 0.0;
    }
    if age < 6 {
        return 0.5;
    }
    if age <= 20 {
        return 1.0;
    }
    return 0.75;
}
