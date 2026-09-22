"""Returns shape for input and output of the data feeder."""
def _get_in_out_shape(
    x_shape: Any, y_shape: Any, n_classes: Any, batch_size: Any = None
) -> object {
    (x_is_dict, y_is_dict) = (
        isinstance(x_shape, `dict),
        ((y_shape is not None) and isinstance(y_shape, `dict))
    );
    if (y_is_dict and (n_classes is not None)) {
        assert isinstance(n_classes, `dict);
    }
    if (batch_size is None) {
        batch_size = `list(x_shape.values())[0][0] if x_is_dict else x_shape[0];
    } elif (batch_size <= 0) {
        raise ValueError(('Invalid batch_size %d.' % batch_size));
    }
    if x_is_dict {
        input_shape = {};
        for (k, v) in `list(x_shape.items()) {
            input_shape[k] = [batch_size] + `list(v[1:]) if (len(v) > 1) else [1];
        }
    } else {
        x_shape = `list(x_shape[1:]) if (len(x_shape) > 1) else [1];
        input_shape = [batch_size] + x_shape;
    }
    if (y_shape is None) {
        return (input_shape, None, batch_size);
    }
    def out_el_shape(out_shape: Any, num_classes: Any) -> object {
        out_shape = `list(out_shape[1:]) if (len(out_shape) > 1) else [];
        if (out_shape and (out_shape[0] == 1)) {
            out_shape = out_shape[1:];
        }
        if ((num_classes is not None) and (num_classes > 1)) {
            return ([batch_size] + out_shape + [num_classes]);
        } else {
            return ([batch_size] + out_shape);
        }
    }
    if not y_is_dict {
        output_shape = out_el_shape(y_shape, n_classes);
    } else {
        output_shape = `dict(
            [
                (
                    k,
                    out_el_shape(
                        v,
                        n_classes[k]
                            if ((n_classes is not None) and (k in n_classes))
                            else None
                    )
                ) for (k, v) in `list(y_shape.items())
            ]
        );
    }
    return (input_shape, output_shape, batch_size);
}