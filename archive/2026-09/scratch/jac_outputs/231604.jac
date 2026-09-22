"""Get k of TopK for onnx exporting."""
def get_k_for_topk(k: int, size: int) -> int {
    ret_k = -1;
    if k <= 0 or size <= 0 {
        return ret_k;
    }
    if k < size {
        ret_k = k;
    }
    return ret_k;
}