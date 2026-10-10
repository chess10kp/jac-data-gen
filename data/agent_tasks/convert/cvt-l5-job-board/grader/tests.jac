# Hidden tests for the job-board port (in-process walker spawns). The graph store
# persists between tests: organisations/jobs are uuid-tagged, asserts are deltas.
import uuid;
import from main { Organisation, Job, Posted, welcome_page, sign_org_up, sign_org_in, sign_org_out,
                   insert_org_data, get_org_data, get_jobs, create_job, get_job, update_job, delete_job }

glob CO: dict[str, str] = {"location": "USA", "companyBio": "Big tech", "industry": "Technology",
                           "telephone": "+447398346125", "companySize": "10,000+ Employees"};

def first(rs: list[any]) -> dict[str, any] {
    assert len(rs) > 0;
    return dict(rs[0]);
}

def rows(rs: list[any]) -> list[dict[str, any]] {
    xs = rs[0] if len(rs) == 1 and isinstance(rs[0], list) else rs;
    return [dict(x) for x in xs];
}

def org(tag: str) -> str {
    email = f"hr-{tag}@example.com";
    r = first((root spawn sign_org_up(companyName="Acme " + tag, email=email, password="Strong+Password")).reports);
    assert r["action"] == "Sign Up" and r["message"] == f"New org registered with email {email}";
    return email;
}

def post(email: str, title: str, role: str, skills: list[str], location: str) -> None {
    r = first((root spawn create_job(email=email, title=title, role=role, description="d", industry="IT",
                                     skillset=skills, company=CO, experience="0-2 years", salary=1500.0,
                                     location=location)).reports);
    assert r["action"] == "Job Created" and r["message"] == "Job Post created";
}

def jobs_titled(t: str) -> list[dict[str, any]] {
    return rows((root spawn get_jobs(title=t)).reports);
}

test "welcome and sign out" {
    assert first((root spawn welcome_page()).reports)["message"] == "Welcome to the BGN task everyone.";
    assert first((root spawn sign_org_out()).reports)["message"] == "You have successfully signed out.";
}

test "sign up, duplicate, sign in" {
    tag = uuid.uuid4().hex[:8];
    email = org(tag);
    dup = first((root spawn sign_org_up(companyName="X", email=email, password="p")).reports);
    assert dup["error"] == "Organisation with email exist already!";
    assert len([o for o in [root -->[?:Organisation]] if o.email == email]) == 1;
    stored = [o for o in [root -->[?:Organisation]] if o.email == email][0];
    assert stored.password != "Strong+Password";
    ok = first((root spawn sign_org_in(email=email, password="Strong+Password")).reports);
    assert ok["message"] == "Sign In Successful";
    bad = first((root spawn sign_org_in(email=email, password="wrong")).reports);
    assert bad["error"] == "Invalid Operation";
    none = first((root spawn sign_org_in(email="nobody-" + tag + "@x.com", password="p")).reports);
    assert none["error"] == "Incorrect Details";
}

test "organisation profile" {
    tag = uuid.uuid4().hex[:8];
    email = org(tag);
    assert len(first((root spawn get_org_data(email=email)).reports)) == 0;
    r = first((root spawn insert_org_data(email=email, location="UK", companyBio="bio", industry="Tech",
                                          telephone="123")).reports);
    assert r["message"] == "Organisation's data saved successfully.";
    p = first((root spawn get_org_data(email=email)).reports);
    assert p["location"] == "UK" and p["industry"] == "Tech" and p["companySize"] is None;
    missing = first((root spawn insert_org_data(email="ghost-" + tag + "@x.com", location="a", companyBio="b",
                                                industry="c", telephone="d")).reports);
    assert missing["error"] == "Operation not found.";
}

test "jobs hang off the posting organisation" {
    tag = uuid.uuid4().hex[:8];
    email = org(tag);
    post(email, "Engineer " + tag, "Junior", ["Go", "Python"], "Remote");
    o = [x for x in [root -->[?:Organisation]] if x.email == email][0];
    mine = [j for j in [o ->:Posted:->]];
    assert len(mine) == 1 and mine[0].title == "Engineer " + tag;
    got = jobs_titled("Engineer " + tag);
    assert len(got) == 1;
    assert dict(got[0]["company"])["name"] == "Acme " + tag;
    assert dict(got[0]["company"])["telephone"] == "+447398346125";
    assert list(got[0]["skillset"]) == ["Go", "Python"] and got[0]["salary"] == 1500.0;
}

test "filters are a union in filter order, duplicates kept" {
    tag = uuid.uuid4().hex[:8];
    email = org(tag);
    post(email, "A" + tag, "senior-" + tag, ["Go"], "Remote");
    post(email, "B" + tag, "junior", ["Go"], "loc-" + tag);
    post(email, "C" + tag, "senior-" + tag, ["Jira"], "loc-" + tag);
    by_company = rows((root spawn get_jobs(company="Acme " + tag)).reports);
    assert [j["title"] for j in by_company] == ["A" + tag, "B" + tag, "C" + tag];
    mixed = rows((root spawn get_jobs(role="senior-" + tag, location="loc-" + tag)).reports);
    assert [j["title"] for j in mixed] == ["A" + tag, "C" + tag, "B" + tag, "C" + tag];
    both = rows((root spawn get_jobs(company="Acme " + tag, title="B" + tag)).reports);
    assert [j["title"] for j in both] == ["A" + tag, "B" + tag, "C" + tag, "B" + tag];
    everything = rows((root spawn get_jobs()).reports);
    assert len([j for j in everything if str(j["title"]).endswith(tag)]) == 3;
}

test "get, update and delete a job" {
    tag = uuid.uuid4().hex[:8];
    email = org(tag);
    post(email, "Keep " + tag, "r", ["Go"], "Remote");
    post(email, "Edit " + tag, "r", ["Go"], "Remote");
    jid_edit = jobs_titled("Edit " + tag)[0]["id"];
    jid_keep = jobs_titled("Keep " + tag)[0]["id"];
    assert first((root spawn get_job(job_id=jid_edit)).reports)["title"] == "Edit " + tag;
    assert first((root spawn get_job(job_id="0" * 24)).reports)["error"] == "Job does not exist";
    u = first((root spawn update_job(job_id=jid_edit, title="Edited " + tag, role="lead", description="new",
                                     industry="IT", skillset=["Rust"], experience="5+", salary=9000.0,
                                     location="Berlin")).reports);
    assert u["message"] == "Job details have been updated";
    g = first((root spawn get_job(job_id=jid_edit)).reports);
    assert g["title"] == "Edited " + tag and g["role"] == "lead" and g["salary"] == 9000.0 and g["location"] == "Berlin";
    assert len(jobs_titled("Edited " + tag)) == 1 and len(jobs_titled("Edit " + tag)) == 0;
    nope = first((root spawn update_job(job_id="0" * 24, title="t", role="r", description="d", industry="i",
                                        skillset=[], experience="e", salary=1.0, location="l")).reports);
    assert nope["error"] == "Job don't exist";
    d = first((root spawn delete_job(job_id=jid_edit)).reports);
    assert d["message"] == "Job Post deleted";
    assert first((root spawn get_job(job_id=jid_edit)).reports)["error"] == "Job does not exist";
    assert first((root spawn get_job(job_id=jid_keep)).reports)["title"] == "Keep " + tag;
    assert first((root spawn delete_job(job_id=jid_edit)).reports)["error"] == "Job does not exist!";
}
