import from byllm.lib { Video }

obj VideoAnalysis {
    has summary: str;
    has key_events: list[str];
    has duration_estimate: str;
    has content_type: str;
    has sentiment: str;
}

"""Analyze this video and extract key information."""
def analyze_video(video: Video) -> VideoAnalysis by llm();
