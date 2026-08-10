"""
    Get the most visibile camera's annotation.
    :param camera_data_dict: Dictionary of form:
      {
        'CAM_BACK': {'attribute_tokens': ['cb5118da1ab342aa947717dc53544259'],
          'bbox_corners': [600.8315617945755,
          426.38901275036744,
          643.6756536789582,
          476.66593163100237],
          'category_name': 'vehicle.bus.rigid',
          'filename': 'samples/CAM_BACK/n015-2018-10-02-10-50-40+0800__CAM_BACK__1538448750037525.jpg',
          'instance_token': '9cba9cd8af85487fb010652c90d845b5',
          'next': 'ef90c2e525244b7d9eeb759837cf2277',
          'num_lidar_pts': 0,
          'num_radar_pts': 0,
          'prev': '6628e81912584a72bd448a44931afb42',
          'sample_annotation_token': '06b4886e79d2435c80bd23e7ac60c618',
          'sample_data_token': '0008443755a14b3ca483f1489c767040',
          'visibility_token': '4'},
        'CAM_FRONT': ...
        ...
      }
    :return: The camera annotation with highest visibility.
    """
def get_most_visible_camera_annotation(camera_data_dict: dict) -> dict {
    best_visibility = '';
    largest_area: float = -1.0;
    best_camera_token = None;
    for camera_token in camera_data_dict {
        visibility = camera_data_dict[camera_token]['visibility_token'] as str;
        bbox_area = camera_data_dict[camera_token]['bbox_area'] as float;
        if visibility > best_visibility or (visibility == best_visibility and bbox_area > largest_area) {
            best_camera_token = camera_token;
            largest_area = bbox_area;
            best_visibility = visibility;
        }
    }
    if not best_camera_token {
        print(
            'Unable to find any good views for camera data dict: {}'.format(
                camera_data_dict
            )
        );
    }
    return camera_data_dict[best_camera_token];
}