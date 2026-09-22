"""Gets cars properties that change during a trip."""
def get_car_changing_properties(car: dict[str, str | float]) -> dict[str, str | float] {
    return {
        'lat': car['Lat'],
        'lng': car['Lon'],
        'address': car['Address'],
        'fuel': car['Fuel']
    };
}