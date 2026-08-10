glob EARTH_RADIUS_KM = 6371.0;

"""calculate the angular radius for a given distance in kilometers"""
def calc_angular_radius(km: float) -> float {
    return km / EARTH_RADIUS_KM;
}