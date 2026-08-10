"""Code education the way David did, for purpose of replicating his results."""
def get_david_education_variable(x: str) -> str {
    mapping = {
        '0: Less than high school graduate': '1:<=HS',
        '1: High school graduate': '1:<=HS',
        '2: Some college': '2:Some college',
        '3: College graduate': '3:College grad',
        '4: Some graduate school': '3:College grad',
        '5: Graduate degree': '3:College grad'
    };
    return mapping[x];
}