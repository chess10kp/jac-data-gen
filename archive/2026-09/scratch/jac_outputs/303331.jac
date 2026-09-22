"""Generate error packet.

`endpoint`
    Optional endpoint name
`reason`
    Error reason
`advice`
    Error advice
"""
def error(endpoint: str | None, reason: str | None, advice: str | None = None) -> str {
    '7::%s:%s+%s' % (endpoint or '', reason or '', advice or '')
}