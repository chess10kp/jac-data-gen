"""Template for feature behaviour reason generated from DICE."""
def generic_type_template(
    tipo: str, name: str, behaviour: str, result0: str, result1: str
) -> str {
    dict_type = {
        "category": f"{name} {behaviour} from {result0} to {result1}.",
        "continuous": f"{name} {behaviour} from {result0} to {result1}"
    };
    return dict_type[tipo].format(
        name=name, behaviour=behaviour, result0=result0, result1=result1
    );
}