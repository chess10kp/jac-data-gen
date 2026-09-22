"""
Fungsi yang menerima input berupa string dan kemudian
mengembalikan string yang berisi tag span dengan class
'active' dan isi yang sama dengan input.

Contoh:
>>> generate_span_tag("")
'<span class="active">HOME</span>'
>>> generate_span_tag("ABOUT")
'<span class="active">ABOUT</span>'
>>> generate_span_tag("CONTACT US")
'<span class="active">CONTACT US</span>'
>>> generate_span_tag("SSYPS")
'<span class="active">SSYPS</span>'
"""
def generate_span_tag(description: str) -> str {
    if description == "" {
        description = "HOME";
    }
    return f'<span class="active">{description}</span>';
}