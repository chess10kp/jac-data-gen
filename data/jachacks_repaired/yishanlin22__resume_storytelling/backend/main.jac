"""ResumePrep AI — JAC backend (jac-cloud 0.2.11 / jaclang 0.9.0).

Graph layout per user (each user has their own root):
  root --> Resume   (one per uploaded version)
  root --> Experience
           Experience --> Story  (BQ stories)
"""

import from byllm.lib { Model }
import from resume_utils { parse_resume_file, generate_resume_docx }
import from jac_cloud.jaseci.models { User as BaseUser, NO_PASSWORD }
import datetime;
import json;
import uuid;

glob llm = Model(model_name="claude-sonnet-4-20250514");

# ---------------------------------------------------------------------------
# User model (required for jac-cloud auth)
# ---------------------------------------------------------------------------

class User(BaseUser) {
    has name: str = "";

    class Collection(BaseUser.Collection) {
        ::py::
        @classmethod
        def __document__(cls, doc):
            return User(
                id=doc.pop("_id"),
                email=doc.pop("email"),
                password=doc.pop("password", None) or NO_PASSWORD,
                root_id=doc.pop("root_id"),
                **doc,
            )
        ::py::
    }
}

# ---------------------------------------------------------------------------
# LLM-powered types  (all fields must be typed — byllm requires it)
# ---------------------------------------------------------------------------

obj ContactInfo {
    has email: str;
    has phone: str;
    has linkedin: str;
    has github: str;
    has location: str;
}

obj ExperienceEntry {
    has company: str;
    has role: str;
    has dates: str;
    has location: str;
    has bullets: list[str];
}

sem ExperienceEntry.bullets = "List of resume bullet points for this role";

obj EducationEntry {
    has institution: str;
    has degree: str;
    has dates: str;
    has gpa: str;
}

sem EducationEntry.gpa = "GPA string, e.g. '3.8/4.0', or empty string if not listed";

obj ProjectEntry {
    has name: str;
    has dates: str;
    has bullets: list[str];
    has technologies: list[str];
}

sem ProjectEntry.technologies = "List of technologies/tools used in this project";

obj ResumeStructured {
    has name: str;
    has contact: ContactInfo;
    has summary: str;
    has experience: list[ExperienceEntry];
    has education: list[EducationEntry];
    has skills: list[str];
    has projects: list[ProjectEntry];
    has certifications: list[str];
}

sem ResumeStructured.skills = "All skills, tools, languages, and frameworks extracted from the resume";
sem ResumeStructured.certifications = "List of certifications or awards, empty list if none";

"""Parse raw resume text into a structured resume object."""
def parse_resume_with_llm(raw_text: str) -> ResumeStructured by llm();

"""Rewrite a single bullet point to be shorter, fitting in one line (~80-100 chars). Keep key achievement and metrics."""
def shorten_bullet(bullet: str) -> str by llm();

"""Rewrite a single bullet point to be longer and more detailed. Add context, tools used, and impact. Target 1.5-2x length."""
def lengthen_bullet(bullet: str) -> str by llm();

"""
Tailor a list of resume bullet points to better match the job description.
Use JD keywords naturally, emphasize relevant experience, quantify where possible.
Return same number of bullets, rewritten.
"""
def tailor_bullets(bullets: list[str], job_description: str, target_role: str) -> list[str] by llm();

"""
Add or rewrite a resume summary section targeting the given role and company.
3-4 sentences. No 'I'. Professional tone.
"""
def generate_summary(structured_resume: str, target_role: str, company: str) -> str by llm();

"""
Strengthen bullet points by adding or improving quantitative metrics.
Return same number of bullets.
"""
def quantify_bullets(bullets: list[str]) -> list[str] by llm();

obj SkillMatchResult {
    has matched: list[str];
    has partial: list[str];
    has missing_key: list[str];
    has score: int;
}

sem SkillMatchResult.matched = "Resume skills that clearly satisfy a JD requirement (semantic match, not just keyword)";
sem SkillMatchResult.partial = "Resume skills that are related or adjacent to JD requirements";
sem SkillMatchResult.missing_key = "Important JD skills the resume lacks entirely";
sem SkillMatchResult.score = "Overall match score 0-100. Be generous — if the candidate knows any one of a group of similar tools listed in the JD, count it as matched";

"""
Compare resume skills against the job description using semantic matching (not just keyword overlap).
Many JDs list many tools where knowing one from the group is sufficient.
Be generous: if the candidate has Python and the JD lists Python/R/MATLAB, count it as matched.
"""
def match_skills(resume_skills: list[str], job_description: str) -> SkillMatchResult by llm();

"""
Generate a professional cover letter.
tone_notes: user guidance on tone or things to emphasize.
talking_points: specific experiences or skills to highlight.
"""
def generate_cover_letter(
    candidate_name: str,
    target_role: str,
    company: str,
    company_info: str,
    talking_points: list[str],
    tone_notes: str,
    resume_summary: str
) -> str by llm();

# ---------------------------------------------------------------------------
# BQ Story types
# ---------------------------------------------------------------------------

obj BQStoryStructure {
    has situation: str;
    has task: str;
    has action: str;
    has result: str;
    has themes: list[str];
    has follow_up_questions: list[str];
}

sem BQStoryStructure.themes = "List of BQ topics this story covers. Include relevant Amazon Leadership Principles (Customer Obsession, Ownership, Invent and Simplify, Are Right A Lot, Learn and Be Curious, Hire and Develop the Best, Insist on Highest Standards, Think Big, Bias for Action, Frugality, Earn Trust, Dive Deep, Have Backbone Disagree and Commit, Deliver Results) and general behavioral themes (Leadership, Teamwork, Conflict Resolution, Failure/Learning, Time Management, Communication, Innovation, Handling Feedback, Biggest Weakness, Initiative)";
sem BQStoryStructure.follow_up_questions = "List of 3-5 likely interviewer follow-up questions for this story";

"""
Build a complete STAR-format BQ story from an experience and a brief situation seed.
Identify all Amazon Leadership Principles and general behavioral themes this story covers.
themes_hint: user-suggested themes to target.
"""
def build_bq_story(
    experience_context: str,
    story_seed: str,
    themes_hint: list[str]
) -> BQStoryStructure by llm();

obj StoryRecommendation {
    has story_index: int;
    has reason: str;
    has key_points_to_emphasize: list[str];
}

sem StoryRecommendation.story_index = "0-based index into the story_summaries list";
sem StoryRecommendation.key_points_to_emphasize = "2-4 specific points from the story to highlight when answering this question";

"""
Given a BQ interview question and a list of story summaries, recommend the best story to use.
Pick the story whose STAR structure best demonstrates the competency asked about.
"""
def recommend_story_for_question(question: str, story_summaries: list[str]) -> StoryRecommendation by llm();

"""
Suggest 3-5 follow-up questions to ask the user to enrich a story with more concrete detail.
"""
def suggest_story_questions(story_seed: str, experience_context: str) -> list[str] by llm();

# ---------------------------------------------------------------------------
# Graph nodes
# ---------------------------------------------------------------------------

node Resume {
    has resume_id: str;
    has version_name: str;
    has label: str;
    has file_name: str;
    has raw_text: str;
    has parsed_data: str;
    has created_at: str;
    has updated_at: str;
    has section_order: str = ""; # JSON list — empty means auto-derive from parsed_data
}

node Experience {
    has exp_id: str;
    has company: str;
    has role: str;
    has dates: str;
    has location: str;
    has bullets: str;       # JSON list
    has description: str;
    has created_at: str;
}

node Story {
    has story_id: str;
    has exp_id: str;
    has title: str;
    has star_data: str;     # JSON of BQStoryStructure
    has user_notes: str;
    has created_at: str;
    has updated_at: str;
}

# ---------------------------------------------------------------------------
# Resume walkers
# ---------------------------------------------------------------------------

walker UploadResume {
    """Upload a resume (base64 file or pasted plain text), parse with LLM, and store."""
    has file_name: str = "resume.txt";
    has file_data: str = "";       # base64-encoded bytes
    has plain_text: str = "";      # alternative: paste raw text
    has version_name: str = "My Resume";
    has label: str = "general";

    can upload with Root entry {
        raw = "";
        if self.file_data {
            raw = parse_resume_file(self.file_name, self.file_data);
        } elif self.plain_text {
            raw = self.plain_text;
        }

        if not raw {
            report {"error": "No content provided. Supply file_data or plain_text."};
            disengage;
        }

        structured = parse_resume_with_llm(raw);

        # Serialize nested typed objects to plain dicts for JSON storage
        contact_dict = {
            "email": structured.contact.email,
            "phone": structured.contact.phone,
            "linkedin": structured.contact.linkedin,
            "github": structured.contact.github,
            "location": structured.contact.location
        };
        experience_list = [
            {"company": e.company, "role": e.role, "dates": e.dates,
             "location": e.location, "bullets": e.bullets}
            for e in structured.experience
        ];
        education_list = [
            {"institution": e.institution, "degree": e.degree,
             "dates": e.dates, "gpa": e.gpa}
            for e in structured.education
        ];
        projects_list = [
            {"name": p.name, "dates": p.dates, "bullets": p.bullets,
             "technologies": p.technologies}
            for p in structured.projects
        ];

        parsed_json = json.dumps({
            "name": structured.name,
            "contact": contact_dict,
            "summary": structured.summary,
            "experience": experience_list,
            "education": education_list,
            "skills": structured.skills,
            "projects": projects_list,
            "certifications": structured.certifications
        });

        now = datetime.datetime.utcnow().isoformat();
        rid = str(uuid.uuid4());

        # Build default section order from whichever sections are non-empty
        parsed_preview = json.loads(parsed_json);
        default_order = [];
        if parsed_preview.get("summary") { default_order.append("summary"); }
        if parsed_preview.get("experience") { default_order.append("experience"); }
        if parsed_preview.get("projects") { default_order.append("projects"); }
        if parsed_preview.get("education") { default_order.append("education"); }
        if parsed_preview.get("skills") { default_order.append("skills"); }
        if parsed_preview.get("certifications") { default_order.append("certifications"); }
        # Always include contact (shown in header)
        section_order_json = json.dumps(default_order);

        resume = Resume(
            resume_id=rid,
            version_name=self.version_name,
            label=self.label,
            file_name=self.file_name,
            raw_text=raw,
            parsed_data=parsed_json,
            section_order=section_order_json,
            created_at=now,
            updated_at=now
        );
        here ++> resume;

        report {
            "resume_id": rid,
            "version_name": self.version_name,
            "label": self.label,
            "parsed": parsed_preview,
            "section_order": default_order
        };
    }
}

walker ListResumes {
    """Return all resume versions for the logged-in user."""
    can list_all with Root entry {
        resumes = [-->[?:Resume]];
        result = [];
        for r in resumes {
            result.append({
                "resume_id": r.resume_id,
                "version_name": r.version_name,
                "label": r.label,
                "file_name": r.file_name,
                "created_at": r.created_at,
                "updated_at": r.updated_at,
                "name": json.loads(r.parsed_data).get("name", "")
            });
        }
        report result;
    }
}

walker GetResume {
    """Return full resume data including parsed structure."""
    has resume_id: str;

    can get with Root entry {
        resumes = [-->[?:Resume]];
        for r in resumes {
            if r.resume_id == self.resume_id {
                report {
                    "resume_id": r.resume_id,
                    "version_name": r.version_name,
                    "label": r.label,
                    "file_name": r.file_name,
                    "raw_text": r.raw_text,
                    "parsed": json.loads(r.parsed_data),
                    "section_order": json.loads(r.section_order) if r.section_order else [],
                    "created_at": r.created_at,
                    "updated_at": r.updated_at
                };
                disengage;
            }
        }
        report {"error": "Resume not found"};
    }
}

walker DeleteResume {
    """Delete a resume version."""
    has resume_id: str;

    can remove with Root entry {
        resumes = [-->[?:Resume]];
        for r in resumes {
            if r.resume_id == self.resume_id {
                destroy(r);
                report {"deleted": self.resume_id};
                disengage;
            }
        }
        report {"error": "Resume not found"};
    }
}

walker UpdateResumeVersion {
    """Rename a resume version or change its label."""
    has resume_id: str;
    has version_name: str = "";
    has label: str = "";

    can update with Root entry {
        resumes = [-->[?:Resume]];
        for r in resumes {
            if r.resume_id == self.resume_id {
                if self.version_name { r.version_name = self.version_name; }
                if self.label { r.label = self.label; }
                r.updated_at = datetime.datetime.utcnow().isoformat();
                report {"resume_id": r.resume_id, "version_name": r.version_name, "label": r.label};
                disengage;
            }
        }
        report {"error": "Resume not found"};
    }
}

# ---------------------------------------------------------------------------
# Tailoring walkers
# ---------------------------------------------------------------------------

walker AdjustBullet {
    """Shorten or lengthen a single bullet point via LLM."""
    has bullet: str;
    has direction: str;    # "shorten" | "lengthen"

    can adjust with Root entry {
        if self.direction == "shorten" {
            result = shorten_bullet(self.bullet);
        } else {
            result = lengthen_bullet(self.bullet);
        }
        report {"bullet": result};
    }
}

walker TailorResume {
    """
    Tailor resume bullets to match a job description.
    Returns modified parsed data without saving — frontend shows diff then user saves.
    """
    has resume_id: str;
    has job_description: str;
    has target_role: str = "";
    has company: str = "";
    has add_summary: bool = False;
    has quantify: bool = False;
    has keyword_optimize: bool = True;

    can tailor with Root entry {
        resumes = [-->[?:Resume]];
        for r in resumes {
            if r.resume_id == self.resume_id {
                parsed = json.loads(r.parsed_data);

                for exp in parsed.get("experience", []) {
                    if exp.get("bullets") {
                        bullets = exp["bullets"];
                        if self.keyword_optimize {
                            bullets = tailor_bullets(bullets, self.job_description, self.target_role);
                        }
                        if self.quantify {
                            bullets = quantify_bullets(bullets);
                        }
                        exp["bullets"] = bullets;
                    }
                }
                for proj in parsed.get("projects", []) {
                    if proj.get("bullets") {
                        bullets = proj["bullets"];
                        if self.keyword_optimize {
                            bullets = tailor_bullets(bullets, self.job_description, self.target_role);
                        }
                        if self.quantify {
                            bullets = quantify_bullets(bullets);
                        }
                        proj["bullets"] = bullets;
                    }
                }

                if self.add_summary {
                    parsed["summary"] = generate_summary(
                        json.dumps(parsed),
                        self.target_role,
                        self.company
                    );
                }

                report {
                    "resume_id": self.resume_id,
                    "tailored_parsed": parsed
                };
                disengage;
            }
        }
        report {"error": "Resume not found"};
    }
}

walker SaveTailoredResume {
    """Save tailored resume data back, either overwriting or as a new version."""
    has resume_id: str;
    has tailored_parsed: dict;
    has save_as_new: bool = False;
    has new_version_name: str = "";

    can save with Root entry {
        resumes = [-->[?:Resume]];
        for r in resumes {
            if r.resume_id == self.resume_id {
                now = datetime.datetime.utcnow().isoformat();
                if self.save_as_new {
                    rid = str(uuid.uuid4());
                    new_r = Resume(
                        resume_id=rid,
                        version_name=self.new_version_name or (r.version_name + " (Tailored)"),
                        label=r.label,
                        file_name=r.file_name,
                        raw_text=r.raw_text,
                        parsed_data=json.dumps(self.tailored_parsed),
                        created_at=now,
                        updated_at=now
                    );
                    here ++> new_r;
                    report {"resume_id": rid, "saved_as_new": True};
                } else {
                    r.parsed_data = json.dumps(self.tailored_parsed);
                    r.updated_at = now;
                    report {"resume_id": self.resume_id, "saved_as_new": False};
                }
                disengage;
            }
        }
        report {"error": "Resume not found"};
    }
}

walker MatchSkills {
    """Semantic skill matching between resume and job description."""
    has resume_id: str;
    has job_description: str;

    can `match with Root entry {
        resumes = [-->[?:Resume]];
        for r in resumes {
            if r.resume_id == self.resume_id {
                parsed = json.loads(r.parsed_data);
                skills = parsed.get("skills", []);
                result = match_skills(skills, self.job_description);
                report {
                    "matched": result.matched,
                    "partial": result.partial,
                    "missing_key": result.missing_key,
                    "score": result.score
                };
                disengage;
            }
        }
        report {"error": "Resume not found"};
    }
}

# ---------------------------------------------------------------------------
# Experience & BQ story walkers
# ---------------------------------------------------------------------------

walker AddExperience {
    """Add a work/project experience for BQ story prep."""
    has company: str;
    has role: str;
    has dates: str = "";
    has location: str = "";
    has bullets: list = [];
    has description: str = "";

    can add with Root entry {
        now = datetime.datetime.utcnow().isoformat();
        eid = str(uuid.uuid4());
        exp = Experience(
            exp_id=eid,
            company=self.company,
            role=self.role,
            dates=self.dates,
            location=self.location,
            bullets=json.dumps(self.bullets),
            description=self.description,
            created_at=now
        );
        here ++> exp;
        report {"exp_id": eid, "company": self.company, "role": self.role};
    }
}

walker ListExperiences {
    can list_all with Root entry {
        exps = [-->[?:Experience]];
        result = [];
        for e in exps {
            stories = [e-->[?:Story]];
            story_count = len(stories);
            result.append({
                "exp_id": e.exp_id,
                "company": e.company,
                "role": e.role,
                "dates": e.dates,
                "location": e.location,
                "bullets": json.loads(e.bullets),
                "description": e.description,
                "story_count": story_count,
                "created_at": e.created_at
            });
        }
        report result;
    }
}

walker UpdateExperience {
    has exp_id: str;
    has company: str = "";
    has role: str = "";
    has dates: str = "";
    has location: str = "";
    has bullets: list = [];
    has description: str = "";

    can update with Root entry {
        exps = [-->[?:Experience]];
        for e in exps {
            if e.exp_id == self.exp_id {
                if self.company { e.company = self.company; }
                if self.role { e.role = self.role; }
                if self.dates { e.dates = self.dates; }
                if self.location { e.location = self.location; }
                if self.bullets { e.bullets = json.dumps(self.bullets); }
                if self.description { e.description = self.description; }
                report {"exp_id": e.exp_id, "updated": True};
                disengage;
            }
        }
        report {"error": "Experience not found"};
    }
}

walker DeleteExperience {
    has exp_id: str;

    can remove with Root entry {
        exps = [-->[?:Experience]];
        for e in exps {
            if e.exp_id == self.exp_id {
                destroy(e);
                report {"deleted": self.exp_id};
                disengage;
            }
        }
        report {"error": "Experience not found"};
    }
}

walker ImportExperiencesFromResume {
    """Pull all experience entries from a parsed resume into the Experience graph."""
    has resume_id: str;

    can import_exp with Root entry {
        resumes = [-->[?:Resume]];
        for r in resumes {
            if r.resume_id == self.resume_id {
                parsed = json.loads(r.parsed_data);
                created = [];
                now = datetime.datetime.utcnow().isoformat();
                for exp_data in parsed.get("experience", []) {
                    eid = str(uuid.uuid4());
                    exp = Experience(
                        exp_id=eid,
                        company=exp_data.get("company", ""),
                        role=exp_data.get("role", ""),
                        dates=exp_data.get("dates", ""),
                        location=exp_data.get("location", ""),
                        bullets=json.dumps(exp_data.get("bullets", [])),
                        description="",
                        created_at=now
                    );
                    here ++> exp;
                    created.append({"exp_id": eid, "company": exp_data.get("company", ""), "role": exp_data.get("role", "")});
                }
                report {"imported": created};
                disengage;
            }
        }
        report {"error": "Resume not found"};
    }
}

walker BuildStory {
    """Build a STAR BQ story from an experience. story_seed is a brief description of the incident."""
    has exp_id: str;
    has story_seed: str;
    has title: str = "";
    has themes_hint: list = [];
    has user_notes: str = "";

    can build with Root entry {
        exps = [-->[?:Experience]];
        for e in exps {
            if e.exp_id == self.exp_id {
                context = f"Company: {e.company} | Role: {e.role} | Dates: {e.dates}\nBullets: {e.bullets}\nExtra context: {e.description}";
                star = build_bq_story(context, self.story_seed, self.themes_hint);

                now = datetime.datetime.utcnow().isoformat();
                sid = str(uuid.uuid4());
                star_dict = {
                    "situation": star.situation,
                    "task": star.task,
                    "action": star.action,
                    "result": star.result,
                    "themes": star.themes,
                    "follow_up_questions": star.follow_up_questions
                };
                story = Story(
                    story_id=sid,
                    exp_id=self.exp_id,
                    title=self.title or self.story_seed[:60],
                    star_data=json.dumps(star_dict),
                    user_notes=self.user_notes,
                    created_at=now,
                    updated_at=now
                );
                e ++> story;

                report {
                    "story_id": sid,
                    "exp_id": self.exp_id,
                    "title": story.title,
                    "star": star_dict
                };
                disengage;
            }
        }
        report {"error": "Experience not found"};
    }
}

walker SuggestStoryQuestions {
    """Get LLM-suggested questions to flesh out a story with more detail."""
    has exp_id: str;
    has story_seed: str;

    can suggest with Root entry {
        exps = [-->[?:Experience]];
        for e in exps {
            if e.exp_id == self.exp_id {
                context = f"Company: {e.company} | Role: {e.role}\nContext: {e.description}";
                questions = suggest_story_questions(self.story_seed, context);
                report {"questions": questions};
                disengage;
            }
        }
        report {"error": "Experience not found"};
    }
}

walker ListStories {
    """List all BQ stories, optionally filtered by exp_id."""
    has exp_id: str = "";

    can collect with Root entry {
        exps = [-->[?:Experience]];
        result = [];
        for e in exps {
            if self.exp_id and e.exp_id != self.exp_id {
                continue;
            }
            stories = [e-->[?:Story]];
            for s in stories {
                star = json.loads(s.star_data);
                result.append({
                    "story_id": s.story_id,
                    "exp_id": s.exp_id,
                    "exp_company": e.company,
                    "exp_role": e.role,
                    "title": s.title,
                    "themes": star.get("themes", []),
                    "situation": star.get("situation", ""),
                    "user_notes": s.user_notes,
                    "created_at": s.created_at
                });
            }
        }
        report result;
    }
}

walker GetStory {
    has story_id: str;

    can find with Root entry {
        exps = [-->[?:Experience]];
        for e in exps {
            stories = [e-->[?:Story]];
            for s in stories {
                if s.story_id == self.story_id {
                    report {
                        "story_id": s.story_id,
                        "exp_id": s.exp_id,
                        "title": s.title,
                        "star": json.loads(s.star_data),
                        "user_notes": s.user_notes,
                        "created_at": s.created_at,
                        "updated_at": s.updated_at
                    };
                    disengage;
                }
            }
        }
        report {"error": "Story not found"};
    }
}

walker UpdateStory {
    has story_id: str;
    has title: str = "";
    has user_notes: str = "";

    can update with Root entry {
        exps = [-->[?:Experience]];
        for e in exps {
            stories = [e-->[?:Story]];
            for s in stories {
                if s.story_id == self.story_id {
                    if self.title { s.title = self.title; }
                    if self.user_notes { s.user_notes = self.user_notes; }
                    s.updated_at = datetime.datetime.utcnow().isoformat();
                    report {"story_id": s.story_id, "updated": True};
                    disengage;
                }
            }
        }
        report {"error": "Story not found"};
    }
}

walker DeleteStory {
    has story_id: str;

    can remove with Root entry {
        exps = [-->[?:Experience]];
        for e in exps {
            stories = [e-->[?:Story]];
            for s in stories {
                if s.story_id == self.story_id {
                    destroy(s);
                    report {"deleted": self.story_id};
                    disengage;
                }
            }
        }
        report {"error": "Story not found"};
    }
}

walker RecommendStory {
    """Given a BQ interview question, recommend the best prepared story to use."""
    has question: str;

    can recommend with Root entry {
        all_stories = [];
        exps = [-->[?:Experience]];
        for e in exps {
            stories = [e-->[?:Story]];
            for s in stories {
                star = json.loads(s.star_data);
                all_stories.append({
                    "story_id": s.story_id,
                    "title": s.title,
                    "summary": f"S: {star.get('situation','')[:120]} A: {star.get('action','')[:120]} R: {star.get('result','')[:80]}"
                });
            }
        }
        if not all_stories {
            report {"error": "No stories prepared yet"};
            disengage;
        }
        summaries = [s["summary"] for s in all_stories];
        rec = recommend_story_for_question(self.question, summaries);
        idx = rec.story_index if rec.story_index < len(all_stories) else 0;
        report {
            "story_id": all_stories[idx]["story_id"],
            "story_title": all_stories[idx]["title"],
            "reason": rec.reason,
            "key_points_to_emphasize": rec.key_points_to_emphasize
        };
    }
}

# ---------------------------------------------------------------------------
# Cover letter walker
# ---------------------------------------------------------------------------

walker GenerateCoverLetter {
    has resume_id: str;
    has target_role: str;
    has company: str;
    has company_info: str = "";
    has talking_points: list = [];
    has tone_notes: str = "";

    can generate with Root entry {
        resumes = [-->[?:Resume]];
        for r in resumes {
            if r.resume_id == self.resume_id {
                parsed = json.loads(r.parsed_data);
                letter = generate_cover_letter(
                    parsed.get("name", ""),
                    self.target_role,
                    self.company,
                    self.company_info,
                    self.talking_points,
                    self.tone_notes,
                    parsed.get("summary", "")
                );
                report {"cover_letter": letter};
                disengage;
            }
        }
        report {"error": "Resume not found"};
    }
}

# ---------------------------------------------------------------------------
# Section & item reordering walkers
# ---------------------------------------------------------------------------

walker MoveSectionItem {
    """Move an entry up or down within a resume section (experience, projects, education, etc.)."""
    has resume_id: str;
    has section: str;    # "experience" | "projects" | "education" | "certifications" | "skills"
    has index: int;
    has direction: str;  # "up" | "down"

    can move with Root entry {
        resumes = [-->[?:Resume]];
        for r in resumes {
            if r.resume_id == self.resume_id {
                parsed = json.loads(r.parsed_data);
                items = parsed.get(self.section, []);
                idx = self.index;
                if self.direction == "up" and idx > 0 {
                    tmp = items[idx - 1];
                    items[idx - 1] = items[idx];
                    items[idx] = tmp;
                } elif self.direction == "down" and idx < len(items) - 1 {
                    tmp = items[idx + 1];
                    items[idx + 1] = items[idx];
                    items[idx] = tmp;
                }
                parsed[self.section] = items;
                r.parsed_data = json.dumps(parsed);
                r.updated_at = datetime.datetime.utcnow().isoformat();
                report {"ok": True, "section": self.section, "index": idx, "direction": self.direction};
                disengage;
            }
        }
        report {"error": "Resume not found"};
    }
}

walker UpdateSectionOrder {
    """Persist a new top-level section display order for a resume."""
    has resume_id: str;
    has section_order: list[str];

    can update with Root entry {
        resumes = [-->[?:Resume]];
        for r in resumes {
            if r.resume_id == self.resume_id {
                r.section_order = json.dumps(self.section_order);
                r.updated_at = datetime.datetime.utcnow().isoformat();
                report {"section_order": self.section_order};
                disengage;
            }
        }
        report {"error": "Resume not found"};
    }
}

walker UpdateResumeParsed {
    """Save manually edited resume content back to the DB."""
    has resume_id: str;
    has parsed_data: dict;

    can update with Root entry {
        resumes = [-->[?:Resume]];
        for r in resumes {
            if r.resume_id == self.resume_id {
                r.parsed_data = json.dumps(self.parsed_data);
                r.updated_at = datetime.datetime.utcnow().isoformat();
                report {"resume_id": self.resume_id, "updated": True};
                disengage;
            }
        }
        report {"error": "Resume not found"};
    }
}

walker ExportResume {
    """Export a resume as a DOCX file. Returns base64-encoded file content."""
    has resume_id: str;

    can export with Root entry {
        resumes = [-->[?:Resume]];
        for r in resumes {
            if r.resume_id == self.resume_id {
                parsed = json.loads(r.parsed_data);
                file_data = generate_resume_docx(parsed);
                safe_name = r.version_name.replace("/", "-").replace("\\", "-");
                report {
                    "file_data": file_data,
                    "file_name": safe_name + ".docx",
                    "format": "docx"
                };
                disengage;
            }
        }
        report {"error": "Resume not found"};
    }
}
