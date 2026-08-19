cl {
    import from react { useEffect }

    def:pub Timer() -> JsxElement {
        has seconds: int = 0;

        useEffect(lambda {
            intervalId = setInterval(lambda { seconds = seconds + 1; }, 1000);
            # The returned function is the cleanup -- it runs on unmount
            return lambda { clearInterval(intervalId); };
        }, []);

        return <p>Seconds: {seconds}</p>;
    }
}
