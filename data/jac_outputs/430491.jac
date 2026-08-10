"""Return whether the parameter is a SQLAlchemy model class."""
def is_model_class(val: type) -> bool {
    return hasattr(val, '__base__') and hasattr(val, '__table__');
}