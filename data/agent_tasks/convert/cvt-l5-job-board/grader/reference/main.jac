"""Job board API (port of roshan-rm01/Google-BGN, organisation + job routes).

ODMantic `Organisation` -> `Organisation` node on root; the embedded
`OrganisationData` -> an `obj`; `Job` -> `Job` node hung off the organisation
that posted it via a typed `Posted` edge. Route handlers -> public walkers named
after the handlers. JWT sessions are dropped: the organisation is identified by
its `email` argument. HTTPException -> reported {"error": detail}.
"""
import hashlib;

def hash_pw(pw: str) -> str {
    return hashlib.sha256(pw.encode()).hexdigest();
}

obj OrganisationData {
    has location: str;
    has companyBio: str;
    has industry: str;
    has telephone: str;
    has companySize: str | None = None;
    has name: str | None = None;

    def view -> dict[str, any] {
        return {"name": self.name, "location": self.location, "companyBio": self.companyBio,
                "industry": self.industry, "telephone": self.telephone, "companySize": self.companySize};
    }
}

node Organisation {
    has companyName: str;
    has email: str;
    has password: str;
    has data: OrganisationData | None = None;
}

node Job {
    has title: str;
    has role: str;
    has description: str;
    has industry: str;
    has skillset: list[str];
    has company: OrganisationData;
    has experience: str;
    has salary: float;
    has location: str;

    def view -> dict[str, any] {
        return {"id": jid(self), "title": self.title, "role": self.role, "description": self.description,
                "industry": self.industry, "skillset": list(self.skillset), "company": self.company.view(),
                "experience": self.experience, "salary": self.salary, "location": self.location};
    }
}

edge Posted: Organisation --> Job {}

def find_org(email: str) -> Organisation | None {
    for o in [root -->[?:Organisation]] {
        if o.email == email {
            return o;
        }
    }
    return None;
}

def all_jobs -> list[Job] {
    jobs: list[Job] = [];
    for o in [root -->[?:Organisation]] {
        jobs.extend([o ->:Posted:->]);
    }
    return jobs;
}

def find_job(job_id: str) -> Job | None {
    for j in all_jobs() {
        if jid(j) == job_id {
            return j;
        }
    }
    return None;
}

"""GET /"""
walker:pub welcome_page {
    can greet with Root entry {
        report {"message": "Welcome to the BGN task everyone."};
    }
}

"""POST /org/sign-up"""
walker:pub sign_org_up {
    has companyName: str;
    has email: str;
    has password: str;

    can signup with Root entry {
        if find_org(self.email) {
            report {"error": "Organisation with email exist already!"};
            return;
        }
        here ++> Organisation(companyName=self.companyName, email=self.email, password=hash_pw(self.password));
        report {"action": "Sign Up", "message": f"New org registered with email {self.email}"};
    }
}

"""POST /org/sign-in"""
walker:pub sign_org_in {
    has email: str;
    has password: str;

    can signin with Root entry {
        org = find_org(self.email);
        if org is None {
            report {"error": "Incorrect Details"};
        } elif org.password == hash_pw(self.password) {
            report {"action": "Sign In", "message": "Sign In Successful"};
        } else {
            report {"error": "Invalid Operation"};
        }
    }
}

"""POST /org/sign-out"""
walker:pub sign_org_out {
    can signout with Root entry {
        report {"action": "Sign Out", "message": "You have successfully signed out."};
    }
}

"""POST /org/org-details"""
walker:pub insert_org_data {
    has email: str;
    has location: str;
    has companyBio: str;
    has industry: str;
    has telephone: str;
    has companySize: str | None = None;
    has name: str | None = None;

    can save with Root entry {
        org = find_org(self.email);
        if org is None {
            report {"error": "Operation not found."};
            return;
        }
        org.data = OrganisationData(location=self.location, companyBio=self.companyBio, industry=self.industry,
                                    telephone=self.telephone, companySize=self.companySize, name=self.name);
        report {"action": "Organisation Details Upload", "message": "Organisation's data saved successfully."};
    }
}

"""GET /org/profile"""
walker:pub get_org_data {
    has email: str;

    can profile with Root entry {
        org = find_org(self.email);
        if org is None {
            report {"error": "Operation not found."};
        } else {
            report org.data.view() if org.data else {};
        }
    }
}

"""POST /job/ -- union of per-filter matches, in this filter order (duplicates kept)."""
walker:pub get_jobs {
    has location: str | None = None;
    has industry: str | None = None;
    has skillset: list[str] | None = None;
    has role: str | None = None;
    has title: str | None = None;
    has company: str | None = None;

    can search with Root entry {
        jobs = all_jobs();
        if all(v is None for v in [self.location, self.industry, self.skillset, self.role, self.title, self.company]) {
            report [j.view() for j in jobs];
            return;
        }
        found: list[Job] = [];
        if self.company { found.extend([j for j in jobs if j.company.name == self.company]); }
        if self.skillset { found.extend([j for j in jobs if list(j.skillset) == list(self.skillset)]); }
        if self.role { found.extend([j for j in jobs if j.role == self.role]); }
        if self.title { found.extend([j for j in jobs if j.title == self.title]); }
        if self.industry { found.extend([j for j in jobs if j.industry == self.industry]); }
        if self.location { found.extend([j for j in jobs if j.location == self.location]); }
        report [j.view() for j in found];
    }
}

"""POST /job/create/ -- the job's company name is the posting organisation's."""
walker:pub create_job {
    has email: str;
    has title: str;
    has role: str;
    has description: str;
    has industry: str;
    has skillset: list[str];
    has company: dict[str, str];
    has experience: str;
    has salary: float;
    has location: str;

    can post with Root entry {
        org = find_org(self.email);
        if org is None {
            report {"error": "Operation not found."};
            return;
        }
        c = self.company;
        info = OrganisationData(location=c.get("location", ""), companyBio=c.get("companyBio", ""),
                                industry=c.get("industry", ""), telephone=c.get("telephone", ""),
                                companySize=c.get("companySize"), name=org.companyName);
        org +>:Posted:+> Job(title=self.title, role=self.role, description=self.description,
                             industry=self.industry, skillset=self.skillset, company=info,
                             experience=self.experience, salary=self.salary, location=self.location);
        report {"action": "Job Created", "message": "Job Post created"};
    }
}

"""GET /job/get/{job_id}/"""
walker:pub get_job {
    has job_id: str;

    can fetch with Root entry {
        j = find_job(self.job_id);
        report j.view() if j else {"error": "Job does not exist"};
    }
}

"""PUT /job/update/{job_id}/ -- replace the job's details."""
walker:pub update_job {
    has job_id: str;
    has title: str;
    has role: str;
    has description: str;
    has industry: str;
    has skillset: list[str];
    has experience: str;
    has salary: float;
    has location: str;

    can edit with Root entry {
        j = find_job(self.job_id);
        if j is None {
            report {"error": "Job don't exist"};
            return;
        }
        j.title = self.title;
        j.role = self.role;
        j.description = self.description;
        j.industry = self.industry;
        j.skillset = self.skillset;
        j.experience = self.experience;
        j.salary = self.salary;
        j.location = self.location;
        report {"action": "Job Update", "message": "Job details have been updated"};
    }
}

"""DELETE /job/delete/{job_id}/"""
walker:pub delete_job {
    has job_id: str;

    can remove with Root entry {
        j = find_job(self.job_id);
        if j is None {
            report {"error": "Job does not exist!"};
            return;
        }
        del j;
        report {"action": "Job Delete", "message": "Job Post deleted"};
    }
}
