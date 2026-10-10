#!/usr/bin/env python3
"""Hidden HTTP smoke for cvt-l5-job-board: org sign-up/in, profile, job posting, filtered
search, get/update/delete over `jac run --serve`."""
import os
import sys
import uuid

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from smoke_lib import check, is_error, items, ok_resp, run  # noqa: E402

CO = {"location": "USA", "companyBio": "Search company", "industry": "Technology",
      "telephone": "+447398346125", "companySize": "10,000+ Employees"}


def jobs(srv, **f):
    st, env = srv.call("/walker/get_jobs", f)
    check(ok_resp(st, env), f"get_jobs failed: {st} {env}")
    return [j for j in items(env) if isinstance(j, dict)]


def checks(srv):
    st, env, r = srv.walker("welcome_page")
    check(ok_resp(st, env) and (r or {}).get("message") == "Welcome to the BGN task everyone.", f"welcome: {env}")
    tag = uuid.uuid4().hex[:6]
    email = f"page{tag}@gmail.com"
    st, env, r = srv.walker("sign_org_up", companyName="Google " + tag, email=email, password="Strong+Password")
    check(ok_resp(st, env) and (r or {}).get("action") == "Sign Up", f"sign_org_up: {st} {env}")
    st, env, r = srv.walker("sign_org_up", companyName="Google " + tag, email=email, password="x")
    check(is_error(st, env), f"duplicate sign up should be an error: {st} {env}")
    st, env, r = srv.walker("sign_org_in", email=email, password="Strong+Password")
    check(ok_resp(st, env) and (r or {}).get("message") == "Sign In Successful", f"sign_org_in: {st} {env}")
    st, env, r = srv.walker("sign_org_in", email=email, password="bad")
    check(is_error(st, env), f"bad password should be an error: {st} {env}")
    st, env, r = srv.walker("insert_org_data", email=email, **CO)
    check(ok_resp(st, env), f"insert_org_data: {st} {env}")
    st, env, r = srv.walker("get_org_data", email=email)
    check(ok_resp(st, env) and (r or {}).get("companyBio") == "Search company", f"get_org_data: {st} {env}")
    for title, role in (("SWE " + tag, "Junior"), ("SRE " + tag, "Senior")):
        st, env, r = srv.walker("create_job", email=email, title=title, role=role, description="Backend work",
                                industry="Internet", skillset=["Go", "Python"], company=CO,
                                experience="0-2 years", salary=1500.0, location="Remote")
        check(ok_resp(st, env) and (r or {}).get("message") == "Job Post created", f"create_job: {st} {env}")
    mine = jobs(srv, company="Google " + tag)
    check([j.get("title") for j in mine] == ["SWE " + tag, "SRE " + tag], f"company filter: {mine}")
    dup = jobs(srv, company="Google " + tag, title="SRE " + tag)
    check(len(dup) == 3, f"union filter should keep duplicates: {dup}")
    jid = mine[0].get("id") if mine else ""
    st, env, r = srv.walker("update_job", job_id=jid, title="SWE II " + tag, role="Mid", description="x",
                            industry="Internet", skillset=["Go"], experience="2-4 years", salary=3000.0,
                            location="Remote")
    check(ok_resp(st, env), f"update_job: {st} {env}")
    st, env, r = srv.walker("get_job", job_id=jid)
    check(ok_resp(st, env) and (r or {}).get("title") == "SWE II " + tag and (r or {}).get("salary") == 3000.0,
          f"get_job after update: {st} {env}")
    st, env, r = srv.walker("delete_job", job_id=jid)
    check(ok_resp(st, env) and (r or {}).get("message") == "Job Post deleted", f"delete_job: {st} {env}")
    left = [j.get("title") for j in jobs(srv, company="Google " + tag)]
    check(left == ["SRE " + tag], f"after delete: {left}")
    st, env, r = srv.walker("get_job", job_id=jid)
    check(is_error(st, env), f"deleted job should be an error: {st} {env}")


if __name__ == "__main__":
    run(checks)
