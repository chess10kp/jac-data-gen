"""Returns a string that can be used with pandas.DataFrame.query"""
def probe_set_name_starts_with_one_of(gene_prefixes: list[str]) -> str {
    return " | ".join(
        f"`Probe.Set.Name`.str.startswith('{prefix}', na=False)"
        for prefix in gene_prefixes
    );
}