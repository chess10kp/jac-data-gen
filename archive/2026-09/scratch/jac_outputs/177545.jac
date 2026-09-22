"""Transform keras activation function name into full activation function name."""
def get_activation_function(function_name: str) -> str {
    translation_dict = {
        'relu': 'Rectified Linear Unit',
        'linear': 'Linear',
        'elu': 'Exponential Linear Unit',
        'exponential': 'Exponential',
        'selu': 'Scaled Exponential Linear Unit',
        'tanh': 'Hyperbolic Tangent',
        'sigmoid': 'Sigmoid',
        'hard_sigmoid': 'Hard Sigmoid',
        'softmax': 'Softmax',
        'softplus': 'Softplus',
        'softsign': 'Softsign'
    };
    return translation_dict.get(function_name, function_name.capitalize());
}