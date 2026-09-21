"""Org-chart salary and headcount rollup.

Employees report to managers through ReportsTo edges (report -> manager).
A rollup walker descends from the CEO to every employee, and because exit
abilities are deferred until all descendants finish, each manager's exit
sees the completed subtree totals of every direct report -- a bottom-up
post-order aggregation without any explicit recursion.
"""

node Employee {
    has name: str;
    has salary: int;
    has rollup_salary: int = 0;
    has team_size: int = 0;
}

edge ReportsTo: Employee --> Employee {}

walker OrgRollup {
    has headcount: int = 0;

    can descend with Employee entry {
        self.headcount += 1;
        visit [<-:ReportsTo:<-];  # step down to direct reports
    }

    can tally with Employee exit {
        # Every subordinate below has already exited, so its rollup
        # fields are final and can be folded in here.
        total_salary = here.salary;
        total_people = 1;
        for `report in [<-:ReportsTo:<-] {
            total_salary += `report.rollup_salary;
            total_people += `report.team_size + 1;  # report + their subtree
        }
        here.rollup_salary = total_salary;
        here.team_size = total_people - 1;
    }
}

with entry {

    # Reset leftovers from any previous run of this demo.
    for stale_node in [root -->][?:Employee] {
        del stale_node;
    }
    ceo = Employee(name="Morgan (CEO)", salary=500);
    eng_vp = Employee(name="Lee (VP Eng)", salary=300);
    sales_vp = Employee(name="Pat (VP Sales)", salary=280);
    dev1 = Employee(name="Sasha (Dev)", salary=150);
    dev2 = Employee(name="Jamie (Dev)", salary=140);
    qa = Employee(name="Riley (QA)", salary=120);
    acct = Employee(name="Casey (Acct)", salary=110);

    dev1 +>: ReportsTo() :+> eng_vp;
    dev2 +>: ReportsTo() :+> eng_vp;
    qa +>: ReportsTo() :+> eng_vp;
    acct +>: ReportsTo() :+> sales_vp;
    eng_vp +>: ReportsTo() :+> ceo;
    sales_vp +>: ReportsTo() :+> ceo;

    result = ceo spawn OrgRollup();

    print(f"Org headcount: {result.headcount}");
    print(f"{'Employee':<20} {'Own':>5} {'TeamPay':>8} {'TeamSize':>9}");
    for emp in [ceo, eng_vp, sales_vp, dev1] {
        print(
            f"{emp.name:<20} {emp.salary:>5} "
            f"{emp.rollup_salary:>8} {emp.team_size:>9}"
        );
    }
    print(f"Total payroll (CEO subtree): {ceo.rollup_salary}");
}
