"""Tokenize a SMILES molecule or reaction."""
def smi_spliter(smi: str) -> list[str] {
    import re;
    pattern = "(\[[^\]]+]|Br?|Cl?|N|O|S|P|F|I|b|c|n|o|s|p|\(|\)|\.|=|#|-|\+|\\\\|\/|:|~|@|\?|>|\*|\$|\%[0-9]{2}|[0-9])";
    regex = re.compile(pattern);
    tokens = [token for token in regex.findall(smi)];
    assert smi == ''.join(tokens);
    return tokens;
}