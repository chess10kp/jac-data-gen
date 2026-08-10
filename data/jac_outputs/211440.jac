"""Return true if obj has a non-property attribute 'attr'."""
def hasNonPropertyAttr(`obj: Any, attr: Any) -> object {
    if (
        hasattr(`obj, attr)
        and (
            not hasattr(`type(`obj), attr)
            or not isinstance(getattr(`type(`obj), attr), property)
        )
    ) {
        return True;
    } else {
        return False;
    }
}