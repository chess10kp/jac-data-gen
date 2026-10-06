"""OCR processor — converts scanned document images to text via Tesseract or AWS Textract."""

import from os { environ }

glob OCR_ENGINE: str = "tesseract";

"""Run OCR on an image file and return extracted text."""
def ocr_image_file(file_path: str) -> str {
    engine = environ.get("OCR_ENGINE", OCR_ENGINE);
    if engine == "textract" {
        return _textract_ocr(file_path);
    }
    return _tesseract_ocr(file_path);
}

"""Run Tesseract OCR on a file."""
def _tesseract_ocr(file_path: str) -> str {
    try {
        import from pytesseract { image_to_string }
        import from PIL.Image { open as pil_open }
        img = pil_open(file_path);
        text = image_to_string(img, config="--oem 3 --psm 6");
        return text.strip();
    } except Exception as e {
        print(f"[OCR] Tesseract failed for {file_path}: {e}");
        return "";
    }
}

"""Run AWS Textract OCR on a file."""
def _textract_ocr(file_path: str) -> str {
    try {
        import from boto3 { client }
        textract = client("textract", region_name=environ.get("AWS_REGION", "us-east-1"));
        file_bytes = open(file_path, "rb").read();
        response = textract.detect_document_text(Document={"Bytes": file_bytes});
        lines = [];
        for block in response.get("Blocks", []) {
            if block.get("BlockType") == "LINE" {
                lines.append(block.get("Text", ""));
            }
        }
        return "\n".join(lines);
    } except Exception as e {
        print(f"[OCR] Textract failed for {file_path}: {e}");
        return "";
    }
}

"""
Convert PDF to images and OCR each page.
Requires pdf2image and poppler.
"""
def ocr_pdf_pages(pdf_path: str, max_pages: int = 10) -> str {
    try {
        import from pdf2image { convert_from_path }
        import from pytesseract { image_to_string }
        pages = convert_from_path(pdf_path, first_page=1, last_page=max_pages, dpi=300);
        all_text = [];
        page_num = 0;
        for page in pages {
            page_num += 1;
            try {
                text = image_to_string(page, config="--oem 3 --psm 6");
                all_text.append(f"=== Page {page_num} ===\n" + text.strip());
            } except Exception as pe {
                print(f"[OCR] Page {page_num} OCR failed: {pe}");
            }
        }
        return "\n\n".join(all_text);
    } except Exception as e {
        print(f"[OCR] PDF OCR failed for {pdf_path}: {e}");
        return "";
    }
}
