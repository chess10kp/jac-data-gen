cl {
    def:pub Timer() -> JsxElement {
        has seconds: int = 0;

        can with entry {
            intervalId = setInterval(lambda -> None {
                seconds = seconds + 1;
            }, 1000);
        }

        can with exit {
            clearInterval(intervalId);
        }

        return <p>Seconds: {seconds}</p>;
    }
}
