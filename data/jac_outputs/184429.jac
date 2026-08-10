"""Returns a string phrase describing what types are allowed"""
def get_valid_classes_phrase(input_classes: list[type]) -> str {
    all_classes = sorted(list(input_classes), key=lambda (cls: type) { cls.__name__ });
    all_class_names = [cls.__name__ for cls in all_classes];
    if len(all_class_names) == 1 {
        return 'is {0}'.format(all_class_names[0]);
    }
    return "is one of [{0}]".format(", ".join(all_class_names));
}