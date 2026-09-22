"""Get processed paths from dictionary."""
def get_processed_paths(image_id: str | int, paths_list: list[dict[str, str | int]]) -> dict[str, str | int] {
  dataset_type_list = paths_list;
  for (indx, item) in enumerate(dataset_type_list) {
    if item['id'] == image_id {
      path_subdict = dataset_type_list[indx];
      break;
    }
  } else {
    raise KeyError(f"The item {image_id} was not found in the dataset.");
  }
  return path_subdict;
}