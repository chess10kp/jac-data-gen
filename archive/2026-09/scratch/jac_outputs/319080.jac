""" Changes Mt. -> Mount """
def fix_mounts(report_city: str) -> str {
    city_components = report_city.split(" ");
    if city_components[0].strip().lower() == "mt." {
        city_components[0] = "Mount";
    }
    return " ".join(city_components);
}