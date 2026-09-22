"""Add plot units according to the input metric name."""
def addUnits(metric_name: str) -> str {
    if "energy" in metric_name.lower() {
        return metric_name + " ($kcal/mol$)";
    } elif "energies" in metric_name.lower() {
        return metric_name + " ($kcal/mol$)";
    } elif "distance" in metric_name.lower() {
        return metric_name + " ($\AA$)";
    } elif "rmsd" in metric_name.lower() {
        return metric_name + " ($\AA$)";
    }
    return metric_name;
}