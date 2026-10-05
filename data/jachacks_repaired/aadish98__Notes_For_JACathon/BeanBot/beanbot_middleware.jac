# jac-scale: walkers prefixed with `_` run as request middleware (see jac-scale docs).
import from db { prime_request_auth_from_jac_headers }

walker _prime_beanbot_auth {
    has headers: dict;

    can prime with Root entry {
        err = prime_request_auth_from_jac_headers(self.headers);
        if err is not None and str(err) != "" {
            report {"type": "error", "text": str(err)};
            disengage;
        }
        report {"type": "ok", "text": ""};
    }
}
