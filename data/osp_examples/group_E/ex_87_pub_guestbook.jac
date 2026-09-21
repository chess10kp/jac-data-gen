"""Public walkers as REST endpoints: a guestbook anyone can sign.

With `jac start`, walker `has` fields become the JSON request body and
each report lands in the response; the entry block seeds data for
standalone runs.
"""

node Entry {
    has name: str;
    has message: str;
}

walker:pub sign_guestbook {
    has name: str;
    has message: str;

    can sign with Root entry {
        # `has` fields (name, message) are the request body over HTTP.
        stamp = here ++> Entry(name=self.name, message=self.message);
        report {"signed": jid(stamp), "name": stamp.name};  # response body
    }
}

walker:pub read_guestbook {
    has limit: int = 10;

    can read with Root entry {
        entries = [e for e in [-->][?:Entry]][-self.limit:];
        report [{"from": e.name, "msg": e.message} for e in entries];
    }
}

with entry {
    root spawn sign_guestbook(name="Ada", message="Can't wait!");
    root spawn sign_guestbook(name="Grace", message="Bringing snacks.");
    result = root spawn read_guestbook();
    print(result.reports);
}
