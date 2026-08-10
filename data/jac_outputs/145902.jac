"""Build a car profile."""
def make_car(manufacturer: str, `type: str, **additions: str) -> dict[str, str] {
    car = dict();
    car['manufacturer'] = manufacturer;
    car['type'] = `type;
    for (k, v) in additions.items() {
        car[k] = v;
    }
    return car;
}