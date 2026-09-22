"""
        This function provides a standard representation of mutations to be
        used when services announce themselves
    """
def summarize_mutation(
    mutation_name: str, event: str, inputs: list[str], outputs: list[str], isAsync: bool = False
) -> dict[str, str | bool | list[str]] {
    return dict(
        name=mutation_name, event=event, isAsync=isAsync, inputs=inputs, outputs=outputs
    );
}