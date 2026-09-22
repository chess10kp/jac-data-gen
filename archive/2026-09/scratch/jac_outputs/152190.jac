"""Since class names don't allow underscore in names, we're parsing them
 out"""
def _filter_out_underscore(object_name: str) -> str {
    object_name if "_" not in object_name else object_name.replace("_", "")
}