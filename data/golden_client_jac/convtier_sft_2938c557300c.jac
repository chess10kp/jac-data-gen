enum Light {
    RED = "RED",
    GREEN = "GREEN",
    YELLOW = "YELLOW"
}

def next_light(l: Light) -> Light {
    order: dict = {
        Light.RED: Light.GREEN,
        Light.GREEN: Light.YELLOW,
        Light.YELLOW: Light.RED
    };
    return order[l];
}

with entry {
    print(next_light(Light.RED).value);
}
