"""Return a list object representation of the output from cflow

    Example:
    If cflow_output is:
    main() <int () at main.c:18>:
        f() <int () at main.c:4>:
            malloc()
            printf()

    Then this function will return:
    ['main() <int () at main.c:18>:',
    ['f() <int () at main.c:4>:', ['malloc()', 'printf()']]]

    Parameters:
    cflow_output: string
    """
import from tokenize { NEWLINE, INDENT, DEDENT, tokenize }
import io;

def get_list_representation(cflow_output: str) -> list[object] {
    stack = [[]];
    lastindent = len(stack);

    def push_new_list -> int {
        stack[-1].append([]);
        stack.append(stack[-1][-1]);
        return len(stack);
    }

    readl = io.BytesIO(cflow_output.encode('utf-8')).readline;
    for t in tokenize(readl) {
        if t.type == NEWLINE {
            if lastindent != len(stack) {
                stack.pop();
                lastindent = push_new_list();
            }
            stack[-1].append(t.line.strip());
        } elif t.type == INDENT {
            lastindent = push_new_list();
        } elif t.type == DEDENT {
            stack.pop();
        }
    }
    return stack[-1];
}