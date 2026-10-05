"""Diana, The Huntress - continuous autonomous maritime OSINT verifier.

Run from repo root:
  env\Scripts\jac.exe run diana\diana_huntress.jac

Diana is separate from Orion v1/v2, but reuses the proven v2 SpatialSAR backend.
The LLM is only used to convert unstructured OSINT text into strict geospatial
tasking inputs; image scoring remains local ResNet inference inside v2.
"""

import from diana_tools {
    ArticleBatch, ArticleCandidate,
    GeoHit, DianaScanResult, DianaReport,
    FeatherlessModel, featherless_api_key,
    diana_llm_available,
    diana_log, diana_log_path, diana_sleep,
    diana_start_session, write_diana_session_summary,
    get_operator_directive,
    collect_maritime_articles,
    diana_graph_reset, diana_graph_id, diana_graph_node,
    diana_graph_edge, diana_graph_active,
    utc_now_iso, within_location_radius, is_memory_reuse_scan,
    is_valid_geo_hit, run_diana_sar_scan, make_frontend_payload,
    diana_save_finding,
    empty_geo_hit, empty_scan_result,
    DIANA_MAX_CYCLES, DIANA_SLEEP_SECONDS,
    DIANA_MAX_ARTICLES_PER_CYCLE, DIANA_MIN_GEOCODE_CONFIDENCE
}

glob llm: FeatherlessModel = FeatherlessModel(
    model_name="Qwen/Qwen3-8B",
    base_url="https://api.featherless.ai/v1",
    api_key=featherless_api_key(),
    proxy=True
);

# ---------------------------------------------------------------------------
# Circular pipeline graph
# ---------------------------------------------------------------------------

node intelligence_pipeline {}
node scheduler {}

node osint_scraper {
    has articles: list[ArticleCandidate] = [];
}

node geocoder {}
node sar_dispatcher {}
node reporting {}

# ---------------------------------------------------------------------------
# Diana Intelligence Knowledge Base
# ---------------------------------------------------------------------------

node intelligence_kb {
    has created_at: str = "";
}

node article {
    has keyword: str = "";
    has text: str = "";
    has first_seen: str = "";
    has geocoded: bool = False;
    has reused_location: bool = False;
}

node location {
    has graph_id: str = "";
    has name: str = "";
    has lat: float = 0.0;
    has lon: float = 0.0;
    has first_seen: str = "";
    has scan_count: int = 0;
}

node sar_scan {
    has graph_id: str = "";
    has start_date: str = "";
    has end_date: str = "";
    has target_locked: bool = False;
    has confidence_score: float = 0.0;
    has winning_image_path: str = "";
    has winning_bbox: list = [];
    has winning_sensor: str = "";
    has display_image_path: str = "";
    has display_bbox: list = [];
    has display_sensor: str = "";
    has search_matrix: list = [];
    has reasoning: str = "";
    has scanned_at: str = "";
}

# ---------------------------------------------------------------------------
# LLM bridge: unstructured OSINT -> strict geospatial satellite tasking
# ---------------------------------------------------------------------------

"""You are Diana, an autonomous maritime OSINT geocoder.

Extract the most precise event coordinates and date window from the article.
Before reading the article, read operator_directive. If it is non-empty, use it
as search intent: prioritize matching geography, incident type, vessel class,
time window, or source hints. Do not invent coordinates from the directive
alone; the article must still support the geocode.

Only return a coordinate if the text describes a maritime disaster, vessel
grounding, tanker collision, oil slick, ship spill, or similar marine event.

Return a JSON object matching GeoHit:
{
  "lat": float,
  "lon": float,
  "start_date": "YYYY-MM-DD",
  "end_date": "YYYY-MM-DD",
  "location_name": str,
  "confidence": float,
  "reasoning": str
}

Rules:
- Coordinates must be decimal degrees.
- Prefer exact event coordinates over country/city centroids.
- Use a tight date window around the reported incident.
- If the article is vague, irrelevant, or only names a broad sea/region, return
  confidence below 0.70 and explain why.
"""
def extract_coordinates(article_text: str, operator_directive: str) -> GeoHit by llm();

# ---------------------------------------------------------------------------
# Walker
# ---------------------------------------------------------------------------

walker diana_huntress {
    has cycles_run: int = 0;
    has current_article: ArticleCandidate = None;
    has current_geo: GeoHit = None;
    has current_scan: DianaScanResult = None;
    has current_report: DianaReport = None;
    has current_cycle_articles: list[ArticleCandidate] = [];
    has current_article_index: int = 0;
    has current_cycle_hits: int = 0;
    has verified_hits: list[dict] = [];
    has operator_directive: str = "";
    has memory_ref: intelligence_kb = None as intelligence_kb;
    has known_locations: list[location] = [];
    has current_article_node: article = None as article;
    has current_location_node: location = None as location;
    has memory_graph_id: str = "";
    has current_article_graph_id: str = "";
    has current_scan_graph_id: str = "";
    has scheduler_ref: scheduler = None as scheduler;
    has osint_scraper_ref: osint_scraper = None as osint_scraper;
    has geocoder_ref: geocoder = None as geocoder;
    has sar_dispatcher_ref: sar_dispatcher = None as sar_dispatcher;
    has reporting_ref: reporting = None as reporting;

    can with Root entry {
        visit [-->];
    }

    can with intelligence_pipeline entry {
        visit [-->];
    }

    can with scheduler entry {
        if self.cycles_run >= DIANA_MAX_CYCLES {
            diana_log(
                "scheduler",
                f"Max cycles reached ({DIANA_MAX_CYCLES}). Diana is standing down.",
                f"verified_hits={len(self.verified_hits)}"
            );
            summary_path: str = write_diana_session_summary();
            diana_log("reporting", "Session summary written.", summary_path);
            return;
        }

        if self.cycles_run > 0 {
            diana_sleep(DIANA_SLEEP_SECONDS);
        }

        self.cycles_run += 1;
        self.current_article_index = 0;
        self.current_cycle_hits = 0;
        self.current_cycle_articles = [];
        diana_log(
            "scheduler",
            f"Starting hunt cycle {self.cycles_run}/{DIANA_MAX_CYCLES}.",
            f"max_articles={DIANA_MAX_ARTICLES_PER_CYCLE} min_geocode_confidence={DIANA_MIN_GEOCODE_CONFIDENCE}"
        );
        visit [self.osint_scraper_ref];
    }

    can with osint_scraper entry {
        diana_log("osint", "Scraping maritime disaster OSINT.");
        batch: ArticleBatch = collect_maritime_articles(
            DIANA_MAX_ARTICLES_PER_CYCLE * 4,
            self.operator_directive
        );
        here.articles = batch.articles[:DIANA_MAX_ARTICLES_PER_CYCLE];
        self.current_cycle_articles = here.articles;
        diana_log(
            "osint",
            f"Candidate articles this cycle: {len(self.current_cycle_articles)}",
            "Diana is using the in-memory Jac intelligence graph instead of seen_leads.json."
        );

        if len(self.current_cycle_articles) == 0 {
            if self.cycles_run >= DIANA_MAX_CYCLES {
                diana_log("scheduler", f"End of Cycle {self.cycles_run}. Max cycle limit reached.");
            } else {
                diana_log(
                    "scheduler",
                    f"End of Cycle {self.cycles_run}. Sleeping for {DIANA_SLEEP_SECONDS} seconds..."
                );
            }
            visit [self.scheduler_ref];
            return;
        }

        self.current_article_index = 0;
        self.current_article = self.current_cycle_articles[self.current_article_index];
        self.current_geo = empty_geo_hit("Not geocoded yet.");
        self.current_scan = empty_scan_result("Not scanned yet.");
        self.current_article_node = article(
            keyword=self.current_article.keyword,
            text=self.current_article.text,
            first_seen=utc_now_iso()
        );
        self.current_article_graph_id = diana_graph_id("article");
        self.current_location_node = None as location;
        self.memory_ref ++> self.current_article_node;
        diana_graph_node(
            self.current_article_graph_id,
            "article",
            self.current_article.keyword,
            "geocoding",
            self.current_article.text[:180]
        );
        diana_graph_edge(self.memory_graph_id, self.current_article_graph_id, "observes");
        diana_log(
            "geocoder",
            "Geocoding candidate article.",
            f"{self.current_article_index + 1}/{len(self.current_cycle_articles)} keyword={self.current_article.keyword}"
        );
        visit [self.geocoder_ref];
    }

    can with geocoder entry {
        if not diana_llm_available() {
            diana_graph_node(
                self.current_article_graph_id,
                "article",
                self.current_article.keyword,
                "rejected",
                "No Featherless key available for LLM extraction."
            );
            diana_log("geocoder", "Rejected geocode: no Featherless key available for LLM extraction.");
            self.current_article_index += 1;
            if self.current_article_index < len(self.current_cycle_articles) {
                self.current_article = self.current_cycle_articles[self.current_article_index];
                self.current_article_node = article(
                    keyword=self.current_article.keyword,
                    text=self.current_article.text,
                    first_seen=utc_now_iso()
                );
                self.current_article_graph_id = diana_graph_id("article");
                self.current_location_node = None as location;
                self.memory_ref ++> self.current_article_node;
                diana_graph_node(
                    self.current_article_graph_id,
                    "article",
                    self.current_article.keyword,
                    "geocoding",
                    self.current_article.text[:180]
                );
                diana_graph_edge(self.memory_graph_id, self.current_article_graph_id, "observes");
                diana_log(
                    "geocoder",
                    "Geocoding candidate article.",
                    f"{self.current_article_index + 1}/{len(self.current_cycle_articles)} keyword={self.current_article.keyword}"
                );
                visit [self.geocoder_ref];
            } else {
                if self.cycles_run >= DIANA_MAX_CYCLES {
                    diana_log("scheduler", f"End of Cycle {self.cycles_run}. Max cycle limit reached.");
                } else {
                    diana_log(
                        "scheduler",
                        f"End of Cycle {self.cycles_run}. Sleeping for {DIANA_SLEEP_SECONDS} seconds..."
                    );
                }
                visit [self.scheduler_ref];
            }
            return;
        }

        # The LLM bridge turns noisy article text into strict lat/lon/date inputs.
        diana_log("geocoder", "Calling LLM to extract strict geospatial tasking inputs.");
        self.current_geo = extract_coordinates(self.current_article.text, self.operator_directive);
        if not is_valid_geo_hit(self.current_geo, DIANA_MIN_GEOCODE_CONFIDENCE) {
            self.current_article_node.geocoded = False;
            diana_graph_node(
                self.current_article_graph_id,
                "article",
                self.current_article.keyword,
                "rejected",
                self.current_geo.reasoning[:180]
            );
            diana_log("geocoder", "Rejected geocode.", self.current_geo.reasoning);
            self.current_article_index += 1;
            if self.current_article_index < len(self.current_cycle_articles) {
                self.current_article = self.current_cycle_articles[self.current_article_index];
                self.current_article_node = article(
                    keyword=self.current_article.keyword,
                    text=self.current_article.text,
                    first_seen=utc_now_iso()
                );
                self.current_article_graph_id = diana_graph_id("article");
                self.current_location_node = None as location;
                self.memory_ref ++> self.current_article_node;
                diana_graph_node(
                    self.current_article_graph_id,
                    "article",
                    self.current_article.keyword,
                    "geocoding",
                    self.current_article.text[:180]
                );
                diana_graph_edge(self.memory_graph_id, self.current_article_graph_id, "observes");
                diana_log(
                    "geocoder",
                    "Geocoding candidate article.",
                    f"{self.current_article_index + 1}/{len(self.current_cycle_articles)} keyword={self.current_article.keyword}"
                );
                visit [self.geocoder_ref];
            } else {
                if self.cycles_run >= DIANA_MAX_CYCLES {
                    diana_log("scheduler", f"End of Cycle {self.cycles_run}. Max cycle limit reached.");
                } else {
                    diana_log(
                        "scheduler",
                        f"End of Cycle {self.cycles_run}. Sleeping for {DIANA_SLEEP_SECONDS} seconds..."
                    );
                }
                visit [self.scheduler_ref];
            }
            return;
        }

        diana_log(
            "geocoder",
            f"Geocode accepted: {self.current_geo.location_name}",
            f"{self.current_geo.lat}, {self.current_geo.lon} {self.current_geo.start_date}->{self.current_geo.end_date}"
        );
        self.current_article_node.geocoded = True;
        diana_graph_node(
            self.current_article_graph_id,
            "article",
            self.current_article.keyword,
            "geocoded",
            self.current_geo.location_name
        );

        matching_location: location | None = None;
        for known_location in self.known_locations {
            if matching_location == None and within_location_radius(
                self.current_geo.lat,
                self.current_geo.lon,
                known_location.lat,
                known_location.lon,
                0.5
            ) {
                matching_location = known_location;
            }
        }

        if matching_location != None {
            self.current_location_node = matching_location;
            self.current_article_node.reused_location = True;
            self.current_article_node ++> self.current_location_node;
            diana_graph_edge(
                self.current_article_graph_id,
                self.current_location_node.graph_id,
                "reuses"
            );
            diana_graph_active(
                self.current_location_node.graph_id,
                "Matched existing location; SAR skipped."
            );
            self.current_scan = empty_scan_result(
                f"Skipped SAR scan: geocode falls within 0.5 degrees of existing KB location {self.current_location_node.name} ({self.current_location_node.lat}, {self.current_location_node.lon})."
            );
            diana_log(
                "memory",
                "Matched existing location in intelligence graph; skipping redundant SAR scan.",
                f"{self.current_geo.location_name} -> {self.current_location_node.name}"
            );
            visit [self.reporting_ref];
            return;
        }

        self.current_location_node = location(
            graph_id=diana_graph_id("location"),
            name=self.current_geo.location_name,
            lat=self.current_geo.lat,
            lon=self.current_geo.lon,
            first_seen=utc_now_iso()
        );
        self.memory_ref ++> self.current_location_node;
        self.current_article_node ++> self.current_location_node;
        self.known_locations.append(self.current_location_node);
        diana_graph_node(
            self.current_location_node.graph_id,
            "location",
            self.current_location_node.name,
            "new",
            f"{self.current_location_node.lat}, {self.current_location_node.lon}"
        );
        diana_graph_edge(self.memory_graph_id, self.current_location_node.graph_id, "indexes");
        diana_graph_edge(self.current_article_graph_id, self.current_location_node.graph_id, "geocodes_to");
        diana_log(
            "memory",
            "Created new location in intelligence graph.",
            f"{self.current_location_node.name} ({self.current_location_node.lat}, {self.current_location_node.lon})"
        );
        visit [self.sar_dispatcher_ref];
    }

    can with sar_dispatcher entry {
        diana_log(
            "sar_dispatcher",
            "Dispatching SpatialSAR scan.",
            f"{self.current_geo.lat}, {self.current_geo.lon}"
        );
        self.current_scan = run_diana_sar_scan(
            self.current_geo.lat,
            self.current_geo.lon,
            self.current_geo.start_date,
            self.current_geo.end_date
        );
        self.current_location_node.scan_count += 1;
        self.current_scan_graph_id = diana_graph_id("sar_scan");
        scan_node = sar_scan(
            graph_id=self.current_scan_graph_id,
            start_date=self.current_geo.start_date,
            end_date=self.current_geo.end_date,
            target_locked=self.current_scan.target_locked,
            confidence_score=self.current_scan.confidence_score,
            winning_image_path=self.current_scan.winning_image_path,
            winning_bbox=self.current_scan.winning_bbox,
            winning_sensor=self.current_scan.winning_sensor,
            display_image_path=self.current_scan.display_image_path,
            display_bbox=self.current_scan.display_bbox,
            display_sensor=self.current_scan.display_sensor,
            search_matrix=self.current_scan.search_matrix,
            reasoning=self.current_scan.reasoning,
            scanned_at=utc_now_iso()
        );
        self.current_location_node ++> scan_node;
        self.current_article_node ++> scan_node;
        diana_graph_node(
            self.current_scan_graph_id,
            "sar_scan",
            self.current_scan.winning_sensor if self.current_scan.winning_sensor != "" else "SpatialSAR",
            "locked" if self.current_scan.target_locked else "dead_end",
            f"confidence={self.current_scan.confidence_score}"
        );
        diana_graph_edge(self.current_location_node.graph_id, self.current_scan_graph_id, "scanned_by");
        diana_graph_edge(self.current_article_graph_id, self.current_scan_graph_id, "evidence");
        visit [self.reporting_ref];
    }

    can with reporting entry {
        if self.current_scan.target_locked {
            self.current_report = make_frontend_payload(
                self.current_geo,
                self.current_scan,
                self.current_article.text
            );
            self.verified_hits.append(self.current_report.payload);
            self.current_cycle_hits += 1;
            diana_log("reporting", "Target locked. Frontend payload ready.");
            print(self.current_report.payload_json);
            diana_save_finding(self.current_report.payload_json);
        } elif is_memory_reuse_scan(self.current_scan) {
            diana_log(
                "reporting",
                f"Reused existing location for {self.current_geo.location_name}.",
                self.current_scan.reasoning
            );
        } else {
            diana_log(
                "reporting",
                f"Dead end at {self.current_geo.location_name}.",
                self.current_scan.reasoning
            );
        }

        self.current_article_index += 1;
        if self.current_article_index < len(self.current_cycle_articles) {
            self.current_article = self.current_cycle_articles[self.current_article_index];
            self.current_geo = empty_geo_hit("Not geocoded yet.");
            self.current_scan = empty_scan_result("Not scanned yet.");
            self.current_article_node = article(
                keyword=self.current_article.keyword,
                text=self.current_article.text,
                first_seen=utc_now_iso()
            );
            self.current_article_graph_id = diana_graph_id("article");
            self.current_location_node = None as location;
            self.memory_ref ++> self.current_article_node;
            diana_graph_node(
                self.current_article_graph_id,
                "article",
                self.current_article.keyword,
                "geocoding",
                self.current_article.text[:180]
            );
            diana_graph_edge(self.memory_graph_id, self.current_article_graph_id, "observes");
            diana_log(
                "geocoder",
                "Geocoding candidate article.",
                f"{self.current_article_index + 1}/{len(self.current_cycle_articles)} keyword={self.current_article.keyword}"
            );
            visit [self.geocoder_ref];
            return;
        }

        if self.cycles_run >= DIANA_MAX_CYCLES {
            diana_log(
                "scheduler",
                f"End of Cycle {self.cycles_run}. Max cycle limit reached.",
                f"cycle_hits={self.current_cycle_hits} total_hits={len(self.verified_hits)}"
            );
        } else {
            diana_log(
                "scheduler",
                f"End of Cycle {self.cycles_run}. Sleeping for {DIANA_SLEEP_SECONDS} seconds...",
                f"cycle_hits={self.current_cycle_hits} total_hits={len(self.verified_hits)}"
            );
        }
        visit [self.scheduler_ref];
    }
}

# ---------------------------------------------------------------------------
# Entry point: scheduler -> osint_scraper -> geocoder -> sar_dispatcher ->
# reporting -> scheduler
# ---------------------------------------------------------------------------

with entry {
    diana_start_session();
    diana_graph_reset();
    operator_directive: str = get_operator_directive();
    if operator_directive != "" {
        diana_log("startup", "Operator directive loaded.", operator_directive);
    } else {
        diana_log("startup", "No operator directive supplied.");
    }
    diana_log("startup", "Initializing circular intelligence_pipeline graph.");

    pipeline = intelligence_pipeline();
    kb = intelligence_kb(created_at=utc_now_iso());
    memory_graph_id: str = "intelligence_kb";
    diana_graph_node(memory_graph_id, "intelligence_kb", "Diana KB", "active", "Native Jac graph mirror");
    sched = scheduler();
    scraper = osint_scraper();
    geo = geocoder();
    dispatcher = sar_dispatcher();
    reporter = reporting();

    root ++> pipeline;
    root ++> kb;
    pipeline ++> sched;
    sched ++> scraper;
    scraper ++> geo;
    geo ++> dispatcher;
    dispatcher ++> reporter;
    reporter ++> sched;

    root spawn diana_huntress(
        operator_directive=operator_directive,
        memory_ref=kb,
        memory_graph_id=memory_graph_id,
        scheduler_ref=sched,
        osint_scraper_ref=scraper,
        geocoder_ref=geo,
        sar_dispatcher_ref=dispatcher,
        reporting_ref=reporter
    );
}
