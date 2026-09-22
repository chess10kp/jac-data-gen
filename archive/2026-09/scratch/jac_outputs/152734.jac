"""Return the pycon video list sorted by viewCount"""
def get_most_popular_talks_by_views(videos: Any) -> object {
    return sorted(
        videos, key=lambda (x: Any) { int(x.metrics['viewCount']); }, reverse=True
    );
    ;
}