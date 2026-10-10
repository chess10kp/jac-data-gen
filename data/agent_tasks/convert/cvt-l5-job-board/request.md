Our hackathon job-board backend is FastAPI + ODMantic (Mongo), in `python/backend/` — organisation/job models in `models/organisation/model.py`, handlers in `routes/organisation/org_routes.py` (org accounts) and `routes/organisation/route.py` (jobs), plus the welcome route in `routes/router.py`. The applicant side has already been cut. Port what's there to a Jac service in `main.jac` (entry point already set in `jac.toml`).

Data model: `Organisation` nodes on root, the embedded `OrganisationData` as a Jac `obj` (an org's optional `data`, and each job's `company`), and `Job` nodes attached to the organisation that posted them through a `Posted` edge.

One public walker per handler, same names:
`welcome_page`, `sign_org_up(companyName, email, password)`, `sign_org_in(email, password)`, `sign_org_out`, `insert_org_data(email, location, companyBio, industry, telephone, companySize=None, name=None)`, `get_org_data(email)` (report `{}` if no details saved yet), `get_jobs(location, industry, skillset, role, title, company — all optional)`, `create_job(email, title, role, description, industry, skillset, company, experience, salary, location)` where `company` is the OrganisationData dict, `get_job(job_id)`, `update_job(job_id, title, role, description, industry, skillset, experience, salary, location)`, `delete_job(job_id)`.

Notes:
- Drop the JWT cookies: whatever used the session now takes the organisation's `email` argument, and don't return tokens. Passwords must not be stored in plain text (any one-way hash; bcrypt isn't available) and sign-in has to check them.
- Keep the response dicts (`action`/`message`) and use `{"error": "<detail>"}` wherever the Python raises an HTTPException, with the same detail text.
- `get_jobs` must behave like the Python: no filters → all jobs; otherwise concatenate the matches of each given filter in the order company, skillset, role, title, industry, location (a job matching two filters shows up twice). Skip the salary filter. A posted job's `company.name` is always the posting org's `companyName`.
- `update_job` should just overwrite that job's fields (the Python accidentally saves a new document).
- Jobs are reported as dicts with an `id` (the node's jid) plus all fields, `company` as a dict.

It must start with `jac start main.jac` and pass `jac check`.
