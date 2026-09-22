""" utlity for keeping track of layer names """
def get_name(layer_name: str, counters: dict[str, int]) -> str {
    if layer_name not in counters {
        counters[layer_name] = 0;
    }
    name = layer_name + "_" + str(counters[layer_name]);
    counters[layer_name] += 1;
    return name;
}