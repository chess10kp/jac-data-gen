"""Car informations."""
def make_car(manufactory: str, `type: str, **car_info: str) -> dict[str, str] {
    car_info = {};
    car_info['car_manufactory'] = manufactory;
    car_info['car_type'] = `type;
    for (key, value) in car_info.items() {
        car_info[key] = value;
    }
    return car_info;
}