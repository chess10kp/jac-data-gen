"""function which adds concat merging of input_names"""
def build_merge(input_names: Any, name: Any, concat_axis: Any) -> object {
    return {
        "class_name": "Merge",
        "name": name,
        "config": {
            "output_mask": None,
            "output_mask_type": "raw",
            "dot_axes": -1,
            "output_shape": None,
            "concat_axis": concat_axis,
            "mode": "concat",
            "name": name,
            "output_shape_type": "raw",
            "arguments": {},
            "mode_type": "raw"
        },
        "inbound_nodes": [[[nm, 0, 0] for nm in input_names]]
    };
}