"""PDF text extractor — extracts text from selectable PDFs via pdfplumber."""

"""Extract text from a selectable PDF using pdfplumber."""
def extract_text_from_pdf(pdf_path: str, max_pages: int = 20) -> str {
    try {
        import from pdfplumber { open as pdf_open }
        pdf = pdf_open(pdf_path);
        all_text = [];
        page_num = 0;
        for page in pdf.pages {
            if page_num >= max_pages {
                break;
            }
            page_num += 1;
            text = page.extract_text();
            if text {
                all_text.append(f"=== Page {page_num} ===\n" + text.strip());
            }
        }
        pdf.close();
        return "\n\n".join(all_text);
    } except Exception as e {
        print(f"[PDFExtractor] Extraction failed for {pdf_path}: {e}");
        return "";
    }
}

"""Extract tables from a PDF as list of lists."""
def extract_tables_from_pdf(pdf_path: str, max_pages: int = 20) -> list[list] {
    try {
        import from pdfplumber { open as pdf_open }
        pdf = pdf_open(pdf_path);
        all_tables = [];
        page_num = 0;
        for page in pdf.pages {
            if page_num >= max_pages {
                break;
            }
            page_num += 1;
            tables = page.extract_tables();
            for table in tables {
                all_tables.append(table);
            }
        }
        pdf.close();
        return all_tables;
    } except Exception as e {
        print(f"[PDFExtractor] Table extraction failed for {pdf_path}: {e}");
        return [];
    }
}

"""Return True if the PDF contains selectable text."""
def is_selectable_pdf(pdf_path: str) -> bool {
    try {
        import from pdfplumber { open as pdf_open }
        pdf = pdf_open(pdf_path);
        if len(pdf.pages) == 0 {
            pdf.close();
            return False;
        }
        text = pdf.pages[0].extract_text();
        pdf.close();
        return text is not None and len(text.strip()) > 50;
    } except Exception {
        return False;
    }
}
