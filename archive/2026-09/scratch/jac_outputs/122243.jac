"""Estimate whether a feature is discrete given the number of records
observed and the cardinality (number of unique values).

The default assumption is that features are not discrete."""
def is_discrete(num_records: int, cardinality: int, p: float = 0.15) -> bool {
    if cardinality >= num_records {
        return False;
    }
    if num_records < 1 {
        return False;
    }
    if cardinality < 1 {
        raise ValueError("Cardinality must be >= 1 for num records >= 1");
    }
    density = num_records / (cardinality + 1);
    return (1 / density) <= p;
}