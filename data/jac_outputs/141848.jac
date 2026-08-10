""" SUMMARY:  creates a list (set) of unique tool names for searching, auto-suggestion, etc.
          INPUT:  a list of two-item tuple (tool, platform)
         OUTPUT:  a de-duplicated list (set) of tool names """
def get_tool_names(tool_list: list[tuple[str, str]]) -> set[str] {
    {x[0] for x in tool_list}
}