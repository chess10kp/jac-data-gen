"""Voice Pipeline — queue calls, execute, transcribe, record outcomes."""

import from graph.nodes.patient { Patient }
import from graph.walkers.voice.call_dispatcher { CallDispatcher }
import from graph.walkers.voice.call_executor { CallExecutor }
import from graph.walkers.voice.call_transcriber { CallTranscriber }
import from graph.walkers.voice.outcome_recorder { OutcomeRecorder }

walker VoicePipeline {
    has dry_run: bool = True;

    can run with Patient entry {
        print(f"[VoicePipeline] Processing calls for: {here.name}");
        here spawn CallDispatcher(
            patient_name=here.name,
            patient_medicare_id=here.medicare_id,
            dry_run=self.dry_run
        );
        here spawn CallTranscriber();
        here spawn OutcomeRecorder();
        print(f"[VoicePipeline] Complete for: {here.name}");
    }
}
