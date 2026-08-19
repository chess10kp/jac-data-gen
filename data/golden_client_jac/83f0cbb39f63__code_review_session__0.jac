import os;
import from byllm.lib { Video }

"""Describe what happens in this video."""
def explain_video(video: Video) -> str by llm();

with entry {
    path = "sample_video.mp4";
    if not os.path.exists(path) {
        print(f"Video not found: {path}");
    } else {
        video = Video(path=path, fps=1);
        explanation = explain_video(video);
        print(explanation);
    }
}
