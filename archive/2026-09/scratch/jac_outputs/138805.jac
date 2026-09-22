type LroResult = int | str | float | bool | list[int] | dict[str, int] | tuple[int, ...];

"""Order results in the order the user passed them in."""
def order_lro_results(doc_id_order: list[str], combined: list[LroResult]) -> list[LroResult] {
    mapping = [(getattr(item, 'id'), item) for item in combined];
    return [
        pair[1]
        for pair in sorted(
            mapping,
            key=lambda (m: tuple[str, LroResult]) { doc_id_order.index(m[0]); }
        )
    ];
}