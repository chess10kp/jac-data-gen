"""Provide possible linker component input data."""
def linkers(sequence_descriptors: Any) -> object {
    return [
        {
            "component_type": "linker_sequence",
            "linker_sequence": sequence_descriptors[0]
        },
        {
            "component_type": "linker_sequence",
            "linker_sequence": sequence_descriptors[1]
        },
        {
            "component_type": "linker_sequence",
            "linker_sequence": sequence_descriptors[2]
        }
    ];
}