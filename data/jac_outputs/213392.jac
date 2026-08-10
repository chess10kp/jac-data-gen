"""This function is extremely reliant on the output format of
    resnet_18/classify_images.py"""
def parse_results_for_matching_tag(output: str, image_tag: str) -> bool {
    found = False;
    if image_tag in output {
        top_match = output.split("\n")[1];
        if image_tag in top_match {
            found = True;
        }
    }
    return found;
}