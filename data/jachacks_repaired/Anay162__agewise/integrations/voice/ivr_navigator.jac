"""IVR navigator — handles interactive voice response menu traversal for call agents."""

import from types.voice_types { IVR_INTENTS }

glob MAX_ATTEMPTS: int = 3;
glob HOLD_TIMEOUT_SECONDS: int = 300;  # 5 min max hold

"""
Build an IVR navigation script for a specific call target.
target: "CLAIM_STATUS" | "BILLING" | "APPEALS" | "REPRESENTATIVE"
Returns ordered list of navigation steps with expected prompts and responses.
"""
def build_navigation_script(target: str, insurer_name: str) -> list[dict] {
    base_steps = [
        {
            "step": "answer_greeting",
            "listen_for": ["press", "say", "welcome", "thank you for calling"],
            "action": "wait",
            "timeout": 8
        },
        {
            "step": "main_menu",
            "listen_for": ["main menu", "press 1", "for claims"],
            "action": "dtmf",
            "response": _get_menu_response(target),
            "timeout": 10
        }
    ];
    if target == "REPRESENTATIVE" {
        base_steps.append({
            "step": "request_agent",
            "listen_for": ["representative", "agent", "hold", "next available"],
            "action": "say",
            "response": "Representative",
            "timeout": 5
        });
        base_steps.append({
            "step": "wait_for_agent",
            "listen_for": ["hello", "this is", "how can I help", "thank you for holding"],
            "action": "wait_for_human",
            "timeout": HOLD_TIMEOUT_SECONDS
        });
    }
    return base_steps;
}

"""Return the DTMF/speech response for a given navigation target."""
def _get_menu_response(target: str) -> str {
    target_map = {
        "CLAIM_STATUS": "1",
        "BILLING": "2",
        "PROVIDER": "3",
        "BENEFITS": "4",
        "APPEALS": "5",
        "REPRESENTATIVE": "0"
    };
    return target_map.get(target, "0");
}

"""
Analyze a transcript segment to detect if a human agent has answered.
Returns True if human pickup is detected.
"""
def detect_human_pickup(transcript_segment: str) -> bool {
    human_indicators = [
        "this is", "my name is", "how can i help", "how may i help",
        "thank you for holding", "thank you for your patience",
        "claims department", "billing department", "customer service"
    ];
    lower_text = transcript_segment.lower();
    return any(indicator in lower_text for indicator in human_indicators);
}

"""Detect if the call reached a voicemail system."""
def detect_voicemail(transcript_segment: str) -> bool {
    voicemail_indicators = [
        "leave a message", "not available", "voicemail", "after the tone",
        "after the beep", "press 1 to leave a message", "mailbox is full"
    ];
    lower_text = transcript_segment.lower();
    return any(indicator in lower_text for indicator in voicemail_indicators);
}

"""Return phrases that indicate being on hold (for transcript analysis)."""
def get_hold_music_detector() -> list[str] {
    return [
        "your call is important",
        "please continue to hold",
        "all representatives are busy",
        "estimated wait time",
        "you are number",
        "in the queue"
    ];
}
