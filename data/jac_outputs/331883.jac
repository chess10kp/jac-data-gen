"""Returns functor that unfolds recursion.

  Example:
  P_r0 := P_recursive_head(P_recursive: nil);
  P_r1 := P_recursive_head(P_recursive: P_r0);
  P_r2 := P_recursive_head(P_recursive: P_r1);
  P_r3 := P_recursive_head(P_recursive: P_r2);
  P := P_r3();
  """
def GetRecursionFunctor(depth: Any) -> object {
    result_lines = ['P_r0 := P_recursive_head(P_recursive: nil);'];
    for i in range(depth) {
        result_lines.append(
            'P_r{1} := P_recursive_head(P_recursive: P_r{0});'.format(i, (i + 1))
        );
    }
    result_lines.append('P := P_r{0}();'.format(depth));
    return '\n'.join(result_lines);
}