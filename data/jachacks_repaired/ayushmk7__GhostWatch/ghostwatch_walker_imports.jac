# ghostwatch_walker_imports.jac — Side-effect imports so walker:pub endpoints register.
# Imported by main.jac and frontend/main.jac to avoid drift.

import from graph.nodes { FileNode, PRAnalysisNode }
import from graph.edges { ImportEdge, BlastEdge }
import from objects.verdict { VerdictObject, SecurityFinding, CompatibilityIssue }
import from graph.builder { GraphBuilderWalker }
import from walkers.static.orchestrator { OrchestratorWalker }
import from walkers.static.security { SecurityAuditorWalker }
import from walkers.static.compatibility { CompatibilityCheckerWalker }
import from walkers.static.blast_radius { BlastRadiusMapperWalker }
import from walkers.static.graph_state { GraphStateWalker }
import from walkers.static.pr_comment { PRCommentWriterWalker }
import from integrations.github { validate_webhook_signature }
import from integrations.discord { notify_discord }
import from walkers.ghostwatch.github_system2_webhook { GitHubSystem2WebhookWalker }
import from walkers.ghostwatch.system2_hooks { System2PushTriggerWalker, System2MergeTriggerWalker, System2EscalationTickWalker }
import from walkers.ghostwatch.dep_diff { DependencyDiffWalker }
import from walkers.ghostwatch.sandbox { SandboxExecutorWalker }
import from walkers.ghostwatch.fix_gen { FixGenerationWalker }
import from walkers.ghostwatch.pr_creator { GhostwatchPRCreatorWalker }
import from walkers.ghostwatch.gap_analysis { GapAnalysisWalker }

def:pub ghostwatch_walkers_registered() -> bool {
    return True;
}
