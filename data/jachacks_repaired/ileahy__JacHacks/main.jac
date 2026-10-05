import from datetime { datetime }
import from os { environ }
import from math { sqrt }
import from urllib.request { urlopen }
import from urllib.parse { urlencode }
import from json { loads, dumps }
import from dotenv { load_dotenv }
import from byllm.llm { Model }

glob _env_loaded = load_dotenv();
glob llm = Model(model_name="claude-sonnet-4-6");

# ── LLM Output Types ─────────────────────────────────────────────────────────

obj Macros {
    has calories: int,
        protein_g: float,
        carbs_g: float,
        fat_g: float;
}

obj FoodItem {
    has name: str,
        category: str,
        estimated_price: float,
        unit: str,
        macros_per_100g: Macros,
        notes: str;
}

obj StoreResult {
    has name: str,
        address: str,
        distance_miles: float,
        store_type: str,
        hours: str,
        items: list[FoodItem];
}

obj Ingredient {
    has item: str,
        quantity: str,
        store: str,
        estimated_price: float;
}

obj Recipe {
    has name: str,
        description: str,
        prep_time_mins: int,
        cook_time_mins: int,
        servings: int,
        estimated_cost: float,
        macros_per_serving: Macros,
        macro_deviation_pct: float,
        budget_deviation_pct: float,
        ingredients: list[Ingredient],
        instructions: list[str],
        tags: list[str];
}

obj LLMResult {
    has stores: list[StoreResult],
        recipes: list[Recipe],
        summary: str;
}

# ── Data Nodes ────────────────────────────────────────────────────────────────

node UserPreferences {
    has location: str,
        radius_miles: float,
        allergies: list[str],
        budget: float,
        calories: int,
        protein_g: int,
        carbs_g: int,
        fat_g: int,
        macro_flex_pct: int,
        conditions: list[str],
        restrictions: list[str],
        cached_result: dict = {},
        created_at: str = "";
}

node SearchResult {
    has stores: list[StoreResult] = [],
        recipes: list[Recipe] = [],
        summary: str = "",
        center_lat: float = 0.0,
        center_lng: float = 0.0,
        store_locations: list = [],
        created_at: str = "";
}

# ── Google Places Helpers (server-side Python) ────────────────────────────────

def geocode_location(location: str, api_key: str) -> dict {
    params = urlencode({"address": location, "key": api_key});
    url = "https://maps.googleapis.com/maps/api/geocode/json?" + params;
    resp = loads(urlopen(url).read().decode("utf-8"));
    if resp.get("status") == "OK" {
        loc = resp["results"][0]["geometry"]["location"];
        return {"lat": loc["lat"], "lng": loc["lng"]};
    }
    return {"error": resp.get("status", "UNKNOWN") + ": " + resp.get("error_message", "no details")};
}

def fetch_nearby_stores(lat: float, lng: float, radius_meters: int, api_key: str) -> list {
    params = urlencode({
        "location": str(lat) + "," + str(lng),
        "radius": str(radius_meters),
        "type": "grocery_or_supermarket",
        "key": api_key
    });
    url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?" + params;
    resp = loads(urlopen(url).read().decode("utf-8"));
    stores = [];
    if resp.get("status") == "OK" {
        for place in resp["results"] {
            slat = place["geometry"]["location"]["lat"];
            slng = place["geometry"]["location"]["lng"];
            dlat = (slat - lat) * 69.0;
            dlng = (slng - lng) * 69.0 * 0.7854;
            dist = round(sqrt(dlat * dlat + dlng * dlng), 2);
            stores.append({
                "name": place.get("name", ""),
                "address": place.get("vicinity", ""),
                "distance_miles": dist,
                "lat": slat,
                "lng": slng,
                "rating": place.get("rating", None),
                "types": place.get("types", []),
                "open_now": place.get("opening_hours", {}).get("open_now", None)
            });
        }
    }
    return stores;
}

# ── LLM Function — receives real stores, returns items + recipes ──────────────

"""
You are given `stores_json`: a JSON list of REAL grocery stores retrieved from the
Google Places API near the user's location. Each store has: name, address,
distance_miles, rating, types, open_now.

Your tasks:
1. For each store, suggest 4-6 specific food items that store realistically carries
   and that fit the user's constraints (see below).
2. Generate 3-5 practical recipes using ingredients from those stores.

HARD CONSTRAINTS — never violate under any circumstances:
  - `allergies`: Never suggest any food containing these allergens.
  - `conditions`: Never suggest foods incompatible with these medical conditions
    (e.g. diabetes -> avoid high-sugar items; celiac -> absolutely no gluten).
  - `restrictions`: Never violate these dietary lifestyles (vegan, halal, kosher, etc.).

SOFT CONSTRAINTS — target values per meal; may deviate by up to `macro_flex_pct`%:
  - calories (kcal), protein_g (g), carbs_g (g), fat_g (g)
  - budget (USD)

For each store, return a StoreResult with these fields:
  name, address, distance_miles (copy exactly from input),
  store_type (derive from the store's types list),
  hours ("Open now" or "Closed" based on open_now),
  items (list of FoodItem).

Each FoodItem: name, category, estimated_price, unit,
  macros_per_100g (Macros: calories, protein_g, carbs_g, fat_g), notes.

Each Recipe: name, description, prep_time_mins, cook_time_mins, servings,
  estimated_cost, macros_per_serving (Macros), macro_deviation_pct,
  budget_deviation_pct, ingredients (list of Ingredient: item, quantity, store,
  estimated_price), instructions (list of str), tags (list of str).

Return a single LLMResult with stores, recipes, and summary fields.
The summary must be ONE short sentence (under 15 words), e.g.
"Generated grocery store recommendations and recipes for the Ann Arbor area."
Do NOT include stats, macro numbers, store names, distances, or dietary details in the summary.
"""
def generate_items_and_recipes(
    stores_json: str,
    allergies: list[str],
    budget: float,
    calories: int,
    protein_g: int,
    carbs_g: int,
    fat_g: int,
    macro_flex_pct: int,
    conditions: list[str],
    restrictions: list[str]
) -> LLMResult by llm();

# ── Backend API ───────────────────────────────────────────────────────────────

walker:priv save_and_search {
    has location: str,
        radius_miles: float,
        allergies: list[str],
        budget: float,
        calories: int,
        protein_g: int,
        carbs_g: int,
        fat_g: int,
        macro_flex_pct: int,
        conditions: list[str],
        restrictions: list[str];

    can search with Root entry {
        places_key = environ.get("GOOGLE_PLACES_API_KEY", "");
        if not places_key {
            report {
                "stores": [],
                "recipes": [],
                "summary": "Error: GOOGLE_PLACES_API_KEY environment variable is not set."
            };
            disengage;
        }

        # Cache check: find a UserPreferences node with identical inputs and cached_result
        for pn in [-->] {
            if isinstance(pn, UserPreferences)
               and pn.location == self.location
               and pn.radius_miles == self.radius_miles
               and pn.allergies == self.allergies
               and pn.budget == self.budget
               and pn.calories == self.calories
               and pn.protein_g == self.protein_g
               and pn.carbs_g == self.carbs_g
               and pn.fat_g == self.fat_g
               and pn.macro_flex_pct == self.macro_flex_pct
               and pn.conditions == self.conditions
               and pn.restrictions == self.restrictions
               and pn.cached_result {
                cr = pn.cached_result;
                cr["maps_api_key"] = places_key;
                cr["cached"] = True;
                report cr;
                disengage;
            }
        }

        # Cache miss — full pipeline
        prefs = UserPreferences(
            location=self.location,
            radius_miles=self.radius_miles,
            allergies=self.allergies,
            budget=self.budget,
            calories=self.calories,
            protein_g=self.protein_g,
            carbs_g=self.carbs_g,
            fat_g=self.fat_g,
            macro_flex_pct=self.macro_flex_pct,
            conditions=self.conditions,
            restrictions=self.restrictions,
            created_at=str(datetime.now())
        );
        here ++> prefs;

        coords = geocode_location(self.location, places_key);
        if not coords or "error" in coords {
            geo_err = coords.get("error", "unknown error") if coords else "no response";
            report {
                "stores": [],
                "recipes": [],
                "summary": "Geocoding failed (" + geo_err + "). Check that the Geocoding API is enabled and billing is active in Google Cloud Console."
            };
            disengage;
        }

        radius_meters = int(self.radius_miles * 1609.34);
        raw_stores = fetch_nearby_stores(coords["lat"], coords["lng"], radius_meters, places_key);
        if not raw_stores {
            report {
                "stores": [],
                "recipes": [],
                "summary": "No grocery stores found within " + str(self.radius_miles) + " miles. Try increasing your radius."
            };
            disengage;
        }

        stores_json = dumps(raw_stores);
        data = generate_items_and_recipes(
            stores_json=stores_json,
            allergies=self.allergies,
            budget=self.budget,
            calories=self.calories,
            protein_g=self.protein_g,
            carbs_g=self.carbs_g,
            fat_g=self.fat_g,
            macro_flex_pct=self.macro_flex_pct,
            conditions=self.conditions,
            restrictions=self.restrictions
        );

        result_data = {
            "stores": data.stores,
            "recipes": data.recipes,
            "summary": data.summary,
            "center_lat": coords["lat"],
            "center_lng": coords["lng"],
            "radius_miles": self.radius_miles,
            "store_locations": raw_stores
        };
        prefs.cached_result = result_data;

        sr = SearchResult(
            stores=data.stores,
            recipes=data.recipes,
            summary=data.summary,
            center_lat=coords["lat"],
            center_lng=coords["lng"],
            store_locations=raw_stores,
            created_at=str(datetime.now())
        );
        prefs ++> sr;

        result_data["maps_api_key"] = places_key;
        result_data["cached"] = False;
        report result_data;
    }
}

# ── Load User Data API ────────────────────────────────────────────────────────

walker:priv load_user_data {
    can load with Root entry {
        latest: UserPreferences | None = None;
        latest_ts = "";
        for pn in [-->] {
            if isinstance(pn, UserPreferences) and pn.created_at > latest_ts {
                latest_ts = pn.created_at;
                latest = pn;
            }
        }
        if latest is None {
            report {};
            disengage;
        }
        result = {
            "location": latest.location,
            "radius_miles": latest.radius_miles,
            "allergies": latest.allergies,
            "budget": latest.budget,
            "calories": latest.calories,
            "protein_g": latest.protein_g,
            "carbs_g": latest.carbs_g,
            "fat_g": latest.fat_g,
            "macro_flex_pct": latest.macro_flex_pct,
            "conditions": latest.conditions,
            "restrictions": latest.restrictions
        };
        if latest.cached_result {
            cr = latest.cached_result;
            places_key = environ.get("GOOGLE_PLACES_API_KEY", "");
            result["stores"] = cr.get("stores", []);
            result["recipes"] = cr.get("recipes", []);
            result["summary"] = cr.get("summary", "");
            result["center_lat"] = cr.get("center_lat", 0);
            result["center_lng"] = cr.get("center_lng", 0);
            result["store_locations"] = cr.get("store_locations", []);
            result["maps_api_key"] = places_key;
        }
        report result;
    }
}

# ── Autocomplete API ─────────────────────────────────────────────────────────

walker:pub get_autocomplete {
    has query: str;

    can suggest with Root entry {
        places_key = environ.get("GOOGLE_PLACES_API_KEY", "");
        if not places_key or len(self.query) < 3 {
            report [];
            disengage;
        }
        params = urlencode({"input": self.query, "types": "geocode", "key": places_key});
        url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?" + params;
        resp = loads(urlopen(url).read().decode("utf-8"));
        if resp.get("status") == "OK" {
            report [p.get("description", "") for p in resp.get("predictions", [])[:5]];
        } else {
            report [];
        }
    }
}

# ── Client Component ──────────────────────────────────────────────────────────

import from "@jac/runtime" { jacSpawn, jacLogin, jacSignup, jacLogout, jacIsLoggedIn }

    def:pub app() -> JsxElement {
        # View state — starts at "landing" if not authenticated
        has view: str = ("form" if jacIsLoggedIn() else "landing");
        has active_tab: str = "stores";
        has error: str = "";

        # Form — location
        has location: str = "";
        has radius: str = "5";

        # Autocomplete
        has suggestions: list = [];
        has show_suggestions: bool = False;
        has debounce_id: any = None;

        # Form — hard constraints (tag lists)
        has allergy_input: str = "";
        has allergies: list = [];
        has condition_input: str = "";
        has conditions: list = [];
        has restriction_input: str = "";
        has restrictions: list = [];

        # Form — soft constraints
        has budget: str = "15";
        has calories: str = "550";
        has protein: str = "30";
        has carbs: str = "50";
        has fat: str = "30";
        has macro_flex: str = "20";

        # Results
        has stores: list = [];
        has recipes: list = [];
        has summary: str = "";
        has expanded_recipe: str = "";

        # Map (rendered as self-contained HTML for an iframe)
        has map_html: str = "";
        has _styles_injected: bool = False;

        # Multi-step form
        has form_step: int = 1;
        has show_advanced: bool = False;
        has selected_goal: str = "";

        # Auth
        has username: str = "";
        has password: str = "";
        has confirm_password: str = "";
        has auth_loading: bool = False;
        has auth_error: str = "";
        has _prefs_loaded: bool = False;

        # ── Shared styles ─────────────────────────────────────────────────────
        s_wrap = {"maxWidth": "1320px", "margin": "0 auto",
                  "fontFamily": "system-ui,-apple-system,sans-serif", "padding": "24px 16px"};
        s_card = {"background": "var(--cd)", "borderRadius": "12px", "padding": "24px",
                  "marginBottom": "20px", "boxShadow": "var(--sh)"};
        s_input = {"width": "100%", "padding": "10px 14px", "borderRadius": "8px",
                   "border": "1px solid var(--bd)", "fontSize": "14px", "boxSizing": "border-box",
                   "background": "var(--inp)", "color": "var(--tx)"};
        s_btn_primary = {"padding": "14px 32px", "background": "#2ecc71", "color": "white",
                         "border": "none", "borderRadius": "10px", "cursor": "pointer",
                         "fontSize": "15px", "fontWeight": "600", "width": "100%"};
        s_btn_add = {"padding": "8px 16px", "background": "#2ecc71", "color": "white",
                     "border": "none", "borderRadius": "8px", "cursor": "pointer",
                     "fontSize": "13px", "whiteSpace": "nowrap"};
        s_btn_ghost = {"padding": "8px 18px", "background": "none", "border": "1px solid var(--bd)",
                       "borderRadius": "8px", "cursor": "pointer", "fontSize": "14px",
                       "color": "var(--tx)"};
        s_btn_expand = {"background": "none", "border": "1px solid var(--be)", "borderRadius": "8px",
                        "padding": "8px 16px", "cursor": "pointer", "fontSize": "13px",
                        "color": "var(--t5)", "width": "100%", "marginTop": "12px"};
        s_tag_strict = {"display": "inline-flex", "alignItems": "center", "gap": "4px",
                        "background": "var(--rb)", "color": "var(--rt)", "borderRadius": "20px",
                        "padding": "3px 10px 3px 12px", "fontSize": "13px",
                        "marginRight": "6px", "marginBottom": "6px"};
        s_tag_x = {"background": "none", "border": "none", "cursor": "pointer",
                   "color": "var(--rt)", "fontSize": "14px", "padding": "0", "lineHeight": "1"};
        s_badge_strict = {"background": "var(--bb)", "color": "white", "borderRadius": "4px",
                          "padding": "1px 7px", "fontSize": "11px", "fontWeight": "700"};
        s_label = {"display": "block", "marginBottom": "6px", "fontSize": "13px",
                   "fontWeight": "600", "color": "var(--t5)"};
        s_pill_cal  = {"background": "var(--p1b)", "color": "var(--p1c)", "borderRadius": "6px",
                       "padding": "4px 10px", "fontSize": "12px", "fontWeight": "600"};
        s_pill_pro  = {"background": "var(--p2b)", "color": "var(--p2c)", "borderRadius": "6px",
                       "padding": "4px 10px", "fontSize": "12px", "fontWeight": "600"};
        s_pill_carb = {"background": "var(--p3b)", "color": "var(--p3c)", "borderRadius": "6px",
                       "padding": "4px 10px", "fontSize": "12px", "fontWeight": "600"};
        s_pill_fat  = {"background": "var(--p4b)", "color": "var(--p4c)", "borderRadius": "6px",
                       "padding": "4px 10px", "fontSize": "12px", "fontWeight": "600"};
        s_item_row  = {"display": "flex", "justifyContent": "space-between", "alignItems": "center",
                       "padding": "8px 12px", "background": "var(--rw)", "borderRadius": "8px"};
        s_ing_row   = {"display": "flex", "justifyContent": "space-between", "alignItems": "center",
                       "padding": "8px 0", "borderBottom": "1px solid var(--bf)", "fontSize": "14px"};
        s_dist_pill = {"background": "var(--gb)", "color": "var(--gt)", "borderRadius": "20px",
                       "padding": "4px 12px", "fontSize": "13px", "fontWeight": "600",
                       "display": "block", "marginBottom": "4px"};
        s_price_grn = {"color": "var(--gt)", "fontWeight": "700", "fontSize": "14px",
                       "whiteSpace": "nowrap", "marginLeft": "12px"};
        s_cost_pill = {"background": "var(--gb)", "color": "var(--gt)", "borderRadius": "20px",
                       "padding": "5px 14px", "fontSize": "14px", "fontWeight": "700",
                       "whiteSpace": "nowrap", "marginLeft": "16px", "flexShrink": "0"};
        s_summary   = {"background": "var(--gb)", "borderRadius": "12px", "padding": "16px",
                       "marginBottom": "20px", "borderLeft": "4px solid #2ecc71"};
        s_tag_grey  = {"display": "inline-block", "background": "var(--dv)", "color": "var(--t5)",
                       "borderRadius": "12px", "padding": "3px 10px", "fontSize": "12px",
                       "marginRight": "5px", "marginBottom": "4px"};
        s_error_box = {"background": "var(--rb)", "color": "var(--rt)", "borderRadius": "8px",
                       "padding": "12px 16px", "marginBottom": "16px", "fontSize": "14px"};

        # ── Tag-add helpers ───────────────────────────────────────────────────

        def add_allergy() {
            v = allergy_input.strip();
            if v and v not in allergies {
                allergies = allergies + [v];
                allergy_input = "";
            }
        }

        def add_condition() {
            v = condition_input.strip();
            if v and v not in conditions {
                conditions = conditions + [v];
                condition_input = "";
            }
        }

        def add_restriction() {
            v = restriction_input.strip();
            if v and v not in restrictions {
                restrictions = restrictions + [v];
                restriction_input = "";
            }
        }

        def toggle_allergy(item: str) {
            if item in allergies {
                allergies = [x for x in allergies if x != item];
            } else {
                allergies = allergies + [item];
            }
        }

        def toggle_condition(item: str) {
            if item in conditions {
                conditions = [x for x in conditions if x != item];
            } else {
                conditions = conditions + [item];
            }
        }

        def toggle_restriction(item: str) {
            if item in restrictions {
                restrictions = [x for x in restrictions if x != item];
            } else {
                restrictions = restrictions + [item];
            }
        }

        def apply_goal(goal: str) {
            selected_goal = goal;
            if goal == "lose_weight" { calories = "400"; protein = "35"; carbs = "35"; fat = "15"; }
            elif goal == "maintain" { calories = "550"; protein = "30"; carbs = "50"; fat = "30"; }
            elif goal == "build_muscle" { calories = "700"; protein = "50"; carbs = "60"; fat = "25"; }
            elif goal == "high_protein" { calories = "550"; protein = "45"; carbs = "35"; fat = "20"; }
            elif goal == "low_carb" { calories = "500"; protein = "35"; carbs = "20"; fat = "30"; }
            elif goal == "balanced" { calories = "550"; protein = "30"; carbs = "50"; fat = "25"; }
        }

        # ── Autocomplete ──────────────────────────────────────────────────────

        async def do_fetch_suggestions(q: str) {
            result = await jacSpawn("get_autocomplete", "", {"query": q});
            if result.reports and result.reports.length > 0 {
                suggestions = result.reports[0];
                show_suggestions = len(suggestions) > 0;
            }
        }

        def on_location_change(val: str) {
            location = val;
            if debounce_id is not None {
                clearTimeout(debounce_id);
            }
            if len(val) >= 3 {
                debounce_id = setTimeout(lambda -> None { do_fetch_suggestions(val); }, 400);
            } else {
                suggestions = [];
                show_suggestions = False;
            }
        }

        def select_suggestion(s: str) {
            location = s;
            suggestions = [];
            show_suggestions = False;
        }

        # ── Theme injection ───────────────────────────────────────────────────
        def inject_theme() {
            if not _styles_injected {
                _styles_injected = True;
                _s: any = document.createElement("style");
                _s.textContent = ":root{--pg:#f7f8fa;--cd:#fff;--inp:#fff;--rw:#f8f9fa;--tx:#1a1a1a;--t2:#888;--t3:#aaa;--t4:#bbb;--t5:#555;--t6:#333;--t7:#444;--t8:#666;--t9:#222;--ta:#777;--bd:#ddd;--be:#eee;--bf:#f5f5f5;--dv:#f0f0f0;--sh:0 2px 10px rgba(0,0,0,.07);--gb:#eafaf1;--gt:#27ae60;--gs:#1e8449;--rb:#fdecea;--rt:#c0392b;--bb:#e74c3c;--wn:#e74c3c;--fl:#f39c12;--p1b:#fff3e0;--p1c:#e67e22;--p2b:#e3f2fd;--p2c:#1565c0;--p3b:#f3e5f5;--p3c:#6a1b9a;--p4b:#fce4ec;--p4c:#ad1457;--hg:#f0fdf4;--sc:#f8f9fa}@media(prefers-color-scheme:dark){:root{--pg:#0a0a0a;--cd:#161616;--inp:#1e1e1e;--rw:#1a1a1a;--tx:#f0f0f0;--t2:#888;--t3:#666;--t4:#555;--t5:#a0a0a0;--t6:#d0d0d0;--t7:#c0c0c0;--t8:#a0a0a0;--t9:#e0e0e0;--ta:#888;--bd:#2a2a2a;--be:#222;--bf:#1a1a1a;--dv:#222;--sh:0 2px 12px rgba(0,0,0,.5);--gb:#0d1f0d;--gt:#4ade80;--gs:#4ade80;--rb:#2d1515;--rt:#f87171;--bb:#c0392b;--wn:#f87171;--fl:#fbbf24;--p1b:#2d2000;--p1c:#ffb74d;--p2b:#0a1e3a;--p2c:#64b5f6;--p3b:#1e0a2a;--p3c:#ce93d8;--p4b:#2a0a15;--p4c:#f48fb1;--hg:#0d1f0d;--sc:#111}}body{margin:0;background:var(--pg);color:var(--tx)}html{scroll-behavior:smooth}*{box-sizing:border-box}";
                (document.head as any).appendChild(_s);
            }
        }

        # ── Map helpers ───────────────────────────────────────────────────────
        # Google Maps JS API needs the `new` keyword (unsupported in Jac), so the
        # map is rendered inside a self-contained iframe via srcdoc.

        def build_map_html(api_key: str, clat: float, clng: float,
                           r_mi: float, raw_stores: list) -> str {
            sj = JSON.stringify(raw_stores);
            lat_s = str(clat);
            lng_s = str(clng);
            r_s = str(r_mi);
            return "<!DOCTYPE html><html><head>"
                + "<meta charset='utf-8'>"
                + "<style>*{margin:0;padding:0}html,body,#m{width:100%;height:100%}</style>"
                + "</head><body><div id='m'></div>"
                + "<script>"
                + "function initMap(){"
                + "var c={lat:" + lat_s + ",lng:" + lng_s + "};"
                + "var m=new google.maps.Map(document.getElementById('m'),{"
                + "center:c,zoom:12,disableDefaultUI:false,zoomControl:true,"
                + "mapTypeControl:false,streetViewControl:false,fullscreenControl:false});"
                + "new google.maps.Marker({position:c,map:m,title:'Your Location',"
                + "icon:{path:google.maps.SymbolPath.CIRCLE,scale:10,"
                + "fillColor:'#2ecc71',fillOpacity:1,strokeColor:'#fff',strokeWeight:3}});"
                + "new google.maps.Circle({map:m,center:c,radius:" + r_s + "*1609.34,"
                + "fillColor:'#2ecc71',fillOpacity:0.08,"
                + "strokeColor:'#2ecc71',strokeWeight:2,strokeOpacity:0.5});"
                + "var ss=" + sj + "||[];"
                + "for(var i=0;i<ss.length;i++){(function(s){"
                + "var la=parseFloat(s.lat||0),lo=parseFloat(s.lng||0);"
                + "if(!la||!lo)return;"
                + "var mk=new google.maps.Marker({position:{lat:la,lng:lo},map:m,title:s.name||''});"
                + "var iw=new google.maps.InfoWindow({content:"
                + "'<b>'+(s.name||'')+'</b><br><span style=color:#777>'+(s.address||'')+'</span>'});"
                + "mk.addListener('click',function(){iw.open(m,mk);});"
                + "})(ss[i])}"
                + "var b=new google.maps.LatLngBounds();"
                + "var rd=" + r_s + "/69.0,rl=" + r_s + "/(69.0*0.7854);"
                + "b.extend({lat:" + lat_s + "+rd,lng:" + lng_s + "});"
                + "b.extend({lat:" + lat_s + "-rd,lng:" + lng_s + "});"
                + "b.extend({lat:" + lat_s + ",lng:" + lng_s + "+rl});"
                + "b.extend({lat:" + lat_s + ",lng:" + lng_s + "-rl});"
                + "m.fitBounds(b);"
                + "}"
                + "</script>"
                + "<script src='https://maps.googleapis.com/maps/api/js?key="
                + api_key + "&callback=initMap' async defer></script>"
                + "</body></html>";
        }

        # ── Auth handlers ────────────────────────────────────────────────────

        async def apply_user_data() {
            result = await jacSpawn("load_user_data", "", {});
            if result.reports and result.reports.length > 0 {
                d = result.reports[0];
                if d and d["location"] {
                    location = d["location"] or "";
                    radius = str(d["radius_miles"] or "5");
                    allergies = d["allergies"] or [];
                    conditions = d["conditions"] or [];
                    restrictions = d["restrictions"] or [];
                    budget = str(d["budget"] or "15");
                    calories = str(d["calories"] or "550");
                    protein = str(d["protein_g"] or "30");
                    carbs = str(d["carbs_g"] or "50");
                    fat = str(d["fat_g"] or "30");
                    macro_flex = str(d["macro_flex_pct"] or "20");
                    if d["stores"] {
                        stores = d["stores"] or [];
                        recipes = d["recipes"] or [];
                        summary = d["summary"] or "";
                        ak = str(d["maps_api_key"] or "");
                        cl = float(d["center_lat"] or 0);
                        cg = float(d["center_lng"] or 0);
                        sl = d["store_locations"] or [];
                        if ak and cl and cg {
                            map_html = build_map_html(ak, cl, cg, float(radius), sl);
                        }
                        active_tab = "stores";
                        view = "results";
                        return;
                    }
                }
            }
            form_step = 1;
            view = "form";
        }

        async def handle_login() {
            if not username.strip() or not password {
                auth_error = "Please fill in all fields.";
                return;
            }
            auth_error = "";
            auth_loading = True;
            success = await jacLogin(username, password);
            auth_loading = False;
            if success {
                password = "";
                await apply_user_data();
            } else {
                auth_error = "Invalid username or password.";
            }
        }

        async def handle_signup() {
            if not username.strip() or not password {
                auth_error = "Please fill in all fields.";
                return;
            }
            if password != confirm_password {
                auth_error = "Passwords don't match.";
                return;
            }
            if len(password) < 4 {
                auth_error = "Password must be at least 4 characters.";
                return;
            }
            auth_error = "";
            auth_loading = True;
            result = await jacSignup(username, password);
            auth_loading = False;
            if result["success"] {
                password = "";
                confirm_password = "";
                await apply_user_data();
            } else {
                auth_error = result["error"] or "Signup failed.";
            }
        }

        def handle_logout() {
            jacLogout();
            stores = [];
            recipes = [];
            summary = "";
            map_html = "";
            location = "";
            allergies = [];
            conditions = [];
            restrictions = [];
            username = "";
            password = "";
            auth_error = "";
            form_step = 1;
            show_advanced = False;
            selected_goal = "";
            view = "landing";
        }

        # ── Submit ────────────────────────────────────────────────────────────

        async def handle_submit() {
            if not location.strip() {
                error = "Please enter your location.";
                return;
            }
            error = "";
            view = "loading";
            result = await jacSpawn("save_and_search", "", {
                "location": location.strip(),
                "radius_miles": float(radius),
                "allergies": allergies,
                "budget": float(budget),
                "calories": int(calories),
                "protein_g": int(protein),
                "carbs_g": int(carbs),
                "fat_g": int(fat),
                "macro_flex_pct": int(macro_flex),
                "conditions": conditions,
                "restrictions": restrictions
            });
            if result.reports and result.reports.length > 0 {
                data = result.reports[0];
                stores = data.stores or [];
                recipes = data.recipes or [];
                summary = data.summary or "";
                ak = str(data["maps_api_key"] or "");
                cl = float(data["center_lat"] or 0);
                cg = float(data["center_lng"] or 0);
                sl = data["store_locations"] or [];
                if ak and cl and cg {
                    map_html = build_map_html(ak, cl, cg, float(radius), sl);
                }
                active_tab = "stores";
                view = "results";
            } else {
                error = "Search failed. Please try again.";
                view = "form";
            }
        }

        async can with entry {
            inject_theme();
            if not _prefs_loaded and jacIsLoggedIn() {
                _prefs_loaded = True;
                await apply_user_data();
            }
        }

        # ═════════════════════════════════════════════════════════════════════
        # LANDING PAGE
        # ═════════════════════════════════════════════════════════════════════

        if view == "landing" {
            _lp = {"fontFamily": "system-ui,-apple-system,sans-serif", "minHeight": "100vh"};
            _sec = {"maxWidth": "1060px", "margin": "0 auto", "padding": "0 24px"};

            return <div style={_lp}>
                <nav style={{"position": "sticky", "top": "0", "zIndex": "100",
                              "background": "var(--pg)", "borderBottom": "1px solid var(--bd)"}}>
                    <div style={{"maxWidth": "1060px", "margin": "0 auto", "padding": "0 24px",
                                  "display": "flex", "justifyContent": "space-between",
                                  "alignItems": "center", "height": "56px"}}>
                        <span style={{"fontSize": "20px", "fontWeight": "800",
                                      "color": "var(--tx)", "letterSpacing": "-0.5px"}}>
                            {"🍽️ eatseek"}
                        </span>
                        <div style={{"display": "flex", "gap": "10px", "alignItems": "center"}}>
                            <button
                                onClick={lambda () { auth_error = ""; view = "login"; }}
                                style={{"padding": "7px 16px", "background": "none",
                                        "border": "1px solid var(--bd)", "borderRadius": "8px",
                                        "cursor": "pointer", "fontSize": "14px",
                                        "color": "var(--tx)"}}
                            >Sign In</button>
                            <button
                                onClick={lambda () { auth_error = ""; view = "signup"; }}
                                style={{"padding": "7px 16px", "background": "#2ecc71",
                                        "color": "white", "border": "none", "borderRadius": "8px",
                                        "cursor": "pointer", "fontSize": "14px",
                                        "fontWeight": "600"}}
                            >Get Started</button>
                        </div>
                    </div>
                </nav>

                <div style={{"padding": "80px 24px 60px", "maxWidth": "760px", "margin": "0 auto",
                              "textAlign": "center"}}>
                    <div style={{"display": "inline-block", "padding": "5px 14px",
                                  "background": "var(--hg)", "color": "var(--gt)",
                                  "borderRadius": "20px", "fontSize": "13px", "fontWeight": "600",
                                  "marginBottom": "20px", "border": "1px solid var(--gt)"}}>
                        AI-Powered Meal Planning
                    </div>
                    <h1 style={{"fontSize": "48px", "fontWeight": "800", "lineHeight": "1.1",
                                "margin": "0 0 20px", "color": "var(--tx)",
                                "letterSpacing": "-1px"}}>
                        {"Meal planning that starts with what's actually near you"}
                    </h1>
                    <p style={{"fontSize": "18px", "lineHeight": "1.6", "color": "var(--t5)",
                                "margin": "0 auto 32px", "maxWidth": "580px"}}>
                        {"Find real grocery stores in your area, then get personalized recipes that match your budget, diet, and macros using ingredients you can actually buy."}
                    </p>
                    <div style={{"display": "flex", "gap": "12px", "justifyContent": "center",
                                  "flexWrap": "wrap"}}>
                        <button
                            onClick={lambda () { auth_error = ""; view = "signup"; }}
                            style={{"padding": "14px 32px", "background": "#2ecc71",
                                    "color": "white", "border": "none", "borderRadius": "10px",
                                    "cursor": "pointer", "fontSize": "16px", "fontWeight": "700"}}
                        >Get Started Free</button>
                        <button
                            onClick={lambda () { auth_error = ""; view = "signup"; }}
                            style={{"padding": "14px 32px", "background": "none",
                                    "border": "1px solid var(--bd)", "borderRadius": "10px",
                                    "cursor": "pointer", "fontSize": "16px", "fontWeight": "600",
                                    "color": "var(--tx)"}}
                        >{"See How It Works"}</button>
                    </div>
                </div>

                <div style={{"maxWidth": "700px", "margin": "0 auto 80px", "padding": "0 24px"}}>
                    <div style={{"background": "var(--cd)", "borderRadius": "16px",
                                  "boxShadow": "var(--sh)", "overflow": "hidden",
                                  "border": "1px solid var(--bd)"}}>
                        <div style={{"padding": "16px 20px", "borderBottom": "1px solid var(--bd)",
                                      "display": "flex", "justifyContent": "space-between",
                                      "alignItems": "center"}}>
                            <span style={{"fontWeight": "700", "fontSize": "15px",
                                          "color": "var(--tx)"}}>
                                {"🍽️ Your Food Plan"}
                            </span>
                            <span style={{"fontSize": "13px", "color": "var(--t2)"}}>
                                {"📍 Ann Arbor, MI • 5 mi"}
                            </span>
                        </div>
                        <div style={{"padding": "16px 20px"}}>
                            <div style={{"display": "flex", "gap": "10px",
                                          "marginBottom": "14px"}}>
                                <div style={{"flex": "1", "background": "var(--rw)",
                                              "borderRadius": "10px", "padding": "12px 14px"}}>
                                    <div style={{"display": "flex", "justifyContent": "space-between",
                                                  "alignItems": "center"}}>
                                        <span style={{"fontWeight": "600", "fontSize": "14px",
                                                      "color": "var(--tx)"}}>{"Trader Joe's"}</span>
                                        <span style={{"color": "var(--gt)", "fontSize": "12px",
                                                      "fontWeight": "600"}}>0.8 mi</span>
                                    </div>
                                    <p style={{"margin": "4px 0 0", "fontSize": "12px",
                                                "color": "var(--t2)"}}>Open until 9 PM</p>
                                </div>
                                <div style={{"flex": "1", "background": "var(--rw)",
                                              "borderRadius": "10px", "padding": "12px 14px"}}>
                                    <div style={{"display": "flex", "justifyContent": "space-between",
                                                  "alignItems": "center"}}>
                                        <span style={{"fontWeight": "600", "fontSize": "14px",
                                                      "color": "var(--tx)"}}>Whole Foods</span>
                                        <span style={{"color": "var(--gt)", "fontSize": "12px",
                                                      "fontWeight": "600"}}>1.2 mi</span>
                                    </div>
                                    <p style={{"margin": "4px 0 0", "fontSize": "12px",
                                                "color": "var(--t2)"}}>Open until 10 PM</p>
                                </div>
                            </div>
                            <div style={{"background": "var(--rw)", "borderRadius": "10px",
                                          "padding": "14px 16px"}}>
                                <div style={{"display": "flex", "justifyContent": "space-between",
                                              "alignItems": "center", "marginBottom": "8px"}}>
                                    <span style={{"fontWeight": "700", "fontSize": "15px",
                                                  "color": "var(--tx)"}}>
                                        Mediterranean Chickpea Bowl
                                    </span>
                                    <span style={{"background": "var(--gb)", "color": "var(--gt)",
                                                  "borderRadius": "20px", "padding": "3px 10px",
                                                  "fontSize": "13px", "fontWeight": "600"}}>
                                        $4.50
                                    </span>
                                </div>
                                <div style={{"display": "flex", "gap": "6px", "flexWrap": "wrap"}}>
                                    <span style={{"background": "var(--p1b)", "color": "var(--p1c)",
                                                  "borderRadius": "6px", "padding": "3px 8px",
                                                  "fontSize": "11px", "fontWeight": "600"}}>
                                        520 cal
                                    </span>
                                    <span style={{"background": "var(--p2b)", "color": "var(--p2c)",
                                                  "borderRadius": "6px", "padding": "3px 8px",
                                                  "fontSize": "11px", "fontWeight": "600"}}>
                                        32g protein
                                    </span>
                                    <span style={{"background": "var(--p3b)", "color": "var(--p3c)",
                                                  "borderRadius": "6px", "padding": "3px 8px",
                                                  "fontSize": "11px", "fontWeight": "600"}}>
                                        48g carbs
                                    </span>
                                    <span style={{"background": "var(--p4b)", "color": "var(--p4c)",
                                                  "borderRadius": "6px", "padding": "3px 8px",
                                                  "fontSize": "11px", "fontWeight": "600"}}>
                                        18g fat
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div style={{"background": "var(--sc)", "padding": "80px 24px",
                              "borderTop": "1px solid var(--bd)",
                              "borderBottom": "1px solid var(--bd)"}}>
                    <div style={{"maxWidth": "1060px", "margin": "0 auto", "textAlign": "center"}}>
                        <h2 style={{"fontSize": "32px", "fontWeight": "800", "margin": "0 0 8px",
                                    "color": "var(--tx)", "letterSpacing": "-0.5px"}}>How It Works</h2>
                        <p style={{"color": "var(--t2)", "fontSize": "16px", "margin": "0 0 48px"}}>
                            Three steps to smarter meal planning
                        </p>
                        <div style={{"display": "flex", "gap": "24px", "flexWrap": "wrap",
                                      "justifyContent": "center"}}>
                            <div style={{"flex": "1", "minWidth": "240px", "maxWidth": "320px",
                                          "textAlign": "center"}}>
                                <div style={{"width": "48px", "height": "48px", "borderRadius": "50%",
                                              "background": "#2ecc71", "color": "white",
                                              "display": "inline-flex", "alignItems": "center",
                                              "justifyContent": "center", "fontSize": "20px",
                                              "fontWeight": "800", "marginBottom": "16px"}}>1</div>
                                <h3 style={{"margin": "0 0 8px", "fontSize": "18px",
                                            "fontWeight": "700", "color": "var(--tx)"}}>
                                    Set Your Location
                                </h3>
                                <p style={{"margin": "0", "fontSize": "14px", "lineHeight": "1.5",
                                            "color": "var(--t5)"}}>
                                    Enter your address and search radius to discover grocery stores nearby.
                                </p>
                            </div>
                            <div style={{"flex": "1", "minWidth": "240px", "maxWidth": "320px",
                                          "textAlign": "center"}}>
                                <div style={{"width": "48px", "height": "48px", "borderRadius": "50%",
                                              "background": "#2ecc71", "color": "white",
                                              "display": "inline-flex", "alignItems": "center",
                                              "justifyContent": "center", "fontSize": "20px",
                                              "fontWeight": "800", "marginBottom": "16px"}}>2</div>
                                <h3 style={{"margin": "0 0 8px", "fontSize": "18px",
                                            "fontWeight": "700", "color": "var(--tx)"}}>
                                    Add Your Preferences
                                </h3>
                                <p style={{"margin": "0", "fontSize": "14px", "lineHeight": "1.5",
                                            "color": "var(--t5)"}}>
                                    Set dietary restrictions, allergies, a per-meal budget, and macro targets.
                                </p>
                            </div>
                            <div style={{"flex": "1", "minWidth": "240px", "maxWidth": "320px",
                                          "textAlign": "center"}}>
                                <div style={{"width": "48px", "height": "48px", "borderRadius": "50%",
                                              "background": "#2ecc71", "color": "white",
                                              "display": "inline-flex", "alignItems": "center",
                                              "justifyContent": "center", "fontSize": "20px",
                                              "fontWeight": "800", "marginBottom": "16px"}}>3</div>
                                <h3 style={{"margin": "0 0 8px", "fontSize": "18px",
                                            "fontWeight": "700", "color": "var(--tx)"}}>
                                    Get Your Plan
                                </h3>
                                <p style={{"margin": "0", "fontSize": "14px", "lineHeight": "1.5",
                                            "color": "var(--t5)"}}>
                                    Receive AI-generated recipes using real ingredients from stores near you.
                                </p>
                            </div>
                        </div>
                    </div>
                </div>

                <div style={{"padding": "80px 24px", "maxWidth": "1060px", "margin": "0 auto"}}>
                    <div style={{"textAlign": "center", "marginBottom": "48px"}}>
                        <h2 style={{"fontSize": "32px", "fontWeight": "800", "margin": "0 0 8px",
                                    "color": "var(--tx)", "letterSpacing": "-0.5px"}}>
                            Everything you need for smarter meals
                        </h2>
                        <p style={{"color": "var(--t2)", "fontSize": "16px", "margin": "0"}}>
                            No generic recipe sites. Real stores, real prices, real plans.
                        </p>
                    </div>
                    <div style={{"display": "grid",
                                  "gridTemplateColumns": "repeat(auto-fit, minmax(240px, 1fr))",
                                  "gap": "20px"}}>
                        <div style={{"background": "var(--cd)", "borderRadius": "14px",
                                      "padding": "28px 24px", "boxShadow": "var(--sh)",
                                      "border": "1px solid var(--bd)"}}>
                            <div style={{"fontSize": "32px", "marginBottom": "14px"}}>🏪</div>
                            <h3 style={{"margin": "0 0 8px", "fontSize": "17px", "fontWeight": "700",
                                        "color": "var(--tx)"}}>Recipes From Real Stores</h3>
                            <p style={{"margin": "0", "fontSize": "14px", "lineHeight": "1.5",
                                        "color": "var(--t5)"}}>
                                Every recipe uses ingredients available at grocery stores within your radius. No guesswork.
                            </p>
                        </div>
                        <div style={{"background": "var(--cd)", "borderRadius": "14px",
                                      "padding": "28px 24px", "boxShadow": "var(--sh)",
                                      "border": "1px solid var(--bd)"}}>
                            <div style={{"fontSize": "32px", "marginBottom": "14px"}}>🥗</div>
                            <h3 style={{"margin": "0 0 8px", "fontSize": "17px", "fontWeight": "700",
                                        "color": "var(--tx)"}}>Diet-Aware Recommendations</h3>
                            <p style={{"margin": "0", "fontSize": "14px", "lineHeight": "1.5",
                                        "color": "var(--t5)"}}>
                                {"Kosher, vegan, gluten-free, halal -- set your restrictions and every result respects them."}
                            </p>
                        </div>
                        <div style={{"background": "var(--cd)", "borderRadius": "14px",
                                      "padding": "28px 24px", "boxShadow": "var(--sh)",
                                      "border": "1px solid var(--bd)"}}>
                            <div style={{"fontSize": "32px", "marginBottom": "14px"}}>💰</div>
                            <h3 style={{"margin": "0 0 8px", "fontSize": "17px", "fontWeight": "700",
                                        "color": "var(--tx)"}}>Budget & Macro Planning</h3>
                            <p style={{"margin": "0", "fontSize": "14px", "lineHeight": "1.5",
                                        "color": "var(--t5)"}}>
                                Set calorie, protein, carb, and fat targets plus a per-meal budget and stay on track.
                            </p>
                        </div>
                        <div style={{"background": "var(--cd)", "borderRadius": "14px",
                                      "padding": "28px 24px", "boxShadow": "var(--sh)",
                                      "border": "1px solid var(--bd)"}}>
                            <div style={{"fontSize": "32px", "marginBottom": "14px"}}>📱</div>
                            <h3 style={{"margin": "0 0 8px", "fontSize": "17px", "fontWeight": "700",
                                        "color": "var(--tx)"}}>Save & Resume Anytime</h3>
                            <p style={{"margin": "0", "fontSize": "14px", "lineHeight": "1.5",
                                        "color": "var(--t5)"}}>
                                Your preferences and results are saved. Come back and pick up right where you left off.
                            </p>
                        </div>
                    </div>
                </div>

                <div style={{"background": "var(--sc)", "padding": "80px 24px",
                              "textAlign": "center", "borderTop": "1px solid var(--bd)",
                              "borderBottom": "1px solid var(--bd)"}}>
                    <h2 style={{"fontSize": "32px", "fontWeight": "800", "margin": "0 0 12px",
                                "color": "var(--tx)", "letterSpacing": "-0.5px"}}>
                        Ready to plan smarter meals?
                    </h2>
                    <p style={{"color": "var(--t5)", "fontSize": "16px", "margin": "0 0 28px",
                                "maxWidth": "460px", "marginLeft": "auto", "marginRight": "auto",
                                "lineHeight": "1.5"}}>
                        Join Eatseek and start discovering recipes built around your real neighborhood.
                    </p>
                    <button
                        onClick={lambda () { auth_error = ""; view = "signup"; }}
                        style={{"padding": "14px 36px", "background": "#2ecc71", "color": "white",
                                "border": "none", "borderRadius": "10px", "cursor": "pointer",
                                "fontSize": "16px", "fontWeight": "700"}}
                    >Get Started Free</button>
                    <p style={{"marginTop": "16px", "fontSize": "14px", "color": "var(--t2)"}}>
                        {"Already have an account? "}
                        <span
                            onClick={lambda () { auth_error = ""; view = "login"; }}
                            style={{"color": "#2ecc71", "cursor": "pointer", "fontWeight": "600"}}
                        >{"Sign in"}</span>
                    </p>
                </div>

                <div style={{"padding": "24px", "textAlign": "center"}}>
                    <p style={{"margin": "0", "fontSize": "13px", "color": "var(--t3)"}}>
                        {"©2026 eatseek • Built for smarter grocery planning"}
                    </p>
                </div>
            </div>;
        }

        # ═════════════════════════════════════════════════════════════════════
        # LOGIN VIEW
        # ═════════════════════════════════════════════════════════════════════

        if view == "login" {
            return <div style={{"maxWidth": "420px", "margin": "0 auto",
                                "fontFamily": "system-ui,-apple-system,sans-serif",
                                "padding": "24px 16px"}}>
                <div style={{"textAlign": "center", "marginTop": "60px", "marginBottom": "28px"}}>
                    <div style={{"fontSize": "48px", "marginBottom": "12px"}}>🍽️</div>
                    <h1 style={{"fontSize": "28px", "margin": "0 0 8px", "color": "var(--tx)",
                                "fontWeight": "800"}}>Welcome back</h1>
                    <p style={{"color": "var(--t2)", "margin": "0", "fontSize": "14px"}}>
                        Sign in to your eatseek account
                    </p>
                </div>

                <div style={s_card}>
                    {auth_error and <div style={s_error_box}>⚠️ {auth_error}</div>}

                    <div style={{"marginBottom": "16px"}}>
                        <label style={s_label}>Username</label>
                        <input
                            value={username}
                            onChange={lambda (e: any) { username = e.target.value; }}
                            onKeyDown={lambda (e: any) {
                                if e.key == "Enter" { handle_login(); }
                            }}
                            placeholder="Enter username"
                            style={s_input}
                        />
                    </div>

                    <div style={{"marginBottom": "24px"}}>
                        <label style={s_label}>Password</label>
                        <input
                            type="password"
                            value={password}
                            onChange={lambda (e: any) { password = e.target.value; }}
                            onKeyDown={lambda (e: any) {
                                if e.key == "Enter" { handle_login(); }
                            }}
                            placeholder="Enter password"
                            style={s_input}
                        />
                    </div>

                    <button
                        onClick={lambda () { handle_login(); }}
                        disabled={auth_loading}
                        style={s_btn_primary}
                    >
                        {auth_loading and "Signing in..." or "Sign In"}
                    </button>

                    <p style={{"textAlign": "center", "marginTop": "16px", "fontSize": "14px",
                               "color": "var(--t2)"}}>
                        {"Don't have an account? "}
                        <span
                            onClick={lambda () { auth_error = ""; view = "signup"; }}
                            style={{"color": "#2ecc71", "cursor": "pointer", "fontWeight": "600"}}
                        >Sign up</span>
                    </p>
                </div>

                <p style={{"textAlign": "center", "marginTop": "8px", "fontSize": "14px",
                           "color": "var(--t3)"}}>
                    <span
                        onClick={lambda () { view = "landing"; }}
                        style={{"cursor": "pointer", "color": "var(--t2)"}}
                    >{"← Back to home"}</span>
                </p>
            </div>;
        }

        # ═════════════════════════════════════════════════════════════════════
        # SIGNUP VIEW
        # ═════════════════════════════════════════════════════════════════════

        if view == "signup" {
            return <div style={{"maxWidth": "420px", "margin": "0 auto",
                                "fontFamily": "system-ui,-apple-system,sans-serif",
                                "padding": "24px 16px"}}>
                <div style={{"textAlign": "center", "marginTop": "60px", "marginBottom": "28px"}}>
                    <div style={{"fontSize": "48px", "marginBottom": "12px"}}>🍽️</div>
                    <h1 style={{"fontSize": "28px", "margin": "0 0 8px", "color": "var(--tx)",
                                "fontWeight": "800"}}>Create your account</h1>
                    <p style={{"color": "var(--t2)", "margin": "0", "fontSize": "14px"}}>
                        Start planning smarter meals in seconds
                    </p>
                </div>

                <div style={s_card}>
                    {auth_error and <div style={s_error_box}>⚠️ {auth_error}</div>}

                    <div style={{"marginBottom": "16px"}}>
                        <label style={s_label}>Username</label>
                        <input
                            value={username}
                            onChange={lambda (e: any) { username = e.target.value; }}
                            placeholder="Choose a username"
                            style={s_input}
                        />
                    </div>

                    <div style={{"marginBottom": "16px"}}>
                        <label style={s_label}>Password</label>
                        <input
                            type="password"
                            value={password}
                            onChange={lambda (e: any) { password = e.target.value; }}
                            placeholder="Choose a password"
                            style={s_input}
                        />
                    </div>

                    <div style={{"marginBottom": "24px"}}>
                        <label style={s_label}>Confirm Password</label>
                        <input
                            type="password"
                            value={confirm_password}
                            onChange={lambda (e: any) { confirm_password = e.target.value; }}
                            onKeyDown={lambda (e: any) {
                                if e.key == "Enter" { handle_signup(); }
                            }}
                            placeholder="Confirm your password"
                            style={s_input}
                        />
                    </div>

                    <button
                        onClick={lambda () { handle_signup(); }}
                        disabled={auth_loading}
                        style={s_btn_primary}
                    >
                        {auth_loading and "Creating account..." or "Create Account"}
                    </button>

                    <p style={{"textAlign": "center", "marginTop": "16px", "fontSize": "14px",
                               "color": "var(--t2)"}}>
                        {"Already have an account? "}
                        <span
                            onClick={lambda () { auth_error = ""; view = "login"; }}
                            style={{"color": "#2ecc71", "cursor": "pointer", "fontWeight": "600"}}
                        >Sign in</span>
                    </p>
                </div>

                <p style={{"textAlign": "center", "marginTop": "8px", "fontSize": "14px",
                           "color": "var(--t3)"}}>
                    <span
                        onClick={lambda () { view = "landing"; }}
                        style={{"cursor": "pointer", "color": "var(--t2)"}}
                    >{"← Back to home"}</span>
                </p>
            </div>;
        }

        # ═════════════════════════════════════════════════════════════════════
        # LOADING VIEW
        # ═════════════════════════════════════════════════════════════════════

        if view == "loading" {
            return <div style={{"maxWidth": "660px", "margin": "100px auto", "textAlign": "center",
                                "fontFamily": "system-ui,sans-serif", "padding": "0 24px"}}>
                <div style={{"fontSize": "56px", "marginBottom": "20px"}}>🍽️</div>
                <h2 style={{"color": "#2ecc71", "fontSize": "24px", "marginBottom": "8px",
                            "fontWeight": "700"}}>Finding your perfect meals...</h2>
                <p style={{"color": "var(--t2)", "fontSize": "15px", "maxWidth": "420px",
                           "margin": "0 auto 32px", "lineHeight": "1.6"}}>
                    {"Searching stores near "} <strong>{location}</strong> {" and crafting recipes tailored to your preferences."}
                </p>
                <div style={{"display": "flex", "justifyContent": "center", "gap": "10px"}}>
                    <div style={{"width": "12px", "height": "12px", "borderRadius": "50%",
                                 "background": "#2ecc71"}} />
                    <div style={{"width": "12px", "height": "12px", "borderRadius": "50%",
                                 "background": "#2ecc71", "opacity": "0.6"}} />
                    <div style={{"width": "12px", "height": "12px", "borderRadius": "50%",
                                 "background": "#2ecc71", "opacity": "0.3"}} />
                </div>
            </div>;
        }

        # ═════════════════════════════════════════════════════════════════════
        # RESULTS VIEW
        # ═════════════════════════════════════════════════════════════════════

        if view == "results" {
            return <div style={s_wrap}>
                <div style={{"display": "flex", "justifyContent": "space-between",
                              "alignItems": "center", "marginBottom": "24px"}}>
                    <div>
                        <h1 style={{"margin": "0 0 4px", "fontSize": "24px", "color": "var(--tx)",
                                    "fontWeight": "700"}}>🍽️ Your Food Plan</h1>
                        <p style={{"margin": "0", "color": "var(--t2)", "fontSize": "14px"}}>
                            📍 {location} · {radius} mi radius
                        </p>
                    </div>
                    <div style={{"display": "flex", "gap": "8px"}}>
                        <button onClick={lambda () { form_step = 1; view = "form"; }} style={s_btn_ghost}>
                            ← New Search
                        </button>
                        <button onClick={lambda () { handle_logout(); }}
                            style={{"padding": "8px 14px", "background": "none",
                                    "border": "1px solid var(--bd)", "borderRadius": "8px",
                                    "cursor": "pointer", "fontSize": "13px", "color": "var(--t3)"}}>
                            Logout
                        </button>
                    </div>
                </div>

                {summary and <div style={s_summary}>
                    <p style={{"margin": "0", "color": "var(--gs)", "fontSize": "14px",
                               "lineHeight": "1.6"}}>{summary}</p>
                </div>}

                {map_html and <div style={s_card}>
                    <h3 style={{"margin": "0 0 12px", "fontSize": "15px", "color": "var(--t9)",
                                "fontWeight": "700"}}>🗺️ Nearby Stores</h3>
                    <iframe
                        srcDoc={map_html}
                        style={{"width": "100%", "height": "420px", "border": "none",
                                "borderRadius": "8px"}}
                    />
                </div>}

                <div style={{"display": "flex", "borderBottom": "2px solid var(--dv)",
                              "marginBottom": "24px"}}>
                    <button
                        onClick={lambda () { active_tab = "stores"; }}
                        style={{"padding": "12px 24px", "border": "none", "background": "none",
                                "cursor": "pointer", "fontSize": "15px", "fontWeight": "600",
                                "color": ("#2ecc71" if active_tab == "stores" else "var(--t3)"),
                                "borderBottom": ("3px solid #2ecc71" if active_tab == "stores"
                                                 else "3px solid transparent"),
                                "marginBottom": "-2px"}}
                    >
                        🏪 Stores ({str(len(stores))})
                    </button>
                    <button
                        onClick={lambda () { active_tab = "recipes"; }}
                        style={{"padding": "12px 24px", "border": "none", "background": "none",
                                "cursor": "pointer", "fontSize": "15px", "fontWeight": "600",
                                "color": ("#2ecc71" if active_tab == "recipes" else "var(--t3)"),
                                "borderBottom": ("3px solid #2ecc71" if active_tab == "recipes"
                                                 else "3px solid transparent"),
                                "marginBottom": "-2px"}}
                    >
                        👨‍🍳 Recipes ({str(len(recipes))})
                    </button>
                </div>

                {active_tab == "stores" and <div style={{"display": "grid",
                    "gridTemplateColumns": "repeat(2, 1fr)", "gap": "0 20px"}}>
                    {not stores and
                     <p style={{"color": "var(--t4)", "textAlign": "center", "padding": "40px 0",
                                "gridColumn": "1 / -1"}}>
                         No stores found. Try increasing your radius.
                     </p>}
                    {[<div key={s.address} style={s_card}>
                        <div style={{"display": "flex", "justifyContent": "space-between",
                                      "alignItems": "flex-start", "marginBottom": "12px"}}>
                            <div>
                                <h3 style={{"margin": "0 0 4px", "fontSize": "17px",
                                           "color": "var(--tx)"}}>{s.name}</h3>
                                <p style={{"margin": "0 0 2px", "color": "var(--ta)",
                                           "fontSize": "13px"}}>📍 {s.address}</p>
                                {s.hours and
                                 <p style={{"margin": "0", "color": "var(--t3)", "fontSize": "12px"}}>
                                     🕐 {s.hours}
                                 </p>}
                            </div>
                            <div style={{"textAlign": "right", "flexShrink": "0",
                                         "marginLeft": "12px"}}>
                                <span style={s_dist_pill}>{str(s.distance_miles)} mi</span>
                                <span style={{"color": "var(--t4)", "fontSize": "12px"}}>{s.store_type}</span>
                            </div>
                        </div>
                        {s.items and <div>
                            <p style={{"margin": "0 0 8px", "fontSize": "13px",
                                       "fontWeight": "600", "color": "var(--t8)",
                                       "borderTop": "1px solid var(--bf)",
                                       "paddingTop": "12px"}}>
                                Available Items
                            </p>
                            <div style={{"display": "grid", "gap": "6px"}}>
                                {[<div key={item.name} style={s_item_row}>
                                    <div>
                                        <span style={{"fontSize": "14px", "fontWeight": "500",
                                                      "color": "var(--t6)"}}>{item.name}</span>
                                        <span style={{"marginLeft": "8px", "fontSize": "11px",
                                                      "color": "var(--t3)", "background": "var(--be)",
                                                      "padding": "2px 7px",
                                                      "borderRadius": "10px"}}>
                                            {item.category}
                                        </span>
                                        {item.notes and
                                         <span style={{"marginLeft": "6px", "fontSize": "11px",
                                                       "color": "var(--t4)"}}>{item.notes}</span>}
                                    </div>
                                    <span style={s_price_grn}>
                                        {"$" + str(item.estimated_price) + "/" + item.unit}
                                    </span>
                                </div> for item in s.items]}
                            </div>
                        </div>}
                    </div> for s in stores]}
                </div>}

                {active_tab == "recipes" and <div style={{"display": "grid",
                    "gridTemplateColumns": "repeat(2, 1fr)", "gap": "0 20px"}}>
                    {not recipes and
                     <p style={{"color": "var(--t4)", "textAlign": "center", "padding": "40px 0",
                                "gridColumn": "1 / -1"}}>
                         No recipes found.
                     </p>}
                    {[<div key={r.name} style={s_card}>
                        <div style={{"display": "flex", "justifyContent": "space-between",
                                      "alignItems": "flex-start", "marginBottom": "10px"}}>
                            <div style={{"flex": "1"}}>
                                <h3 style={{"margin": "0 0 4px", "fontSize": "18px",
                                           "color": "var(--tx)"}}>{r.name}</h3>
                                <p style={{"margin": "0", "color": "var(--t2)", "fontSize": "14px",
                                           "lineHeight": "1.4"}}>{r.description}</p>
                            </div>
                            <span style={s_cost_pill}>{"$" + str(r.estimated_cost)}</span>
                        </div>

                        {r.macros_per_serving and
                         <div style={{"display": "flex", "flexWrap": "wrap", "gap": "6px",
                                       "marginBottom": "10px"}}>
                            <span style={s_pill_cal}>
                                🔥 {str(r.macros_per_serving.calories)} kcal
                            </span>
                            <span style={s_pill_pro}>
                                💪 {str(r.macros_per_serving.protein_g)}g protein
                            </span>
                            <span style={s_pill_carb}>
                                🌾 {str(r.macros_per_serving.carbs_g)}g carbs
                            </span>
                            <span style={s_pill_fat}>
                                🥑 {str(r.macros_per_serving.fat_g)}g fat
                            </span>
                         </div>}

                        <div style={{"display": "flex", "gap": "16px", "fontSize": "13px",
                                      "color": "var(--t2)", "marginBottom": "10px",
                                      "flexWrap": "wrap"}}>
                            <span>⏱ {str(r.prep_time_mins)}m prep</span>
                            <span>🔥 {str(r.cook_time_mins)}m cook</span>
                            <span>🍽 {str(r.servings)} serving(s)</span>
                            {r.macro_deviation_pct is not None and
                             <span>📊 {str(r.macro_deviation_pct)}% macro dev</span>}
                            {r.budget_deviation_pct is not None and
                             <span>💵 {str(r.budget_deviation_pct)}% budget dev</span>}
                        </div>

                        {r.tags and <div style={{"marginBottom": "12px"}}>
                            {[<span key={t} style={s_tag_grey}>{t}</span> for t in r.tags]}
                        </div>}

                        <button
                            onClick={lambda () {
                                expanded_recipe = ("" if expanded_recipe == r.name
                                                   else r.name);
                            }}
                            style={s_btn_expand}
                        >
                            {("▲ Hide Details" if expanded_recipe == r.name
                              else "▼ Ingredients & Instructions")}
                        </button>

                        {expanded_recipe == r.name and <div style={{"marginTop": "16px"}}>
                            <p style={{"fontWeight": "700", "fontSize": "14px",
                                       "marginBottom": "10px", "color": "var(--t6)"}}>
                                🛒 Ingredients
                            </p>
                            <div style={{"marginBottom": "16px"}}>
                                {[<div key={ing.item} style={s_ing_row}>
                                    <div>
                                        <span style={{"fontWeight": "500"}}>{ing.quantity}</span>
                                        <span style={{"marginLeft": "6px",
                                                      "color": "var(--t7)"}}>{ing.item}</span>
                                        <span style={{"marginLeft": "8px", "fontSize": "12px",
                                                      "color": "var(--t3)"}}>@ {ing.store}</span>
                                    </div>
                                    <span style={{"color": "var(--gt)", "fontWeight": "600"}}>
                                        {"$" + str(ing.estimated_price)}
                                    </span>
                                </div> for ing in r.ingredients]}
                            </div>
                            <p style={{"fontWeight": "700", "fontSize": "14px",
                                       "marginBottom": "10px", "color": "var(--t6)"}}>
                                👨‍🍳 Instructions
                            </p>
                            <ol style={{"paddingLeft": "20px", "margin": "0"}}>
                                {[<li key={step}
                                      style={{"marginBottom": "8px", "fontSize": "14px",
                                              "color": "var(--t7)", "lineHeight": "1.5"}}>
                                    {step}
                                </li> for step in r.instructions]}
                            </ol>
                        </div>}
                    </div> for r in recipes]}
                </div>}
            </div>;
        }

        # ═════════════════════════════════════════════════════════════════════
        # FORM VIEW — Multi-step Onboarding
        # ═════════════════════════════════════════════════════════════════════

        _steps = ["Location", "Dietary", "Goals", "Review"];
        _chip = {"display": "inline-flex", "alignItems": "center", "padding": "8px 16px",
                 "borderRadius": "20px", "fontSize": "13px", "cursor": "pointer",
                 "border": "1px solid var(--bd)", "background": "none", "color": "var(--t5)",
                 "marginRight": "8px", "marginBottom": "8px", "transition": "all .15s ease"};
        _chip_on = {"display": "inline-flex", "alignItems": "center", "padding": "8px 16px",
                    "borderRadius": "20px", "fontSize": "13px", "cursor": "pointer",
                    "border": "1px solid #2ecc71", "background": "#2ecc71", "color": "white",
                    "marginRight": "8px", "marginBottom": "8px", "fontWeight": "600",
                    "transition": "all .15s ease"};
        _step_card = {"background": "var(--cd)", "borderRadius": "16px", "padding": "32px 28px",
                      "boxShadow": "var(--sh)", "marginBottom": "24px"};
        _nav_row = {"display": "flex", "justifyContent": "space-between", "alignItems": "center",
                    "gap": "12px", "marginTop": "8px"};
        _btn_next = {"padding": "12px 28px", "background": "#2ecc71", "color": "white",
                     "border": "none", "borderRadius": "10px", "cursor": "pointer",
                     "fontSize": "15px", "fontWeight": "600"};
        _btn_back = {"padding": "12px 28px", "background": "none", "color": "var(--t5)",
                     "border": "1px solid var(--bd)", "borderRadius": "10px",
                     "cursor": "pointer", "fontSize": "15px"};
        _section_lbl = {"fontSize": "13px", "fontWeight": "600", "color": "var(--t5)",
                        "marginBottom": "10px", "display": "flex", "alignItems": "center",
                        "gap": "8px"};

        return <div style={{"maxWidth": "620px", "margin": "0 auto",
                            "fontFamily": "system-ui,-apple-system,sans-serif",
                            "padding": "24px 16px", "minHeight": "100vh"}}>

            <div style={{"display": "flex", "justifyContent": "space-between",
                          "alignItems": "center", "marginBottom": "32px"}}>
                <span style={{"fontSize": "20px", "fontWeight": "800", "color": "var(--tx)",
                              "letterSpacing": "-0.5px"}}>{"🍽️ eatseek"}</span>
                <button onClick={lambda () { handle_logout(); }}
                    style={{"padding": "6px 14px", "background": "none",
                            "border": "1px solid var(--bd)", "borderRadius": "8px",
                            "cursor": "pointer", "fontSize": "13px", "color": "var(--t3)"}}>
                    Logout
                </button>
            </div>

            <div style={{"display": "flex", "alignItems": "center", "marginBottom": "32px",
                          "gap": "0"}}>
                {[<div key={str(i)} style={{"display": "flex", "alignItems": "center",
                                            "flex": ("1" if i < 3 else "0 0 auto")}}>
                    <div style={{"display": "flex", "flexDirection": "column",
                                  "alignItems": "center", "gap": "6px", "position": "relative",
                                  "zIndex": "1"}}>
                        <div style={{"width": "32px", "height": "32px", "borderRadius": "50%",
                                      "display": "flex", "alignItems": "center",
                                      "justifyContent": "center", "fontSize": "13px",
                                      "fontWeight": "700",
                                      "background": ("#2ecc71" if (i + 1) <= form_step else "var(--dv)"),
                                      "color": ("white" if (i + 1) <= form_step else "var(--t4)"),
                                      "transition": "all .2s ease"}}>
                            {("✓" if (i + 1) < form_step else str(i + 1))}
                        </div>
                        <span style={{"fontSize": "11px", "fontWeight": "600",
                                      "color": ("var(--tx)" if (i + 1) == form_step else "var(--t4)"),
                                      "whiteSpace": "nowrap"}}>
                            {_steps[i]}
                        </span>
                    </div>
                    {(i < 3) and <div style={{"flex": "1", "height": "2px", "margin": "0 8px",
                                               "marginBottom": "20px",
                                               "background": ("#2ecc71" if (i + 1) < form_step else "var(--dv)"),
                                               "transition": "all .2s ease"}} />}
                </div> for i in range(4)]}
            </div>

            {error and <div style={s_error_box}>{"⚠️ "}{error}</div>}

            {form_step == 1 and <div>
                <div style={_step_card}>
                    <h2 style={{"margin": "0 0 4px", "fontSize": "22px", "fontWeight": "800",
                                "color": "var(--tx)"}}>{"Where are you?"}</h2>
                    <p style={{"margin": "0 0 24px", "fontSize": "14px", "color": "var(--t2)",
                               "lineHeight": "1.5"}}>
                        {"We'll find grocery stores near your location."}
                    </p>

                    <div style={{"marginBottom": "24px", "position": "relative"}}>
                        <label style={_section_lbl}>{"📍 Address or city"}</label>
                        <input
                            value={location}
                            onChange={lambda (e: any) { on_location_change(e.target.value); }}
                            onKeyDown={lambda (e: any) {
                                if e.key == "Enter" {
                                    suggestions = [];
                                    show_suggestions = False;
                                }
                                if e.key == "Escape" {
                                    suggestions = [];
                                    show_suggestions = False;
                                }
                            }}
                            onBlur={lambda (e: any) {
                                setTimeout(lambda -> None { show_suggestions = False; }, 150);
                            }}
                            placeholder="e.g. 123 Main St, Ann Arbor, MI"
                            style={{"width": "100%", "padding": "14px 16px", "borderRadius": "10px",
                                    "border": "1px solid var(--bd)", "fontSize": "15px",
                                    "boxSizing": "border-box", "background": "var(--inp)",
                                    "color": "var(--tx)"}}
                        />
                        {show_suggestions and <div style={{"position": "absolute", "top": "100%",
                                                            "left": "0", "right": "0",
                                                            "background": "var(--cd)",
                                                            "border": "1px solid var(--bd)",
                                                            "borderTop": "none",
                                                            "borderRadius": "0 0 10px 10px",
                                                            "boxShadow": "0 4px 12px rgba(0,0,0,0.15)",
                                                            "zIndex": "100"}}>
                            {[<div
                                key={s}
                                onMouseDown={lambda (e: any) { select_suggestion(s); }}
                                style={{"padding": "12px 16px", "cursor": "pointer",
                                        "fontSize": "14px", "color": "var(--t6)",
                                        "borderBottom": "1px solid var(--bf)"}}
                            >
                                {"📍 "}{s}
                            </div> for s in suggestions]}
                        </div>}
                    </div>

                    <div>
                        <label style={_section_lbl}>{"📏 Search radius"}</label>
                        <div style={{"display": "flex", "flexWrap": "wrap", "gap": "0"}}>
                            {[<span key={str(v)}
                                onClick={lambda () { radius = str(v); }}
                                style={(_chip_on if radius == str(v) else _chip)}
                            >{str(v)}{" mi"}</span> for v in [1, 3, 5, 10, 25]]}
                        </div>
                    </div>
                </div>

                <div style={_nav_row}>
                    <div />
                    <button
                        onClick={lambda () {
                            if location.strip() {
                                error = "";
                                form_step = 2;
                            } else {
                                error = "Please enter a location to continue.";
                            }
                        }}
                        style={_btn_next}
                    >{"Continue →"}</button>
                </div>
            </div>}

            {form_step == 2 and <div>
                <div style={_step_card}>
                    <h2 style={{"margin": "0 0 4px", "fontSize": "22px", "fontWeight": "800",
                                "color": "var(--tx)"}}>{"any dietary needs?"}</h2>
                    <p style={{"margin": "0 0 28px", "fontSize": "14px", "color": "var(--t2)",
                               "lineHeight": "1.5"}}>
                        {"Select anything that applies. These are strict — the AI will always respect them."}
                    </p>

                    <div style={{"marginBottom": "28px"}}>
                        <label style={_section_lbl}>
                            {"⚠️ Allergies"}
                            <span style={{"background": "var(--rb)", "color": "var(--rt)",
                                          "borderRadius": "4px", "padding": "1px 7px",
                                          "fontSize": "10px", "fontWeight": "700"}}>STRICT</span>
                        </label>
                        <div style={{"display": "flex", "flexWrap": "wrap", "gap": "0"}}>
                            {[<span key={a}
                                onClick={lambda () { toggle_allergy(a); }}
                                style={(_chip_on if a in allergies else _chip)}
                            >{a}</span> for a in ["Peanuts", "Tree Nuts", "Dairy", "Eggs",
                                                   "Shellfish", "Soy", "Wheat", "Gluten", "Fish",
                                                   "Sesame"]]}
                        </div>
                        <div style={{"display": "flex", "gap": "8px", "marginTop": "8px"}}>
                            <input
                                value={allergy_input}
                                onChange={lambda (e: any) { allergy_input = e.target.value; }}
                                onKeyDown={lambda (e: any) { if e.key == "Enter" { add_allergy(); } }}
                                placeholder="Other allergy..."
                                style={{"flex": "1", "padding": "8px 12px", "borderRadius": "8px",
                                        "border": "1px solid var(--bd)", "fontSize": "13px",
                                        "background": "var(--inp)", "color": "var(--tx)",
                                        "boxSizing": "border-box"}}
                            />
                            <button onClick={lambda () { add_allergy(); }}
                                style={{"padding": "8px 14px", "background": "var(--dv)",
                                        "border": "none", "borderRadius": "8px", "cursor": "pointer",
                                        "fontSize": "13px", "color": "var(--t5)"}}>+ Add</button>
                        </div>
                    </div>

                    <div style={{"marginBottom": "28px"}}>
                        <label style={_section_lbl}>
                            {"🥗 Dietary preferences"}
                            <span style={{"background": "var(--rb)", "color": "var(--rt)",
                                          "borderRadius": "4px", "padding": "1px 7px",
                                          "fontSize": "10px", "fontWeight": "700"}}>STRICT</span>
                        </label>
                        <div style={{"display": "flex", "flexWrap": "wrap", "gap": "0"}}>
                            {[<span key={r}
                                onClick={lambda () { toggle_restriction(r); }}
                                style={(_chip_on if r in restrictions else _chip)}
                            >{r}</span> for r in ["Vegetarian", "Vegan", "Kosher", "Halal",
                                                   "Keto", "Paleo", "Pescatarian",
                                                   "Gluten-Free", "Whole30"]]}
                        </div>
                        <div style={{"display": "flex", "gap": "8px", "marginTop": "8px"}}>
                            <input
                                value={restriction_input}
                                onChange={lambda (e: any) { restriction_input = e.target.value; }}
                                onKeyDown={lambda (e: any) { if e.key == "Enter" { add_restriction(); } }}
                                placeholder="Other preference..."
                                style={{"flex": "1", "padding": "8px 12px", "borderRadius": "8px",
                                        "border": "1px solid var(--bd)", "fontSize": "13px",
                                        "background": "var(--inp)", "color": "var(--tx)",
                                        "boxSizing": "border-box"}}
                            />
                            <button onClick={lambda () { add_restriction(); }}
                                style={{"padding": "8px 14px", "background": "var(--dv)",
                                        "border": "none", "borderRadius": "8px", "cursor": "pointer",
                                        "fontSize": "13px", "color": "var(--t5)"}}>+ Add</button>
                        </div>
                    </div>

                    <div>
                        <label style={_section_lbl}>
                            {"🏥 Medical conditions"}
                            <span style={{"background": "var(--rb)", "color": "var(--rt)",
                                          "borderRadius": "4px", "padding": "1px 7px",
                                          "fontSize": "10px", "fontWeight": "700"}}>STRICT</span>
                        </label>
                        <div style={{"display": "flex", "flexWrap": "wrap", "gap": "0"}}>
                            {[<span key={c}
                                onClick={lambda () { toggle_condition(c); }}
                                style={(_chip_on if c in conditions else _chip)}
                            >{c}</span> for c in ["Diabetes", "Celiac", "Hypertension",
                                                   "High Cholesterol", "Lactose Intolerance",
                                                   "IBS", "GERD"]]}
                        </div>
                        <div style={{"display": "flex", "gap": "8px", "marginTop": "8px"}}>
                            <input
                                value={condition_input}
                                onChange={lambda (e: any) { condition_input = e.target.value; }}
                                onKeyDown={lambda (e: any) { if e.key == "Enter" { add_condition(); } }}
                                placeholder="Other condition..."
                                style={{"flex": "1", "padding": "8px 12px", "borderRadius": "8px",
                                        "border": "1px solid var(--bd)", "fontSize": "13px",
                                        "background": "var(--inp)", "color": "var(--tx)",
                                        "boxSizing": "border-box"}}
                            />
                            <button onClick={lambda () { add_condition(); }}
                                style={{"padding": "8px 14px", "background": "var(--dv)",
                                        "border": "none", "borderRadius": "8px", "cursor": "pointer",
                                        "fontSize": "13px", "color": "var(--t5)"}}>+ Add</button>
                        </div>
                    </div>
                </div>

                <div style={_nav_row}>
                    <button onClick={lambda () { form_step = 1; }} style={_btn_back}>{"← Back"}</button>
                    <button onClick={lambda () { form_step = 3; }} style={_btn_next}>{"Continue →"}</button>
                </div>
            </div>}

            {form_step == 3 and <div>
                <div style={_step_card}>
                    <h2 style={{"margin": "0 0 4px", "fontSize": "22px", "fontWeight": "800",
                                "color": "var(--tx)"}}>{"Set your goals"}</h2>
                    <p style={{"margin": "0 0 28px", "fontSize": "14px", "color": "var(--t2)",
                               "lineHeight": "1.5"}}>
                        {"Choose a budget and goal. The AI can flex within your tolerance."}
                    </p>

                    <div style={{"marginBottom": "28px"}}>
                        <label style={_section_lbl}>{"💰 Per-meal budget"}</label>
                        <div style={{"display": "flex", "flexWrap": "wrap", "gap": "0"}}>
                            <span onClick={lambda () { budget = "8"; }}
                                style={(_chip_on if budget == "8" else _chip)}>{"Under $10"}</span>
                            <span onClick={lambda () { budget = "12"; }}
                                style={(_chip_on if budget == "12" else _chip)}>{"$10 – $15"}</span>
                            <span onClick={lambda () { budget = "17"; }}
                                style={(_chip_on if budget == "17" else _chip)}>{"$15 – $20"}</span>
                            <span onClick={lambda () { budget = "25"; }}
                                style={(_chip_on if budget == "25" else _chip)}>{"$20+"}</span>
                        </div>
                        <div style={{"display": "flex", "alignItems": "center", "gap": "8px",
                                      "marginTop": "8px"}}>
                            <span style={{"fontSize": "13px", "color": "var(--t5)"}}>{"Exact: $"}</span>
                            <input type="number" value={budget} min="1" max="200" step="0.5"
                                   onChange={lambda (e: any) { budget = e.target.value; }}
                                   style={{"width": "80px", "padding": "8px 10px",
                                           "borderRadius": "8px", "border": "1px solid var(--bd)",
                                           "fontSize": "14px", "background": "var(--inp)",
                                           "color": "var(--tx)", "boxSizing": "border-box"}} />
                            <span style={{"fontSize": "13px", "color": "var(--t4)"}}>/ meal</span>
                        </div>
                    </div>

                    <div style={{"marginBottom": "28px"}}>
                        <label style={_section_lbl}>{"🎯 Nutrition goal"}</label>
                        <div style={{"display": "flex", "flexWrap": "wrap", "gap": "0"}}>
                            <span onClick={lambda () { apply_goal("lose_weight"); }}
                                style={(_chip_on if selected_goal == "lose_weight" else _chip)}>
                                {"🔥 Lose Weight"}</span>
                            <span onClick={lambda () { apply_goal("maintain"); }}
                                style={(_chip_on if selected_goal == "maintain" else _chip)}>
                                {"⚖️ Maintain"}</span>
                            <span onClick={lambda () { apply_goal("build_muscle"); }}
                                style={(_chip_on if selected_goal == "build_muscle" else _chip)}>
                                {"💪 Build Muscle"}</span>
                            <span onClick={lambda () { apply_goal("high_protein"); }}
                                style={(_chip_on if selected_goal == "high_protein" else _chip)}>
                                {"🥩 High Protein"}</span>
                            <span onClick={lambda () { apply_goal("low_carb"); }}
                                style={(_chip_on if selected_goal == "low_carb" else _chip)}>
                                {"🥬 Low Carb"}</span>
                            <span onClick={lambda () { apply_goal("balanced"); }}
                                style={(_chip_on if selected_goal == "balanced" else _chip)}>
                                {"🍽️ Balanced"}</span>
                        </div>
                    </div>

                    <div>
                        <button onClick={lambda () { show_advanced = not show_advanced; }}
                            style={{"background": "none", "border": "none", "cursor": "pointer",
                                    "fontSize": "13px", "fontWeight": "600", "color": "var(--t5)",
                                    "padding": "0", "display": "flex", "alignItems": "center",
                                    "gap": "6px"}}>
                            {("▼" if show_advanced else "▶")}
                            {" Customize macros & flexibility"}
                        </button>
                        {show_advanced and <div style={{"marginTop": "16px", "padding": "20px",
                                                         "background": "var(--rw)",
                                                         "borderRadius": "12px"}}>
                            <div style={{"display": "grid", "gridTemplateColumns": "1fr 1fr",
                                          "gap": "14px"}}>
                                <div>
                                    <label style={s_label}>{"Calories (kcal)"}</label>
                                    <input type="number" value={calories} min="200" max="5000" step="50"
                                           onChange={lambda (e: any) { calories = e.target.value; selected_goal = ""; }}
                                           style={s_input} />
                                </div>
                                <div>
                                    <label style={s_label}>{"Protein (g)"}</label>
                                    <input type="number" value={protein} min="0" max="500"
                                           onChange={lambda (e: any) { protein = e.target.value; selected_goal = ""; }}
                                           style={s_input} />
                                </div>
                                <div>
                                    <label style={s_label}>{"Carbs (g)"}</label>
                                    <input type="number" value={carbs} min="0" max="1000"
                                           onChange={lambda (e: any) { carbs = e.target.value; selected_goal = ""; }}
                                           style={s_input} />
                                </div>
                                <div>
                                    <label style={s_label}>{"Fat (g)"}</label>
                                    <input type="number" value={fat} min="0" max="500"
                                           onChange={lambda (e: any) { fat = e.target.value; selected_goal = ""; }}
                                           style={s_input} />
                                </div>
                            </div>
                            <div style={{"marginTop": "14px"}}>
                                <label style={s_label}>{"Flexibility: ±"}{macro_flex}{"%"}</label>
                                <input type="range" min="0" max="50" value={macro_flex}
                                       onChange={lambda (e: any) { macro_flex = e.target.value; }}
                                       style={{"width": "100%", "accentColor": "#2ecc71",
                                               "cursor": "pointer"}} />
                                <div style={{"display": "flex", "justifyContent": "space-between",
                                              "fontSize": "11px", "color": "var(--t4)"}}>
                                    <span>Exact</span><span>Very flexible</span>
                                </div>
                            </div>
                            <p style={{"margin": "12px 0 0", "fontSize": "11px", "color": "var(--t4)",
                                       "lineHeight": "1.4"}}>
                                {"Flexibility applies to calories, macros, and budget. Allergies and restrictions are always strict."}
                            </p>
                        </div>}
                    </div>
                </div>

                <div style={_nav_row}>
                    <button onClick={lambda () { form_step = 2; }} style={_btn_back}>{"← Back"}</button>
                    <button onClick={lambda () { form_step = 4; }} style={_btn_next}>{"Continue →"}</button>
                </div>
            </div>}

            {form_step == 4 and <div>
                <div style={_step_card}>
                    <h2 style={{"margin": "0 0 4px", "fontSize": "22px", "fontWeight": "800",
                                "color": "var(--tx)"}}>{"Ready to generate"}</h2>
                    <p style={{"margin": "0 0 28px", "fontSize": "14px", "color": "var(--t2)",
                               "lineHeight": "1.5"}}>
                        {"Review your selections, then hit Generate."}
                    </p>

                    <div style={{"marginBottom": "20px", "padding": "16px 20px",
                                  "background": "var(--rw)", "borderRadius": "12px"}}>
                        <div style={{"display": "flex", "justifyContent": "space-between",
                                      "alignItems": "center", "marginBottom": "4px"}}>
                            <span style={{"fontSize": "13px", "fontWeight": "600",
                                          "color": "var(--t5)"}}>{"📍 Location"}</span>
                            <button onClick={lambda () { form_step = 1; }}
                                style={{"background": "none", "border": "none", "cursor": "pointer",
                                        "fontSize": "12px", "color": "#2ecc71",
                                        "fontWeight": "600"}}>Edit</button>
                        </div>
                        <p style={{"margin": "0", "fontSize": "15px", "fontWeight": "600",
                                   "color": "var(--tx)"}}>{location}</p>
                        <p style={{"margin": "2px 0 0", "fontSize": "13px",
                                   "color": "var(--t2)"}}>{radius}{" mile radius"}</p>
                    </div>

                    <div style={{"marginBottom": "20px", "padding": "16px 20px",
                                  "background": "var(--rw)", "borderRadius": "12px"}}>
                        <div style={{"display": "flex", "justifyContent": "space-between",
                                      "alignItems": "center", "marginBottom": "4px"}}>
                            <span style={{"fontSize": "13px", "fontWeight": "600",
                                          "color": "var(--t5)"}}>{"🥗 Dietary needs"}</span>
                            <button onClick={lambda () { form_step = 2; }}
                                style={{"background": "none", "border": "none", "cursor": "pointer",
                                        "fontSize": "12px", "color": "#2ecc71",
                                        "fontWeight": "600"}}>Edit</button>
                        </div>
                        {(len(allergies) > 0 or len(restrictions) > 0 or len(conditions) > 0)
                          and <div style={{"display": "flex", "flexWrap": "wrap", "gap": "6px",
                                            "marginTop": "8px"}}>
                            {[<span key={t} style={{"display": "inline-block", "padding": "4px 12px",
                                                     "borderRadius": "16px", "fontSize": "12px",
                                                     "fontWeight": "600",
                                                     "background": "var(--rb)",
                                                     "color": "var(--rt)"}}>{t}</span>
                              for t in allergies]}
                            {[<span key={t} style={{"display": "inline-block", "padding": "4px 12px",
                                                     "borderRadius": "16px", "fontSize": "12px",
                                                     "fontWeight": "600",
                                                     "background": "var(--gb)",
                                                     "color": "var(--gt)"}}>{t}</span>
                              for t in restrictions]}
                            {[<span key={t} style={{"display": "inline-block", "padding": "4px 12px",
                                                     "borderRadius": "16px", "fontSize": "12px",
                                                     "fontWeight": "600",
                                                     "background": "var(--p2b)",
                                                     "color": "var(--p2c)"}}>{t}</span>
                              for t in conditions]}
                        </div>}
                        {(len(allergies) == 0 and len(restrictions) == 0 and len(conditions) == 0)
                          and <p style={{"margin": "4px 0 0", "fontSize": "13px",
                                         "color": "var(--t4)", "fontStyle": "italic"}}>
                            {"None selected"}
                        </p>}
                    </div>

                    <div style={{"padding": "16px 20px", "background": "var(--rw)",
                                  "borderRadius": "12px"}}>
                        <div style={{"display": "flex", "justifyContent": "space-between",
                                      "alignItems": "center", "marginBottom": "4px"}}>
                            <span style={{"fontSize": "13px", "fontWeight": "600",
                                          "color": "var(--t5)"}}>{"🎯 Goals & Budget"}</span>
                            <button onClick={lambda () { form_step = 3; }}
                                style={{"background": "none", "border": "none", "cursor": "pointer",
                                        "fontSize": "12px", "color": "#2ecc71",
                                        "fontWeight": "600"}}>Edit</button>
                        </div>
                        <div style={{"display": "flex", "gap": "10px", "flexWrap": "wrap",
                                      "marginTop": "8px"}}>
                            <span style={{"display": "inline-flex", "alignItems": "center",
                                          "gap": "4px", "padding": "5px 12px",
                                          "borderRadius": "8px", "fontSize": "13px",
                                          "fontWeight": "600",
                                          "background": "var(--gb)", "color": "var(--gt)"}}>
                                {"💰 $"}{budget}{"/meal"}
                            </span>
                            {selected_goal and <span style={{"display": "inline-flex",
                                          "alignItems": "center", "gap": "4px",
                                          "padding": "5px 12px", "borderRadius": "8px",
                                          "fontSize": "13px", "fontWeight": "600",
                                          "background": "var(--p1b)", "color": "var(--p1c)"}}>
                                {"🎯 "}{selected_goal.replace("_", " ").title()}
                            </span>}
                        </div>
                        <div style={{"display": "flex", "gap": "8px", "flexWrap": "wrap",
                                      "marginTop": "10px"}}>
                            <span style={s_pill_cal}>{calories}{" kcal"}</span>
                            <span style={s_pill_pro}>{protein}{"g protein"}</span>
                            <span style={s_pill_carb}>{carbs}{"g carbs"}</span>
                            <span style={s_pill_fat}>{fat}{"g fat"}</span>
                            <span style={{"padding": "4px 10px", "borderRadius": "6px",
                                          "fontSize": "12px", "fontWeight": "600",
                                          "background": "var(--dv)",
                                          "color": "var(--t5)"}}>{"±"}{macro_flex}{"%"}</span>
                        </div>
                    </div>
                </div>

                <div style={{"display": "flex", "flexDirection": "column", "gap": "10px"}}>
                    <button onClick={lambda () { handle_submit(); }}
                        style={{"padding": "16px 32px", "background": "#2ecc71", "color": "white",
                                "border": "none", "borderRadius": "12px", "cursor": "pointer",
                                "fontSize": "16px", "fontWeight": "700", "width": "100%"}}>
                        {"🚀 Generate My Plan"}
                    </button>
                    <button onClick={lambda () { form_step = 3; }} style={{"padding": "10px",
                            "background": "none", "border": "none", "cursor": "pointer",
                            "fontSize": "14px", "color": "var(--t4)"}}>
                        {"← Go back"}
                    </button>
                </div>
            </div>}

            <div style={{"height": "48px"}} />
        </div>;
    }

