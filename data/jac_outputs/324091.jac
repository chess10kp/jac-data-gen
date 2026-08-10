"""

    """
def build_message(missing_scene_paths: Any, update_stac: Any) -> object {
    message_list = [];
    for path in missing_scene_paths {
        landsat_product_id = str(path.strip("/").split("/")[-1]);
        if not landsat_product_id {
            raise Exception(
                f'It was not possible to build product ID from path {path}'
            );
        }
        message_list.append(
            {
                "Message": {
                    "landsat_product_id": landsat_product_id,
                    "s3_location": str(path),
                    "update_stac": update_stac
                }
            }
        );
    }
    return message_list;
}