"""
Extracts the name of the layer, which is compared against the config values for
`first_conv` and `classifier`.

The input is, e.g., name="res_net/remove/fc/kernel:0". We want to extract "fc".
"""
def _get_layer_name(name: str) -> str {
    name = name.replace(":0", "");
    name = name.replace("/remove/", "/");
    name = name.split("/", 1)[-1];
    name = name.rsplit("/", 1)[0];
    return name;
}