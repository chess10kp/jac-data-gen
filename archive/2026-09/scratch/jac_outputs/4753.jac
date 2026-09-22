"""Return JPEG 2000 component sample parameters from a codestream, or {} if invalid."""
def get_j2k_parameters(codestream: bytes) -> dict[str, int | bool] {
    try {
        if codestream[0:2] != b'\xffO' {
            return {};
        }
        if codestream[2:4] != b'\xffQ' {
            return {};
        }
        ssiz = ord(codestream[42:43]);
        parameters = {};
        if ssiz & 128 {
            parameters['precision'] = (ssiz & 127) + 1;
            parameters['is_signed'] = True;
        } else {
            parameters['precision'] = ssiz + 1;
            parameters['is_signed'] = False;
        }
        return parameters;
    } except (IndexError, TypeError) {
        return {};
    }
}