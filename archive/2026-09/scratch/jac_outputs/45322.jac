def predict_classify_details(
    img_path: str, ground_true: str, predict_code: str, conf: float
) -> list[dict[str, object]] {
    data = {
        'ground_true': ground_true,
        'predict_code': predict_code,
        'conf': conf
    };
    result = {
        'img_path': img_path,
        'info': [data]
    };
    return [result];
}