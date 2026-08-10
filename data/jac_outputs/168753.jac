"""
    since bertMaskedLM output "a,x,b,c,noise,noise", we truncate them
    """
def postprocess(preds: list[str], src: list[dict[str, list[int]]]) -> list[str] {
    return ["".join(preds[i].split())[:len(src[i]["input_ids"]) - 2] for i in range(len(src))];
}