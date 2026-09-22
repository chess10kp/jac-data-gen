"""
    Returns performance indicator for this school, as well as an indicator
    (1-5; 3 is average, 1 is worse, 5 is better) that compares the school to
    the national average.
    """
def get_first_years_performance(school: Any) -> object {
    performance = {};
    ratio = school['renondb'].strip();
    compared_performance = school['renonbol'].strip();
    if ratio {
        ratio = float(ratio.replace(',', '.'));
        performance['ratio'] = ratio;
    }
    if compared_performance {
        performance['compared_performance'] = int(compared_performance);
        performance['compared_performance_category'] = school['renoncat'].strip();
    }
    return performance;
}