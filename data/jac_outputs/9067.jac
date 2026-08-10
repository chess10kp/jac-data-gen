"""get the subset windows of each patch."""
def sliding_window(
    image_width: int,
    image_height: int,
    patch_w: int,
    patch_h: int,
    adj_overlay_x: int = 0,
    adj_overlay_y: int = 0
) -> list[tuple[int, int, int, int]] {
    f_obj = open('split_image_info.txt', 'w');
    f_obj.writelines(
        '### This file is created by split_image.py. mosaic_patches.py need it. Do not edit it\n'
    );
    f_obj.writelines('image_width: %d\n' % image_width);
    f_obj.writelines('image_height: %d\n' % image_height);
    f_obj.writelines('expected patch_w: %d\n' % patch_w);
    f_obj.writelines('expected patch_h: %d\n' % patch_h);
    f_obj.writelines('adj_overlay_x: %d\n' % adj_overlay_x);
    f_obj.writelines('adj_overlay_y: %d\n' % adj_overlay_y);
    count_x = (image_width - 2 * adj_overlay_x) // patch_w;
    count_y = (image_height - 2 * adj_overlay_y) // patch_h;
    patch_boundary: list[tuple[int, int, int, int]] = [];
    for i in range(0, count_x) {
        f_obj.write('column %d:' % i);
        for j in range(0, count_y) {
            f_obj.write(' %d' % (i * count_y + j));
            xoff = i * patch_w + (image_width - count_x * patch_w - 2 * adj_overlay_x) // 2;
            yoff = j * patch_h + (image_height - count_y * patch_h - 2 * adj_overlay_y) // 2;
            xsize = patch_w + 2 * adj_overlay_x;
            ysize = patch_h + 2 * adj_overlay_y;
            patch_boundary.append((xoff, yoff, xsize, ysize));
        }
        f_obj.write('\n');
    }
    f_obj.close();
    return patch_boundary;
}