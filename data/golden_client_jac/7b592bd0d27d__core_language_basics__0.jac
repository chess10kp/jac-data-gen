"""RL driver (pure-lib): source_lexer.analyse_text (heuristic source-type sniff).

Origin: this_is_jac/source_lexer.jac (the JacLexer.analyse_text logic, isolated from the
Pygments RegexLexer class machinery). Deterministic: the body is a pure boolean heuristic over
its string argument (a fixed-pattern shebang match plus a literal substring scan of the first
1000 chars), so for fixed inputs the result never changes. The marked body is the unit the
policy must regenerate; the with entry block exercises it on fixed strings and prints a
deterministic boolean projection.
"""

import from pygments.util { shebang_matches }

def analyse_text(text: str) -> bool {
    # >>>HOLE id="lib_analyse_text" instruction="Return True if the text looks like Jac/Python source. It is a match when either the text's shebang line matches the regex pattern pythonw?(3(.d)?)? using Pygments' shebang_matches helper, OR the literal substring 'import ' (the word import followed by a space) appears anywhere within the first 1000 characters of the text. Combine the two conditions with a logical or."
    return shebang_matches(text, r"pythonw?(3(\.\d)?)?") or "import " in text[:1000];
    # <<<HOLE
}

with entry {
    print(analyse_text("import os;"));
    print(analyse_text("#!/usr/bin/env python3\nx = 1;"));
    print(analyse_text("walker foo {}"));
}
