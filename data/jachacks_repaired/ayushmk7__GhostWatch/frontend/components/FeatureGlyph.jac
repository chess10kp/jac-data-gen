def:pub FeatureGlyph(kind: str) -> JsxElement {
    if kind == "graph" {
        return
            <svg
                viewBox="0 0 32 32"
                width="28"
                height="28"
                fill="none"
                aria-hidden="true"
            >
                <circle
                    cx="8"
                    cy="8"
                    r="4"
                    stroke="rgba(220,239,255,0.84)"
                    strokeWidth="1.8"
                ></circle>
                <circle
                    cx="24"
                    cy="10"
                    r="3.2"
                    stroke="rgba(125,211,255,0.86)"
                    strokeWidth="1.8"
                ></circle>
                <circle
                    cx="19"
                    cy="24"
                    r="4"
                    stroke="rgba(82,229,213,0.86)"
                    strokeWidth="1.8"
                ></circle>
                <path
                    d="M11.6 9.6L20.6 10.2L18.4 20.4L11 11.4"
                    stroke="rgba(220,239,255,0.72)"
                    strokeWidth="1.6"
                ></path>
            </svg>;
    }
    if kind == "walkers" {
        return
            <svg
                viewBox="0 0 32 32"
                width="28"
                height="28"
                fill="none"
                aria-hidden="true"
            >
                <path
                    d="M5 16H27"
                    stroke="rgba(220,239,255,0.82)"
                    strokeWidth="1.8"
                    strokeLinecap="round"
                ></path>
                <path
                    d="M9 8L16 16L9 24"
                    stroke="rgba(125,211,255,0.86)"
                    strokeWidth="1.8"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                ></path>
                <path
                    d="M23 8L16 16L23 24"
                    stroke="rgba(82,229,213,0.86)"
                    strokeWidth="1.8"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                ></path>
            </svg>;
    }
    return
        <svg
            viewBox="0 0 32 32"
            width="28"
            height="28"
            fill="none"
            aria-hidden="true"
        >
            <path
                d="M16 4C12.4 6.1 10.2 6.7 8.2 6.7V14.8C8.2 20.1 11.7 24.7 16 27.2C20.3 24.7 23.8 20.1 23.8 14.8V6.7C21.8 6.7 19.6 6.1 16 4Z"
                stroke="rgba(220,239,255,0.82)"
                strokeWidth="1.8"
            ></path>
            <path
                d="M12.5 16.3L15 18.9L20 13.9"
                stroke="rgba(82,229,213,0.9)"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
            ></path>
        </svg>;
}
