"""Gets rid of noise, where possible. Currently just removes 'AUTO CR - LOG SUMMARY' lines"""
def useful_tokens(tokens: Any) -> object {
    ret_tokens = [];
    lines = {};
    for token in tokens {
        line_key = (token['line_num'], token['par_num'], token['block_num']);
        if (line_key not in lines) {
            lines[line_key] = [];
        }
        lines[line_key].append(token);
    }
    for (pos, toks) in lines.items() {
        line_text = ' '.join(
            [
                t['text']
                for t in toks
                if t['text']
            ]
        );
        if line_text.startswith('AUTO CR - LOG SUMMARY') {
            continue;
        }
        if line_text.startswith('CPD 00') {
            continue;
        }
        for tok in toks {
            ret_tokens.append(tok);
        }
    }
    return ret_tokens;
}