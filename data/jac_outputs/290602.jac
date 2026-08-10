"""Return text labels for the Fashion-MNIST dataset."""
def get_fashion_mnist_labels(labels: Any) -> object {
    text_labels = [
        't-shirt',
        'trouser',
        'pullover',
        'dress',
        'coat',
        'sandal',
        'shirt',
        'sneaker',
        'bag',
        'ankle boot'
    ];
    return [text_labels[int(i)] for i in labels];
}