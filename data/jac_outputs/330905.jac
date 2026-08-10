"""Get SQL Server syntax for hashed-sampling an id clause."""
def get_sqlserver_hashed_sample_clause(id_clause: str, sample_pct: float) -> str {
    assert 0 < sample_pct < 1, f'{sample_pct} should be a float  in (0,1)';
    int_pct = int(sample_pct * 100);
    rv = f"""
    AND ABS(CAST(HASHBYTES('SHA1',
        {id_clause}) AS BIGINT)) % 100 <= {int_pct}""";
    return rv;
}