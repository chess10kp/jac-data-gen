"""akomapahealth/akomapa-lms#105 performance budgets, batch catalog load, scoped cache."""

node Course {
    has cid: str;
    has title: str;
}

node Lesson {
    has lid: str;
    has title: str;
}

node ProfilerState {
    has query_count: int = 0;
    has budgets: dict[str, int] = {};
    has cache_store: dict[str, dict[str, str]] = {};
}

edge CourseLesson {}
edge CoursePrereq {}

walker BatchLessonWalker {
    has claimed: dict[str, bool] = {};
    has course_ids: list[str] = [];
    has result: dict[str, list[str]] = {};

    can boot with node entry {
        visit [-->] else { disengage; }
    }

    can collect with Course entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        wanted: bool = False;
        for cid in self.course_ids {
            if cid == here.cid { wanted = True; }
        }
        if not wanted { skip; }
        lids: list[str] = [];
        kids: list[Lesson] = [here ->:CourseLesson:->][?:Lesson];
        for kid in kids { lids.append(kid.lid); }
        lids.sort();
        self.result[here.cid] = lids;
        print ["batch", here.cid, len(lids)];
    }
}

walker NaiveLessonWalker {
    has claimed: dict[str, bool] = {};
    has profiler: ProfilerState;
    has target_cid: str;
    has result: dict[str, list[str]] = {};

    can boot with node entry {
        visit [-->] else { disengage; }
    }

    can one with Course entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid != self.target_cid { skip; }
        self.profiler.query_count += 1;
        lids: list[str] = [];
        kids: list[Lesson] = [here ->:CourseLesson:->][?:Lesson];
        for kid in kids { lids.append(kid.lid); }
        lids.sort();
        self.result[here.cid] = lids;
        print ["naive", here.cid, len(lids)];
    }
}

walker PrereqWalker {
    has claimed: dict[str, bool] = {};
    has visited: list[str] = [];

    can boot with node entry {
        visit [-->] else { disengage; }
    }

    can walk with Course entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.visited.append(here.cid);
        print ["pre", here.cid];
        nxt: list[Course] = [here ->:CoursePrereq:->][?:Course];
        visit :0: nxt else { disengage; }
    }
}

def make_profiler() -> ProfilerState {
    return ProfilerState();
}

def set_budget(profiler: ProfilerState, metric: str, limit: int) {
    profiler.budgets[metric] = limit;
}

def get_query_count(profiler: ProfilerState) -> int {
    return profiler.query_count;
}

def check_budget(profiler: ProfilerState, metric: str) -> bool {
    if metric not in profiler.budgets { return True; }
    return profiler.query_count <= profiler.budgets[metric];
}

def seed_catalog(graph_root: node, courses: list[str], lessons: dict[str, list[str]], prereq_pairs: list[list[str]] | None = None) -> dict[str, Course] {
    index: dict[str, Course] = {};
    for cid in courses {
        c = Course(cid=cid, title=cid);
        root ++> c;
        index[cid] = c;
    }
    for cid in lessons {
        if cid not in index { continue; }
        cnode = index[cid];
        lids: list[str] = lessons[cid];
        for lid in lids {
            le = Lesson(lid=lid, title=lid);
            cnode +>:CourseLesson:+> le;
        }
    }
    pairs: list[list[str]] = [];
    if prereq_pairs != None { pairs = prereq_pairs; }
    for pair in pairs {
        if pair[0] not in index { continue; }
        if pair[1] not in index { continue; }
        index[pair[0]] +>:CoursePrereq:+> index[pair[1]];
    }
    return index;
}

def load_courses_batched(profiler: ProfilerState, graph_root: node, course_ids: list[str]) -> dict[str, list[str]] {
    w = root spawn BatchLessonWalker(course_ids=course_ids);
    profiler.query_count += 1;
    return w.result;
}

def load_courses_naive(profiler: ProfilerState, graph_root: node, course_ids: list[str]) -> dict[str, list[str]] {
    merged: dict[str, list[str]] = {};
    for cid in course_ids {
        nw = root spawn NaiveLessonWalker(profiler=profiler, target_cid=cid);
        for k in nw.result { merged[k] = nw.result[k]; }
    }
    return merged;
}

def cache_set(profiler: ProfilerState, key: str, user_id: str, value: str) {
    bucket: dict[str, str] = {};
    if user_id in profiler.cache_store { bucket = profiler.cache_store[user_id]; }
    bucket[key] = value;
    profiler.cache_store[user_id] = bucket;
}

def cache_get(profiler: ProfilerState, key: str, user_id: str) -> str | None {
    if user_id not in profiler.cache_store { return None; }
    bucket = profiler.cache_store[user_id];
    if key not in bucket { return None; }
    return bucket[key];
}

def cache_invalidate_course(profiler: ProfilerState, course_id: str) {
    cache_key = "course:" + course_id;
    for uid in profiler.cache_store {
        old_bucket = profiler.cache_store[uid];
        new_bucket: dict[str, str] = {};
        for k in old_bucket {
            if k != cache_key { new_bucket[k] = old_bucket[k]; }
        }
        profiler.cache_store[uid] = new_bucket;
    }
}
