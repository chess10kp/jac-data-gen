def calculate_volume(radius: Any) -> object {
    step = 0.001;
    volume = 0;
    for x in range(int((radius * 1000))) {
        height = math.sqrt(((radius ** 2) - ((x / 1000) ** 2)));
        area = math.pi * ((x / 1000) ** 2);
        volume += area * step;
    }
    return round(volume);
}



with entry {
    print(calculate_volume(0));
}
