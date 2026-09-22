"""
A method to match locations that appear multiple times in the same list
and return year-ordered lists that can then be plotted sequentially
"""
def match_locations(locations: list[dict[str, str | list[str]]]) -> list[list[dict[str, str | list[str]]]] {
    ident = 'Climate Identifier';
    yr = 'Year';
    mon = 'Month';
    matches: list[list[dict[str, str | list[str]]]] = [];
    order_months: list[list[int]] = [[]];
    processed_stations: list[tuple[str, str]] = [];
    try {
        for (i, station1) in enumerate(locations) {
            station_id = station1[ident] as str;
            year = (station1[yr] as list[str])[0];
            if (station_id, year) in processed_stations {
                continue;
            }
            matches.append([]);
            matches[-1].append(station1);
            order_months[-1].append(int((station1[mon] as list[str])[0]));
            for station2 in locations[(i + 1):] {
                if (
                    station_id == (station2[ident] as str)
                    and int(year) == int((station2[yr] as list[str])[0])
                    and int((station1[mon] as list[str])[0]) != int((station2[mon] as list[str])[0])
                ) {
                    matches[-1].append(station2);
                    order_months[-1].append(int((station2[mon] as list[str])[0]));
                }
            }
            processed_stations.append((station_id, year));
        }
        return matches;
    } except ValueError {
        raise Exception("Verify that CSV has valid dates and formatted properly");
    }
}