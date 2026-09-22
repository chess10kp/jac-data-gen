"""Set a name for a machine."""
def handler(context: dict[str, object], inputs: dict[str, object]) -> dict[str, object] {
    old_name = inputs["resourceNames"][0];
    new_name = inputs["customProperties"]["newName"];
    outputs = {};
    outputs["resourceNames"] = inputs["resourceNames"];
    outputs["resourceNames"][0] = new_name;
    print("Setting machine name from {0} to {1}".format(old_name, new_name));
    return outputs;
}