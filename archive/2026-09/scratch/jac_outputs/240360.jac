"""Provides expected result for affected_genes calcprop."""
def affected_gene_result(total: int, contained: int, at_breakpoint: int, omim_genes: int) -> dict[str, str] {
    result = {
        "contained": str(contained) + "/" + str(total),
        "at_breakpoint": str(at_breakpoint) + "/" + str(total),
        "omim_genes": str(omim_genes) + "/" + str(total)
    };
    return result;
}