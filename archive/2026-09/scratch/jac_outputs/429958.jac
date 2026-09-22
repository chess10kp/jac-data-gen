"""
    Given a string representing an attachment link, this function asserts if the
    link is a valid PDF link.
    """
def valid_pdf_attachment(pdf_attachment: str) -> bool {
    invalid_urls = [
        "https://www.gov.uk/government/uploads/system/uploads/attachment_data/file/522875/BIS-16-22-evaluation-of-24_-advanced-learning-loans-an-assessment-of-the-first-year.pdf"
    ];
    pdf_extension = ".pdf" in pdf_attachment;
    not_mailto = "mailto" not in pdf_attachment;
    not_invalid = pdf_attachment not in invalid_urls;
    return pdf_extension and not_mailto and not_invalid;
}