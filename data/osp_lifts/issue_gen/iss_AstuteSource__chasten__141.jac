"""AstuteSource/chasten#141 — model a cached, multi-platform CI workflow."""

node Job {
    has name: str;
    has os_name: str;
    has version: str;
    has cached_install: bool = True;
    has coverage_job: bool = False;
}

edge Requires {}

obj Pipeline {
    has entry: Job | None = None;
    has coverage_floor: int = 0;
}

walker LocateJob {
    has target: str;
    has found: Job | None = None;
    has claimed: dict[str, bool] = {};

    can locate with Job entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        print("locate " + here.name);
        if here.name == self.target {
            self.found = here;
        }
        for kid in [here ->:Requires:->][?:Job] {
            visit :0: [kid];
        }
    }
}

walker CollectJobs {
    has claimed: dict[str, bool] = {};
    has names: list[str] = [];

    can collect with Job entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        print("collect " + here.name);
        self.names.append(here.name);
        for kid in [here ->:Requires:->][?:Job] {
            visit :0: [kid];
        }
    }
}

def make_pipeline(
    versions: list[str],
    platforms: list[str],
    coverage_floor: int
) -> Pipeline {
    pipe = Pipeline(coverage_floor=coverage_floor);
    coverage = Job(
        name="coverage",
        os_name="ubuntu-latest",
        version="3.14",
        coverage_job=True
    );
    report = Job(
        name="coverage-report",
        os_name="ubuntu-latest",
        version="3.14"
    );
    pipe.entry = coverage;
    coverage +>:Requires:+> report;

    for version in versions {
        lint = Job(
            name="lint-" + version,
            os_name="ubuntu-latest",
            version=version
        );
        typecheck = Job(
            name="typecheck-" + version,
            os_name="ubuntu-latest",
            version=version
        );
        test_job = Job(
            name="test-ubuntu-" + version,
            os_name="ubuntu-latest",
            version=version
        );
        coverage +>:Requires:+> lint;
        coverage +>:Requires:+> typecheck;
        coverage +>:Requires:+> test_job;
        lint +>:Requires:+> report;
        typecheck +>:Requires:+> report;
        test_job +>:Requires:+> report;
    }

    for platform in platforms {
        if platform != "ubuntu-latest" {
            test_job = Job(
                name="test-" + platform,
                os_name=platform,
                version="3.14"
            );
            coverage +>:Requires:+> test_job;
            test_job +>:Requires:+> report;
        }
    }
    return pipe;
}

def collect_jobs(pipe: Pipeline, start_id: str) -> list[str] {
    if pipe.entry == None { return []; }
    locate = pipe.entry spawn LocateJob(target=start_id);
    if locate.found != None {
        seed: Job = locate.found;
        collected = seed spawn CollectJobs();
        return sorted(collected.names);
    }
    return [];
}

def coverage_gate(pipe: Pipeline, measured_percent: int) -> bool {
    return measured_percent >= pipe.coverage_floor;
}
