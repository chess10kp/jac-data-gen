cl {
    import from react { useEffect, useRef }

    def:pub Timer() -> JsxElement {
        has seconds: int = 0;

        secondsRef: any = useRef(0);
        secondsRef.current = seconds;

        useEffect(lambda {
            intervalId = setInterval(lambda { seconds = int(secondsRef.current) + 1; }, 1000);
            return lambda { clearInterval(intervalId); };
        }, []);

        return <p>Seconds: {seconds}</p>;
    }
}
