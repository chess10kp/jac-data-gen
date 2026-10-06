"""Weekly Digest Pipeline — generate and deliver weekly summary."""

import from graph.nodes.patient { Patient }
import from graph.walkers.intake.digest_generator { DigestGenerator }

walker WeeklyDigestPipeline {
    can run with Patient entry {
        print(f"[WeeklyDigestPipeline] Generating digest for: {here.name}");
        here spawn DigestGenerator();
    }
}
