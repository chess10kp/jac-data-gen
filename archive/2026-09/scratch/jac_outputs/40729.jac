""" The function to evaluate if the annotation type
    which can be either Class or Property is correct or not"""
def annotation_evaluator(input_annotation: str, evaluation_type: str) -> bool {
    match evaluation_type {
        case "Class":
            return "@RdfsClass" in input_annotation;
        case "Property":
            return "@RdfProperty" in input_annotation;
        case _:
            return False;
    }
}