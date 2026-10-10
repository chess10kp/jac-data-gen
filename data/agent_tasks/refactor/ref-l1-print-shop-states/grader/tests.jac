import from print_jobs { PrintJob, start_job, finish_job, cancel_job, status_line, pages_outstanding }

test "new job is queued" {
    j = PrintJob(name="flyers", pages=40);
    assert status_line(j) == "flyers [queued]";
}

test "normal lifecycle" {
    j = PrintJob(name="posters", pages=5);
    assert start_job(j);
    assert status_line(j) == "posters [printing]";
    assert not start_job(j);
    assert finish_job(j);
    assert status_line(j) == "posters [done]";
    assert not finish_job(j);
    assert not cancel_job(j);
    assert status_line(j) == "posters [done]";
}

test "cannot finish a queued job" {
    j = PrintJob(name="cards", pages=2);
    assert not finish_job(j);
    assert status_line(j) == "cards [queued]";
}

test "cancel from queued and from printing" {
    a = PrintJob(name="a", pages=1);
    b = PrintJob(name="b", pages=1);
    assert cancel_job(a);
    start_job(b);
    assert cancel_job(b);
    assert status_line(a) == "a [cancelled]";
    assert status_line(b) == "b [cancelled]";
    assert not start_job(a);
    assert not cancel_job(a);
}

test "outstanding pages count queued and printing only" {
    q = PrintJob(name="q", pages=10);
    p = PrintJob(name="p", pages=7);
    d = PrintJob(name="d", pages=100);
    c = PrintJob(name="c", pages=1000);
    start_job(p);
    start_job(d);
    finish_job(d);
    cancel_job(c);
    assert pages_outstanding([q, p, d, c]) == 17;
    assert pages_outstanding([d, c]) == 0;
}
