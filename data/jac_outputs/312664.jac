"""Forms a string with the full url from a filename and base url.

    Keyword arguments:
    f - filename
    baseUrl - address of the root of the website
    dropExtension - true to drop extensions of .html from the filename in urls
    """
def urlstring(f: str, baseUrl: str, dropExtension: bool = False) -> str {
    if f[0] == "." {
        u = f[1:];
    } else {
        u = f;
    }
    if len(u) >= 11 and u[-11:] == "/index.html" {
        u = u[:-10];
    } elif u == "index.html" {
        u = "";
    } elif dropExtension and len(u) >= 5 and u[-5:] == ".html" {
        u = u[:-5];
    }
    if len(u) >= 1 and u[0] == "/" and len(baseUrl) >= 1 and baseUrl[-1] == "/" {
        u = u[1:];
    } elif (len(u) == 0 or u[0] != "/") and (len(baseUrl) == 0 or baseUrl[-1] != "/") {
        u = "/" + u;
    }
    return baseUrl + u;
}