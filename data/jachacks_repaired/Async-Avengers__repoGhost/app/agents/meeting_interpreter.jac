import from app.services.llm_runtime { llm }
import from app.models.core { MeetingSummary }
include app.services.meeting_parse;

def:pub run_meeting_interpreter(meeting_text: str) -> MeetingSummary {
    return parse_meeting(meeting_text);
}

def:pub llm_meeting_interpreter(_meeting_text: str, _draft: MeetingSummary) -> MeetingSummary by llm();
