"""extract the pupil data from the eye traker to get standar deviation,
    mean, and filter the dataset"""
def processPupil(
    pupil_positions: list[list[float | int]],
    pupil_coulmn: int,
    recStartTimeAlt: float,
    filterForConf: bool,
    confidence_threshold: float
) -> tuple[list[float], list[float], list[int], list[float], list[float]] {
    diameters = [];
    frames = [];
    timeStamps = [];
    simpleTimeStamps = [];
    confidence = [];
    confidenceThreshold = 0.1;
    if filterForConf {
        confidenceThreshold = confidence_threshold;
    }
    for row in pupil_positions {
        timeStamp = float(row[0]);
        if float(row[3]) > confidenceThreshold {
            timeStamps.append(timeStamp);
            simpleTimeStamps.append(timeStamp - recStartTimeAlt);
            frames.append(int(row[1]));
            confidence.append(float(row[3]));
            diameters.append(float(row[pupil_coulmn]));
        }
    }
    return (diameters, timeStamps, frames, simpleTimeStamps, confidence);
}