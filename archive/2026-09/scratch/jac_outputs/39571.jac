"""
    Take the coordinate string from the KML file, and break it up into [[Lat,Lon,Alt],[Lat,Lon,Alt],...]
    """
def process_coordinate_string(str: Any) -> object {
    long_lat_alt_arr = [];
    for point in str.split('\n') {
        if (len(point) > 0) {
            long_lat_alt_arr.append(
                [
                    float(point.split(',')[0]),
                    float(point.split(',')[1]),
                    float(point.split(',')[2])
                ]
            );
        }
    }
    return long_lat_alt_arr;
}