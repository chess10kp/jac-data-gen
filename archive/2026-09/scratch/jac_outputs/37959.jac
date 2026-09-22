"""
count the nests in nest_spec, return 0 if nest_spec is none
"""
def count_nests(
    nest_spec: dict[str, list[dict[str, list] | str | int | float | bool | list[dict[str, list] | str | int | float | bool]]] | str | int | float | bool | list[dict[str, list] | str | int | float | bool] | None
) -> int {
    def count_each_nest(
        spec: dict[str, list[dict[str, list] | str | int | float | bool | list[dict[str, list] | str | int | float | bool]]] | str | int | float | bool | list[dict[str, list] | str | int | float | bool],
        count: int
    ) -> int {
        if isinstance(spec, dict) {
            return count + sum([count_each_nest(alt, count) for alt in spec['alternatives']]);
        }
        return 1;
    }
    return count_each_nest(nest_spec, 0) if nest_spec is not None else 0;
}