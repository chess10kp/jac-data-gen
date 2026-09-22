"""Return the genome directory name from infra_id and optional arguments."""
def get_genome_dir(
    infra_id: str | int,
    genver: str | int | None = None,
    annver: str | int | None = None,
    key: str | int | None = None
) -> str {
    dirname = f"{infra_id}";
    if genver is not None {
        dirname += f".gnm{genver}";
    }
    if annver is not None {
        dirname += f".ann{annver}";
    }
    if key is not None {
        dirname += f".{key}";
    }
    return dirname;
}