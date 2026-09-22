"""Use majority vote to pick the consensus sequence."""
def get_consensus_through_voting(seq1: str, weight1: int, seq2: str, weight2: int) -> str {
    return seq1 if weight1 > weight2 else seq2;
}