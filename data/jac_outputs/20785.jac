def model_has_predict_function(model: object) -> bool {
    hasattr(model, 'predict')
}