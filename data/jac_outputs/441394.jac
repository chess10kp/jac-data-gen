"""Build a choropleth hover label from a row's median rent."""
def create_label_column(row: dict[str, float | int]) -> str {
    rent = row["Median Rent (SEK)"];
    if rent > 0 {
        return "Median Cost: " + str(int(rent)) + " SEK";
    }
    return "Missing Data";
}