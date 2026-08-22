# Jac-Native Evaluation v0 Plan

## Status

**Planning complete; task creation has not started.**

This document defines the first primary benchmark for models intended to write
good Jac. It replaces the earlier assumption that Python-to-Jac translation is
the headline capability.

The existing `evals/function/v1/` candidate is not this benchmark. It is a
Python-derived translation/completion suite and may be retained later as a
secondary correctness and regression track. It remains unsealed.

## 1. Goal

Measure whether a model can write correct, clear, maintainable, and
context-appropriate Jac directly.

The benchmark must test both:

1. Writing a complete Jac implementation from a natural-language requirement.
2. Completing or editing one target file inside realistic Jac-native context.

The benchmark must not infer Jac quality from Python translation, reference
similarity, or mechanical syntax preferences. In particular, optional use of a
construct such as `match` is not inherently better than an appropriate `if`.

## 2. Non-goals for v0

The first version does not measure:

- Python-to-Jac or JavaScript-to-Jac translation.
- Agent loops that can run tools, inspect failures, and retry.
- Unified-diff or patch-format generation.
- Changes to multiple output files in one task.
- `byLLM` behavior or external model integration.
- Fullstack client/browser behavior.
- Exact or approximate similarity to a reference solution.
- A single automated “idiomaticity” score.

These capabilities can become separate benchmark modes after v0 is stable.

## 3. Pilot size and matrix

Create 48 tasks.

| Domain | Complete solution | Contextual edit | Total |
|---|---:|---:|---:|
| Core Jac | 16 | 16 | 32 |
| OSP | 8 | 8 | 16 |
| **Total** | **24** | **24** | **48** |

Use this split:

| Split | Complete solution | Contextual edit | Total | Visibility |
|---|---:|---:|---:|---|
| Development | 8 | 8 | 16 | Public prompts and context |
| Test | 16 | 16 | 32 | Private prompts, context, references, and tests |

A useful stratification is:

- Development: 5 core and 3 OSP tasks in each track.
- Test: 11 core and 5 OSP tasks in each track.
- Each track: approximately 4 easy, 14 medium, and 6 hard tasks.

Difficulty is a curation label, not a scoring multiplier. Report difficulty
slices separately.

## 4. Evaluation protocol

The model receives one prompt and produces one answer. It cannot run Jac, see
test failures, use repository tools, or revise its answer.

### 4.1 Complete-solution track

The model receives:

- A natural-language requirement.
- A required public API or entrypoint.
- Behavioral constraints and error semantics.
- Optional public examples.
- Optional read-only declarations needed by the task.
- The target path, normally `solution.jac`.

The model returns the complete content of the target `.jac` file.

The prompt must not include:

- A Python or JavaScript implementation.
- A generated Jac prefix that reveals the solution structure.
- Hidden tests.
- A reference implementation.

### 4.2 Contextual-edit track

The model receives:

- A requirement describing the change.
- One named target `.jac` file containing a TODO, defect, or incomplete API.
- Zero or more read-only Jac context files.
- Public tests or examples when useful.
- Compatibility constraints for the existing workspace.

The model returns the complete replacement content of the one target file.
It does not return a diff. Context files must remain unchanged.

Restricting v0 to one target file avoids confusing Jac ability with patch
formatting or multi-file response parsing.

### 4.3 Output extraction

Accept either:

- Raw Jac source, or
- Exactly one fenced `jac` code block.

Reject empty output, multiple Jac blocks, prose mixed with an unrecognized code
fence, and output that attempts to modify files other than the target.

## 5. Capability taxonomy

### 5.1 Core Jac: 32 tasks

Target eight tasks in each group, divided evenly across the two tracks:

1. Typed functions, collections, and transformations.
2. Objects, enums, validation, and data modeling.
3. Modules, public APIs, imports, and error handling.
4. Stateful or mixed problems requiring decomposition across abilities.

Core tasks must not reward unnecessary OSP machinery. A model may choose among
valid Jac control-flow constructs unless the task semantics require a specific
construct.

### 5.2 OSP: 16 tasks

Target four tasks in each group, divided evenly across the two tracks:

1. Node and edge schemas with meaningful graph relationships.
2. Traversal, filtering, and neighborhood queries.
3. Walker state and control flow, including appropriate uses of `visit`,
   `spawn`, `report`, or `disengage`.
4. Graph mutation or multi-step OSP workflows.

An OSP task may require nodes, edges, walkers, or a specific traversal operation
when that construct is part of the requested behavior. This is a semantic task
contract, not a generic style preference.

Do not create OSP tasks that merely wrap an ordinary list-processing function
in a walker.

## 6. First four task design cards

Before authoring all 48 tasks, create these four public development tasks. The
exact Jac spelling must be verified against the pinned toolchain, but authors
must preserve the stated behavior and evaluation purpose.

### 6.1 Core / complete: capacity allocator

**Model-visible requirement:** Define typed request and result objects and
implement a public `allocate_requests` function. It receives requests in input
order and a non-negative capacity. A request has a string ID and positive unit
count. Accept a request only if its ID has not appeared before, its count is
positive, and it fits in the remaining capacity. Reject invalid, duplicate, and
non-fitting requests. Return accepted IDs, rejected IDs, and used capacity.
Do not mutate the caller's request list.

**Target:** `solution.jac`; no context files.

**Hidden behavior:** Empty input, exact-capacity allocation, invalid counts,
duplicate IDs, order preservation, non-fitting requests followed by smaller
fitting requests, and input non-mutation.

**Plausible negatives:** Stop after the first non-fitting request; count a
rejected request as used capacity; accept duplicate IDs; sort instead of
preserving input order.

**Quality purpose:** Typed objects, collection handling, validation, a clear
public API, and decomposition without any reason to introduce OSP.

### 6.2 Core / contextual: sensor summary repair

**Visible context:** `models.jac` defines typed `Reading` and `SensorSummary`
objects. Each reading has a sensor ID, sequence number, numeric value, and
validity flag. The summary holds one result per sensor. A supplied target
`summarizer.jac` contains the required public function signature and an
incomplete implementation.

**Model-visible requirement:** Replace `summarizer.jac`. Ignore invalid
readings. For each sensor, keep only the valid reading with the greatest
sequence number; when sequence numbers tie, the later input wins. Return
summaries ordered by the first appearance of each retained sensor. Preserve the
supplied object definitions and public signature, and do not mutate inputs.

**Target:** complete replacement of `summarizer.jac`; `models.jac` is read-only.

**Hidden behavior:** No valid readings, interleaved sensors, tied sequences,
invalid newer readings, negative and floating values, stable output order, API
compatibility, and input non-mutation.

**Plausible negatives:** Use greatest value instead of greatest sequence; allow
an invalid reading to replace a valid one; sort sensor IDs; change the supplied
model or signature.

**Quality purpose:** Reading existing Jac context, typed object use, stable
state updates, and API-preserving maintenance.

### 6.3 OSP / complete: service reachability audit

**Model-visible requirement:** Model services as nodes and directed calls as
edges. Every service has a unique ID and a display name. Implement a public
walker that starts on one service, traverses outgoing call relationships up to
a supplied maximum hop count, and reports each reachable enabled service ID
exactly once. Exclude the start node from reports. Disabled services are not
reported and must not be traversed through. Preserve breadth layers in the
report; within a layer order by `(display_name, service_id)` so the result is
deterministic even when names match. A negative hop limit produces no reports.

**Target:** `solution.jac`; no context files.

**Objective OSP contract:** The solution must define meaningful node, edge, and
walker declarations and perform graph traversal. This contract exists because
the requested data model and behavior are graph-native.

**Hidden behavior:** Zero and negative hop limits, cycles, converging paths,
duplicate display names with distinct service IDs, disabled bridge nodes,
directed edges, and deterministic multi-layer reports.

**Plausible negatives:** Traverse incoming edges; report the start; traverse
through disabled nodes; emit duplicates on converging paths; ignore the hop
limit.

**Quality purpose:** Graph schema design, walker state, bounded traversal,
cycle handling, and deterministic reporting.

### 6.4 OSP / contextual: follower recommendation walker

**Visible context:** `social_model.jac` defines `Person` nodes and directed
`Follows` edges. A target `recommendations.jac` contains the required walker
name and public state fields but has incomplete traversal/report behavior.

**Model-visible requirement:** Replace `recommendations.jac`. Starting at one
person, recommend people reachable by exactly two outgoing `Follows` hops.
Exclude the start person, direct follows, blocked people, and duplicates. Do not
traverse outward from blocked intermediary people. Report recommendations in
name order while preserving the supplied walker interface and leaving
`social_model.jac` unchanged.

**Target:** complete replacement of `recommendations.jac`;
`social_model.jac` is read-only.

**Objective OSP contract:** Preserve the supplied walker declaration and use
walker traversal/report behavior rather than flattening the graph into an
unrelated constant structure.

**Hidden behavior:** Cycles, direct-follow overlap, multiple paths to one
candidate, blocked intermediaries and candidates, directed edges, no
recommendations, and deterministic order.

**Plausible negatives:** Return direct follows; traverse through blocked
intermediaries; report duplicate candidates; include the start through a
cycle; edit the context schema.

**Quality purpose:** Context-aware walker repair, two-hop traversal, exclusion
sets, deterministic reporting, and compatibility with supplied graph types.

These cards are authoring briefs, not frozen prompts. The author must create the
actual public Jac signatures and context files, then pass every gate in Sections
11 and 15. Review the four-task slice before scaling task authoring.

## 7. Proposed repository layout

Use normal files as the authoring source of truth. Export JSONL only for model
runners and result processing.

```text
evals/jac_native/v0/
├── README.md
├── manifest.json
├── schemas/
│   ├── public-task.schema.json
│   ├── private-task.schema.json
│   └── sample.schema.json
├── public/
│   └── dev/
│       └── <task-id>/
│           ├── task.json
│           ├── prompt.md
│           └── context/
│               └── *.jac
├── private/
│   ├── dev/
│   │   └── <task-id>/
│   │       ├── tests.jac
│   │       ├── reference.jac
│   │       ├── provenance.json
│   │       ├── review.json
│   │       └── negatives/
│   │           └── *.jac
│   └── test/
│       └── <task-id>/
│           ├── task.json
│           ├── prompt.md
│           ├── context/
│           │   └── *.jac
│           ├── tests.jac
│           ├── reference.jac
│           ├── provenance.json
│           ├── review.json
│           └── negatives/
│               └── *.jac
└── exports/
    └── dev.jsonl
```

Each `public/dev/<task-id>/` directory pairs with the same ID under
`private/dev/<task-id>/`. The public side contains only model-visible material;
the private side contains its tests, reference, negatives, provenance, and
review record. Development tests and references remain private even though the
development prompt is public.

Only public development prompts and context may be exported to
`exports/dev.jsonl` or published. Private test prompts are supplied to a model
only inside the controlled evaluation runner.

Never place private test prompts, context, tests, references, negative
solutions, provenance, or review notes in a training export.

## 8. Public task schema

A `task.json` should contain metadata and objective contracts. Large prompt and
context content remain in files.

Example:

```json
{
  "schema_version": 1,
  "id": "jnv0-core-complete-001",
  "split": "dev",
  "track": "complete",
  "domain": "core",
  "category": "objects_validation",
  "difficulty": "medium",
  "prompt_path": "prompt.md",
  "target_path": "solution.jac",
  "context_paths": [],
  "public_example_paths": [],
  "contracts": [
    {
      "kind": "public_symbol",
      "name": "validate_order",
      "reason": "Required caller-facing API"
    }
  ],
  "timeout_s": 120
}
```

Allowed `track` values:

- `complete`
- `contextual`

Allowed `domain` values for v0:

- `core`
- `osp`

Every hard structural contract must include a task-specific reason. Do not add
contracts only to make code look more Jac-like.

Useful contract kinds may include:

- Required public symbol or entrypoint.
- Required compatibility with supplied declarations.
- Required OSP declaration or operation when semantically necessary.
- Forbidden test blocks in model output.
- Forbidden Python imports or Python syntax.

Type discipline, construct usage, and readability should normally remain
reported diagnostics unless the prompt explicitly makes them part of the API.

## 9. Private task metadata

`provenance.json` should record:

```json
{
  "author": "...",
  "created_at": "...",
  "source_kind": "original|transformed_pattern",
  "inspiration": [
    {
      "path_or_url": "...",
      "revision": "...",
      "license": "...",
      "content_sha256": "..."
    }
  ],
  "transformation_summary": "...",
  "training_corpus_similarity_checked": true,
  "reviewers": ["..."]
}
```

`review.json` should record each quality gate, reviewer, date, and outcome. A
task is not eligible for the frozen test set while any required gate is
incomplete.

## 10. Hybrid task sourcing and contamination control

Use both original task ideas and transformed real-world capability patterns.
For transformed tasks:

1. Inspect Jac repositories, documentation, examples, and issue patterns.
2. Record the capability or failure pattern, not the original solution.
3. Change the domain, names, APIs, behavior, edge cases, and file structure.
4. Author the prompt, reference, and tests independently.
5. Compare the final prompt, context, and reference with the inspiration and
   every known training corpus.
6. Reject a task that remains recognizably copied.

Apply text and token similarity checks against at least:

- The final Jac training export.
- `data/composer_dataset.jsonl`.
- Any OSP or golden-client material admitted to training.
- The js2jac training export if the model will consume it.
- The recorded inspiration source.

Similarity is a contamination diagnostic, not a quality score. Review flagged
matches manually.

A transformed-pattern task is substantially rewritten only when all of these
are true:

- No prompt sentence, code body, test case, example, or distinctive identifier
  is copied, except unavoidable Jac syntax and standard API terminology.
- Domain vocabulary, public API, identifiers, examples, and test data are all
  newly authored.
- At least two deeper dimensions also change: behavioral edge cases, state
  model, graph shape or traversal semantics, algorithmic requirement, or file
  organization.
- The reference is written independently rather than edited from the source.
- A reviewer other than the transformer records that the final task cannot be
  solved by recalling the source artifact.

Token and text thresholds may flag candidates for review, but no numeric
similarity threshold can approve a task by itself. Failure of any criterion
above rejects the task or changes its provenance classification.

Once task IDs are assigned, deny every development and test task from all
training exports. Public development tasks must also remain evaluation-only.

## 11. Reference and hidden-test requirements

A reference solution proves that the prompt and tests are feasible. It is not
the unique expected answer and must never be used for textual grading.

For each task:

1. Write or independently review a reference solution.
2. Run source-only `jac check` on the reference and required context.
3. Run hidden behavioral tests in a separate guarded workspace.
4. Verify deterministic behavior across repeated clean runs.
5. Confirm no network or external service is required.
6. Confirm the test suite does not depend on execution order or shared state.

The check input and test input must remain separate. Hidden tests may exercise
values that make combined static checking unsuitable even when the candidate
source is valid.

### 11.1 Negative controls

Create at least three plausible incorrect solutions per task, such as:

- Missing an important edge case.
- Returning the right type but wrong value.
- Mutating state when the contract requires a read-only operation.
- Traversing the wrong graph direction or visiting only one hop.
- Reporting duplicates or failing to disengage when required.
- Breaking a supplied public API while implementing the main behavior.

Every negative must compile when possible and must fail at least one hidden
behavioral test or objective contract. A hidden suite that only rejects syntax
errors is not sufficient.

### 11.2 Independent solve

A reviewer who has not seen the reference must solve the task from only the
model-visible prompt and context. Record:

- Whether the requirement was unambiguous.
- Any assumptions the solver had to invent.
- Whether the supplied API was sufficient.
- Whether multiple valid designs were accepted by the tests.
- The observed difficulty.

Revise or reject ambiguous tasks.

## 12. Automated grading

Reuse the process isolation, timeout handling, infrastructure classification,
and pass@k logic in `scripts/eval_jac.py`. Extend it for workspace tasks rather
than coupling it to a model provider.

For each sample:

1. Extract exactly one target-file response.
2. Create an isolated temporary workspace.
3. Copy read-only context files.
4. Write the model output to `target_path`.
5. Run source-only `jac check` on the candidate workspace.
6. Evaluate objective task contracts.
7. Add private tests only to the guarded test workspace.
8. Run `jac test`.
9. Collect neutral diagnostics.
10. Remove the temporary workspace.

Recommended terminal statuses:

- `pass`
- `invalid_output`
- `check_fail`
- `contract_fail`
- `test_fail`
- `timeout`
- `infra_error`

An infrastructure error makes the run incomplete. It must not count as a model
failure. Results must not include hidden test source, private paths, reference
source, or private provenance.

The current grader aggregates `function` and `osp`. Jac-native v0 needs separate
metadata and reports for:

- `complete` and `contextual` tracks.
- `core` and `osp` domains.
- Capability category.
- Difficulty.
- Development and test splits.

## 13. Metrics

### 13.1 Every run

Report:

- Valid-output rate.
- Compile rate.
- Contract-compliance rate.
- Behavioral pass@1.
- Optional unbiased pass@k when enough samples exist.
- Robustness-test failure counts.
- Status and infrastructure-error counts.
- Results by track, domain, category, difficulty, and split.
- Neutral typing, residue, and readability diagnostics.

Behavior is the primary automatic success criterion. Do not combine static
feature frequencies into an idiomaticity score.

For cross-model comparisons, record the exact model, revision, prompt wrapper,
decoding parameters, tokenizer or provider, sample count, Jac version, task
manifest hash, and grader version. Do not treat pass@k values produced under
materially different sampling policies as directly equivalent.

### 13.2 Periodic expert quality review

Run formal quality review for milestone checkpoints, not every development run.
Review all behaviorally correct pass@1 outputs.

Two reviewers independently see:

- The requirement.
- Public context.
- The candidate.
- Confirmation that it passed behavior.

They must not see the model identity, the other review, or the reference before
submitting an initial judgment.

Record `none`, `minor`, or `major` issues for:

1. Jac paradigm fit.
2. Type discipline and API design.
3. Decomposition and readability.
4. Maintainability and unnecessary complexity.
5. Python/transpiler residue.

A candidate is **correct-and-clean** when it passes the automated behavioral
criteria and receives no major issue after adjudication. Report:

- Correct-and-clean@1.
- Each review dimension separately.
- Initial reviewer agreement.
- Adjudication count and rationale.

Do not award points merely for using `match`, comprehensions, walkers, or any
other optional construct. Judge whether the design fits the requirement and
context.

Automated LLM quality judges may be reported as diagnostics only. They cannot
become formal metrics until calibrated against these blinded expert labels.

## 14. Manifest and freezing

`manifest.json` should contain:

- Schema and benchmark version.
- Status: `draft`, `candidate`, or `sealed`.
- Counts for every split, track, domain, category, and difficulty.
- Jac compiler/runtime version and executable hash.
- Grader version or source hash.
- Hash of every benchmark artifact.
- Reference-validation report hash.
- Task-review completion counts.
- Creation and sealing timestamps.
- Explicit exclusions: agentic, byLLM, fullstack, and translation.

Do not modify a sealed directory. Corrections create a new immutable version.
Seal v0 only when every reference, integrity check, negative control, and review
gate passes.

## 15. Task-author checklist

A task is ready for candidate review only when every item below is true.

### Prompt and context

- [ ] The task directly asks for Jac, not translation from another language.
- [ ] The required behavior and public API are explicit.
- [ ] The output target is exactly one file.
- [ ] All model-visible context is necessary and internally consistent.
- [ ] No private test, reference, or answer hint appears in public material.
- [ ] OSP constructs are required only by graph semantics.

### Correctness

- [ ] A reference compiles using source-only `jac check`.
- [ ] The reference passes all hidden tests.
- [ ] Hidden tests cover normal, boundary, invalid, and stateful cases as
      applicable.
- [ ] At least three plausible negatives are rejected.
- [ ] Tests are deterministic and local.
- [ ] Infrastructure failure can be distinguished from model failure.

### Quality and ambiguity

- [ ] An independent solver completed the task without the reference.
- [ ] Multiple valid implementations can pass.
- [ ] Contracts test requirements rather than arbitrary style.
- [ ] Difficulty and category labels were reviewed.
- [ ] Provenance and transformation notes are complete.
- [ ] Similarity checks found no unresolved contamination risk.

### Privacy and release

- [ ] The task is in the correct public or private split.
- [ ] All task material is excluded from training exports.
- [ ] Private data is absent from generated samples and grading results.
- [ ] Artifact hashes are recorded.

## 16. Build phases and acceptance gates

### Phase 0: specification and schemas

Deliver:

- This plan reviewed and accepted.
- JSON Schemas for public tasks, private metadata, and samples.
- A draft v0 manifest.

Accept when a task author can create a task without inventing undocumented
fields or privacy rules.

### Phase 1: four-task vertical slice

Deliver one task in each domain/track quadrant listed in Section 6.

Accept when:

- All references pass.
- Each task has at least three rejected negative controls.
- Independent solves expose no unresolved ambiguity.
- The generation export contains no private material.
- The grader handles both empty-context and workspace-context tasks.

Do not author the remaining 44 tasks until this gate passes.

### Phase 2: public development set

Expand to 16 public development tasks with the required track/domain coverage.
Run baseline generations and inspect every result.

Accept when:

- The set covers the capability matrix.
- Failures are attributable to model behavior rather than parsing or unclear
  prompts.
- No task is a universal floor or ceiling for uninformative reasons.
- Metrics and artifacts are reproducible.

### Phase 3: private test set

Author 32 private test tasks using the same reviewed process. Keep prompts,
context, references, tests, negatives, and provenance outside public exports.

Accept when all task gates pass and the split-level counts match the matrix.

### Phase 4: calibration

Run multiple representative baseline models using the same one-shot protocol.
Review item-level behavior and perform formal blinded quality review for correct
pass@1 outputs.

Revise or replace tasks that are:

- Ambiguous.
- Accidentally impossible.
- Trivial because the prompt reveals the implementation.
- Passed by incorrect behavior.
- Failed by valid alternative implementations.
- Dominated by output parsing rather than Jac ability.

Any task replacement requires complete revalidation.

### Phase 5: seal v0

Pin toolchain and grader metadata, verify all hashes and privacy boundaries, and
write the final manifest. After sealing, create a new version for any change.

## 17. Recommended immediate next actions

1. Review and accept this plan.
2. Define the three JSON Schemas and draft manifest.
3. Materialize the four Section 6 design cards as public task files.
4. Implement workspace assembly in the provider-neutral grader.
5. Author references, hidden tests, and negative controls for those four tasks.
6. Run independent solves and review the slice before scaling.
