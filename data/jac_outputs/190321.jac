"""Takes a type encoding string and outputs a list of the separated type codes.
    Currently does not handle unions or bitfields and strips out any field width
    specifiers or type specifiers from the encoding.  For Python 3.2+, encoding is
    assumed to be a bytes object and not unicode.

    Examples:
    parse_type_encoding('^v16@0:8') --> ['^v', '@', ':']
    parse_type_encoding('{CGSize=dd}40@0:8{CGSize=dd}16Q32') --> ['{CGSize=dd}', '@', ':', '{CGSize=dd}', 'Q']
    """
def parse_type_encoding(encoding: bytes) -> list[bytes] {
    type_encodings = [];
    brace_count = 0;
    bracket_count = 0;
    typecode = b'';
    for c_raw in encoding {
        c = bytes([c_raw]);
        if c == b'{' {
            if typecode and typecode[-1:] != b'^' and brace_count == 0 and bracket_count == 0 {
                type_encodings.append(typecode);
                typecode = b'';
            }
            typecode += c;
            brace_count += 1;
        } elif c == b'}' {
            typecode += c;
            brace_count -= 1;
            assert brace_count >= 0;
        } elif c == b'[' {
            if typecode and typecode[-1:] != b'^' and brace_count == 0 and bracket_count == 0 {
                type_encodings.append(typecode);
                typecode = b'';
            }
            typecode += c;
            bracket_count += 1;
        } elif c == b']' {
            typecode += c;
            bracket_count -= 1;
            assert bracket_count >= 0;
        } elif brace_count or bracket_count {
            typecode += c;
        } elif c in b'0123456789' {
            ;
        } elif c in b'rnNoORV' {
            ;
        } elif c in b'^cislqCISLQfdBv*@#:b?' {
            if typecode and typecode[-1:] == b'^' {
                typecode += c;
            } else {
                if typecode {
                    type_encodings.append(typecode);
                }
                typecode = c;
            }
        }
    }
    if typecode {
        type_encodings.append(typecode);
    }
    return type_encodings;
}