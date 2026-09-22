"""Filter inter-ligation clusters by distances."""
def filterClusterByDis(
    data: dict[str, dict[str, list[list[float]]]],
    cut: float
) -> dict[str, dict[str, list[list[float]]]] {
    for key in data {
        nr = [];
        for r in data[key]["records"] {
            d = (r[4] + r[5]) / 2 - (r[1] + r[2]) / 2;
            if d >= cut {
                nr.append(r);
            }
        }
        data[key]["records"] = nr;
    }
    return data;
}