"""Cut irrelevant end points, scale to pixel space and store as integer."""
def clean_strokes(sample_strokes: list[list[float | int]], factor: int = 100) -> list[list[int]] {
    copy_stroke = [];
    added_final = False;
    for stroke in sample_strokes {
        finish_flag = int(stroke[4]);
        if finish_flag == 0 {
            copy_stroke.append([
                int(round(stroke[0] * factor)),
                int(round(stroke[1] * factor)),
                int(stroke[2]),
                int(stroke[3]),
                finish_flag
            ]);
        } else {
            copy_stroke.append([0, 0, 0, 0, 1]);
            added_final = True;
            break;
        }
    }
    if not added_final {
        copy_stroke.append([0, 0, 0, 0, 1]);
    }
    return copy_stroke;
}