"""CallTranscriber walker — transcribes completed calls and extracts action items."""

import from graph.nodes.phone_call { PhoneCall }
import from integrations.voice.bland_client { get_call_transcript, get_call_recording_url }
import from abilities.llm_abilities { extract_call_action_items }

import from datetime { datetime }

walker CallTranscriber {

    can transcribe with PhoneCall entry {
        if here.outcome == "PENDING" or here.transcript != "" {
            disengage;
        }

        try {
            transcript = get_call_transcript(here.call_id);
            here.transcript = transcript;
            here.recording_url = get_call_recording_url(here.call_id);

            if transcript != "" {
                outcomes = extract_call_action_items(
                    transcript=transcript,
                    call_type=here.call_type,
                    original_dispute=here.outcome_summary
                );
                here.action_items = outcomes.get("commitments", []);
                here.reference_numbers = outcomes.get("reference_numbers", []);
                here.outcome_summary = outcomes.get("outcome_summary", "");
                here.outcome = "RESOLVED" if not outcomes.get("escalation_needed", True) else "ESCALATED";
            }
            print(f"[CallTranscriber] Transcribed call {here.call_id}");
        } except Exception as e {
            print(f"[CallTranscriber] Error transcribing {here.call_id}: {e}");
        }
    }
}
