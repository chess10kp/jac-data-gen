"""Orion Watchdog v2 — self-directing OSINT intelligence pipeline.

Jac OSP walker with a dynamic knowledge graph:
  MissionNode -> IntelligenceGatheringNode -> InvestigatorNode
                        |                          |
              [EntityMemoryNode*]     PROCEED/PIVOT: SatelliteVerificationNode
                                             ABORT: SynthesisNode <------+
                                                                          |
                                                    SatelliteVerificationNode

Run: jac run watchdog.jac [rumor text]
"""

import from featherless_model { FeatherlessModel, featherless_api_key }
import from agent_tools { search_web, save_rgb_image_to_disk, run_spatial_sar_scan,
                          save_dossier,
                          save_named_dossier, write_offline_dossier,
                          write_deterministic_dossier,
                          no_web_dossier_path, get_cli_mission,
                          format_entities, normalize_rumor_parse,
                          normalize_investigator_decision, next_date,
                          web_intel_absent, empty_entity_list,
                          llm_credentials_available,
                          parse_known_rumor, has_known_rumor_parse,
                          deterministic_investigator_decision,
                          save_run_manifest,
                          RumorParse, DossierReport,
                          Entity, EntityList, InvestigatorDecision,
                          SpatialSearchResult }
import from sar_model_tools { run_rgb_oil_slick_detection, combine_verdicts }
import from tools { SpillVerdict }

glob llm: FeatherlessModel = FeatherlessModel(
    model_name="Qwen/Qwen3-8B",
    base_url="https://api.featherless.ai/v1",
    api_key=featherless_api_key(),
    proxy=True
);

# ---------------------------------------------------------------------------
# Nodes
# ---------------------------------------------------------------------------

node MissionNode {}
node IntelligenceGatheringNode {}
node EntityMemoryNode {
    has name: str = "";
    has entity_type: str = "";
    has description: str = "";
    has relevance: float = 0.0;
    has suggested_lat: float = 0.0;
    has suggested_lon: float = 0.0;
}
node InvestigatorNode {}
node SatelliteVerificationNode {}
node SynthesisNode {}

# ---------------------------------------------------------------------------
# byllm functions
# ---------------------------------------------------------------------------

"""You are Orion, an autonomous OSINT agent.
Parse the user's rumor into a structured incident report.
Use your knowledge to estimate the GPS coordinates of the location.
Generate a DuckDuckGo search query to find corroborating news."""
def parse_rumor(mission: str) -> RumorParse by llm();

"""You are Orion's intelligence analyst.
Read the web search results and identify up to 6 key entities: vessels, companies,
locations, dated events, persons.
For each entity, use your knowledge to estimate GPS coordinates if it is a named
location or known incident; leave suggested_lat and suggested_lon at 0.0 if unknown.
Rate each entity's relevance to the original mission from 0.0 to 1.0."""
def extract_entities(mission: str, web_intel: str) -> EntityList by llm();

"""You are the Lead Investigator for Orion, a Space-Based Environmental Monitoring AI.
Review the mission, web intelligence, and flagged entities. Act like a seasoned
investigator — look for lateral connections and the strongest verifiable signal.

Return exactly one of these actions:
  PROCEED — original coordinates are still the best target
  PIVOT   — a better target location exists; supply new target_lat/lon/target_date
  ABORT   — the rumor is fabricated or unverifiable; skip orbital tasking

Set target_lat, target_lon, target_date to the best coordinates to investigate.
Write one paragraph of reasoning explaining your call."""
def investigate(mission: str, web_intel: str, entities_summary: str) -> InvestigatorDecision by llm();

"""You are Orion, an autonomous Space-Based Environmental Monitoring Agent
serving marine insurers and ESG compliance firms.

Synthesize web intelligence with satellite verification (or its absence) into a
professional Intelligence Dossier in Markdown with this exact four-section structure:

## 1. Executive Summary
State CONFIRMED, CONTRADICTED, or INCONCLUSIVE with one sentence of justification.

## 2. Intelligence Lead
What the web sources and rumors claimed. Quote or paraphrase key sources.

## 3. Orbital Verification
Sentinel-2 RGB classifier satellite findings verbatim with confidence level.
If orbital tasking was aborted, explain why and note no imagery was acquired.

## 4. Risk Assessment
Environmental liability implications, responsible parties, and recommended next actions."""
def write_dossier(mission: str, web_intel: str, decision_text: str,
                  rgb_reasoning: str, spill_detected: bool, confidence: float)
    -> DossierReport by llm();

# ---------------------------------------------------------------------------
# Walker
# ---------------------------------------------------------------------------

walker Watchdog {
    has mission: str = "";
    has rumor_parse: RumorParse = None;
    has web_intel: str = "";
    has entity_list: EntityList = None;
    has decision: InvestigatorDecision = None;
    has target_lat: float = 0.0;
    has target_lon: float = 0.0;
    has target_start: str = "";
    has target_end: str = "";
    has rgb_image_path: str = "";
    has sar_image_path: str = "";
    has winning_image_path: str = "";
    has winning_bbox: list = [];
    has search_matrix: list = [];
    has sar_scan: SpatialSearchResult = None;
    has rgb_verdict: SpillVerdict = None;
    has sar_verdict: SpillVerdict = None;
    has combined_verdict: SpillVerdict = None;
    has dossier: DossierReport = None;
    has investigator_node_ref: InvestigatorNode = None as InvestigatorNode;
    has satellite_node_ref: SatelliteVerificationNode = None as SatelliteVerificationNode;
    has synthesis_node_ref: SynthesisNode = None as SynthesisNode;

    can with Root entry {
        visit [-->];
    }

    can with MissionNode entry {
        print(f"[orion] Mission: {self.mission}");
        self.rumor_parse = parse_known_rumor(self.mission);
        if not has_known_rumor_parse(self.rumor_parse) and llm_credentials_available() {
            self.rumor_parse = parse_rumor(self.mission);
            self.rumor_parse = normalize_rumor_parse(self.mission, self.rumor_parse);
        }
        if not has_known_rumor_parse(self.rumor_parse) {
            print("[orion] LLM parser unavailable and no deterministic coordinates were found. Using default mission parse.");
            self.rumor_parse = parse_known_rumor("near selected AOI at 29.245, 50.245 between 2026-05-05 and 2026-05-08");
        }
        self.target_lat = self.rumor_parse.lat;
        self.target_lon = self.rumor_parse.lon;
        self.target_start = self.rumor_parse.start_date;
        self.target_end = self.rumor_parse.end_date;
        print(f"[orion] Initial target: {self.rumor_parse.location_name} ({self.target_lat}, {self.target_lon})");
        print(f"[orion] Date window: {self.target_start} -> {self.target_end}");
        visit [-->];
    }

    can with IntelligenceGatheringNode entry {
        print("[orion] Searching for corroborating intelligence...");
        result = search_web(self.rumor_parse.search_query);
        self.web_intel = result.articles;
        print(f"[orion] Found {result.source_count} sources.");

        if web_intel_absent(self.web_intel) or not llm_credentials_available() {
            if not llm_credentials_available() {
                print("[orion] LLM credentials unavailable. Skipping entity extraction and using deterministic planner.");
            } else {
                print("[orion] No usable web intel. Treating this as unknown, not disproven.");
            }
            self.entity_list = empty_entity_list();
        } else {
            print("[orion] Extracting entities from intelligence...");
            self.entity_list = extract_entities(self.mission, self.web_intel);
        }

        for entity in self.entity_list.entities {
            new_node = EntityMemoryNode(
                name=entity.name,
                entity_type=entity.entity_type,
                description=entity.description,
                relevance=entity.relevance,
                suggested_lat=entity.suggested_lat,
                suggested_lon=entity.suggested_lon
            );
            here ++> new_node;
        }
        print(f"[orion] Knowledge graph: {len(self.entity_list.entities)} EntityMemoryNodes spawned.");
        visit [self.investigator_node_ref];
    }

    can with InvestigatorNode entry {
        print("[orion] Lead Investigator deliberating...");
        entities_summary = format_entities(self.entity_list);
        if llm_credentials_available() {
            self.decision = investigate(self.mission, self.web_intel, entities_summary);
        } else {
            self.decision = deterministic_investigator_decision(self.mission, self.rumor_parse, self.web_intel);
        }
        self.decision = normalize_investigator_decision(
            self.mission,
            self.rumor_parse,
            self.web_intel,
            self.decision
        );
        print(f"[orion] Decision: {self.decision.action}");
        print(f"[orion] Reasoning: {self.decision.reasoning}");

        if self.decision.action == "PIVOT" {
            self.target_lat = self.decision.target_lat;
            self.target_lon = self.decision.target_lon;
            self.target_start = self.decision.target_date;
            self.target_end = next_date(self.target_start);
            print(f"[orion] Pivoting to ({self.target_lat}, {self.target_lon}) on {self.target_start}");
        }

        if self.decision.action == "ABORT" {
            print("[orion] Orbital tasking aborted. Proceeding directly to synthesis.");
            visit [self.synthesis_node_ref];
        } else {
            visit [self.satellite_node_ref];
        }
    }

    can with SatelliteVerificationNode entry {
        print("[orion] Acquiring Sentinel-2 RGB tile...");
        self.rgb_image_path = save_rgb_image_to_disk(
            self.target_lat,
            self.target_lon,
            self.target_start,
            self.target_end
        );
        if not self.rgb_image_path {
            print("[orion] No Sentinel-2 RGB imagery available. Skipping RGB classifier.");
            self.rgb_verdict = SpillVerdict(
                spill_detected=False,
                confidence=0.0,
                reasoning="No Sentinel-2 RGB imagery found for the requested location and date range."
            );
        } else {
            print(f"[orion] Running Hugging Face RGB classifier on {self.rgb_image_path}...");
            self.rgb_verdict = run_rgb_oil_slick_detection(self.rgb_image_path);
            print(f"[orion] RGB classifier: spill_detected={self.rgb_verdict.spill_detected} confidence={self.rgb_verdict.confidence:.0%}");
        }

        print("[orion] Running shared 3x3 Sentinel-1/Sentinel-2 spatial consensus scan...");
        self.sar_scan = run_spatial_sar_scan(
            self.target_lat,
            self.target_lon,
            self.target_start,
            self.target_end
        );
        self.winning_image_path = self.sar_scan.winning_image_path;
        self.winning_bbox = self.sar_scan.winning_bbox;
        self.search_matrix = self.sar_scan.search_matrix;
        self.sar_verdict = self.sar_scan.winning_verdict;
        if self.sar_scan.display_image_path {
            self.rgb_image_path = self.sar_scan.display_image_path;
        } elif self.sar_scan.winning_sensor == "Sentinel-2_RGB" {
            self.rgb_image_path = self.sar_scan.winning_image_path;
        }
        if self.sar_scan.winning_sensor == "Sentinel-2_RGB" {
            self.sar_image_path = "";
        } else {
            self.sar_image_path = self.sar_scan.winning_image_path;
        }
        if not self.winning_image_path {
            print("[orion] No Sentinel-1/Sentinel-2 imagery available across the 3x3 search matrix.");
        } else {
            print(f"[orion] Spatial grid winner: {self.sar_scan.winning_sensor} {self.winning_image_path}");
            print(f"[orion] Spatial grid classifier: spill_detected={self.sar_verdict.spill_detected} confidence={self.sar_verdict.confidence:.0%}");
        }

        self.combined_verdict = combine_verdicts(self.rgb_verdict, self.sar_verdict);
        print(f"[orion] Combined satellite verdict: spill_detected={self.combined_verdict.spill_detected} confidence={self.combined_verdict.confidence:.0%}");
        visit [-->];
    }

    can with SynthesisNode entry {
        print("[orion] Writing Intelligence Dossier...");
        if self.combined_verdict {
            rgb_text = self.combined_verdict.reasoning;
            detected = self.combined_verdict.spill_detected;
            conf = self.combined_verdict.confidence;
        } else {
            rgb_text = "Orbital tasking aborted - no satellite imagery acquired.";
            detected = False;
            conf = 0.0;
        }
        web_mode = "live";
        if web_intel_absent(self.web_intel) {
            web_mode = "offline";
        }
        self.dossier = write_deterministic_dossier(
            self.mission,
            self.rumor_parse.location_name,
            self.web_intel,
            str(self.decision),
            rgb_text,
            detected,
            conf
        );
        path = save_dossier(self.dossier, self.rumor_parse.location_name);
        print(f"\n{self.dossier.body}\n");
        print(f"[orion] Dossier saved to {path}");

        manifest_path = save_run_manifest(
            self.rumor_parse.location_name,
            self.target_lat,
            self.target_lon,
            self.target_start,
            self.target_end,
            self.rgb_image_path,
            self.sar_image_path,
            self.rgb_verdict,
            self.sar_verdict,
            self.combined_verdict,
            path,
            web_mode,
            self.sar_scan
        );
        print(f"[orion] Manifest saved to {manifest_path}");
    }
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

with entry {
    mission = get_cli_mission();
    if not mission {
        print("=========================================================");
        print("  Orion Watchdog v2 - Agentic OSINT Dossier Generator");
        print("=========================================================");
        print("  Usage:");
        print("    $env:ORION_MISSION = 'tanker spill Hormuz July 2021'");
        print("    jac run watchdog.jac");
        print("=========================================================");
        print("  No rumor supplied -- running with default.");
        print("");
        mission = "I heard a tanker dumped bilge in the Strait of Hormuz in July 2021.";
    }

    mission_node = MissionNode();
    intel_node = IntelligenceGatheringNode();
    investigator_node = InvestigatorNode();
    satellite_node = SatelliteVerificationNode();
    synthesis_node = SynthesisNode();

    root ++> mission_node;
    mission_node ++> intel_node;
    intel_node ++> investigator_node;
    investigator_node ++> satellite_node;
    investigator_node ++> synthesis_node;
    satellite_node ++> synthesis_node;

    root spawn Watchdog(
        mission=mission,
        investigator_node_ref=investigator_node,
        satellite_node_ref=satellite_node,
        synthesis_node_ref=synthesis_node
    );
}
