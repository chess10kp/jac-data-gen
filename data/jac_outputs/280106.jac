"""def videoQualityToInteger(test_video_quality): -> test_video_quality
    convert str video quality to integer."""
def videoQualityToInteger(test_video_quality: Any) -> object {
    try {
        test_video_quality = str(test_video_quality[:-1]);
        test_video_quality = int(test_video_quality);
        return test_video_quality;
    } except Exception as e {
        return 0;
    }
}