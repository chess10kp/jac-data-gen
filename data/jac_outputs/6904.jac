"""returns object hash without control characters"""
def get_objhash_from_object_desc(gitobjcontent: str) -> str {
    return gitobjcontent.split(" ")[1][:40];
}