""" Flatten all the captions into a single list """
def flatten(captions_list: list[list[str]]) -> list[str] {
    return [caption for captions in captions_list for caption in captions];
}