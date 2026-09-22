"""Return base html document with css style."""
def baseHtml(title: str, body: str) -> str {
    html = '<html>\n<head>\n<title>%s</title>\n<link href="class.css" type="te';
    html += 'xt/css" rel="stylesheet"/>\n</head>\n<body>\n%s\n</body>\n</html>';
    return html % (title, body);
}