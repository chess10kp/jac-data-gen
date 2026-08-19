# notify_service.jac (provider)
walker:pub Greet {
    has name: str;
    can greet with Root entry {
        report f"hello, {self.name}";
    }
}

# dispatcher_service.jac (consumer)
sv import from notify_service { Greet }

walker:pub TriggerGreet {
    has who: str;
    can run with Root entry {
        rg = Greet(name=self.who);   # POST /walker/Greet on the provider
        report rg.reports[0];        # "hello, <who>"
    }
}
