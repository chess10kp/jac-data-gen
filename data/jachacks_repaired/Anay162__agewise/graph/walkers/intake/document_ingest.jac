"""DocumentIngest walker — creates Document nodes from incoming sources.

Traverses the Patient node and ingests new documents from:
- Email (IMAP) via the email connector
- Manual upload (file bytes passed in)
- Portal sync (MyMedicare, MyChart)

After creating Document nodes, it queues them for classification.
"""

import from graph.nodes.patient { Patient }
import from graph.nodes.document { Document }
import from abilities.document_hash { compute_content_hash }
import from integrations.email.imap_connector { fetch_new_emails }

import from datetime { datetime }
import from uuid { uuid4 }

walker DocumentIngest {
    has source: str = "email",          # email | upload | portal
        raw_content: str = "",          # for upload mode
        original_filename: str = "",
        source_channel: str = "email";

    can ingest with Patient entry {
        ingested_count = 0;

        if self.source == "email" {
            # Pull new emails from IMAP and create Document nodes
            emails = fetch_new_emails();
            for email_data in emails {
                doc_content = email_data.get("body", "") + "\n" + email_data.get("attachments_text", "");
                content_hash = compute_content_hash(doc_content);

                # Check for duplicates by hash
                existing = [d for d in [here-->] if isinstance(d, Document) and d.content_hash == content_hash];
                if len(existing) > 0 {
                    continue;
                }

                doc = Document(
                    doc_id=str(uuid4()),
                    raw_content=doc_content,
                    source="email",
                    source_channel="email",
                    original_filename=email_data.get("subject", "email"),
                    mime_type="text/plain",
                    ingested_at=datetime.utcnow().isoformat(),
                    content_hash=content_hash
                );
                here ++> doc;
                ingested_count += 1;
            }
        } elif self.source == "upload" {
            content_hash = compute_content_hash(self.raw_content);
            doc = Document(
                doc_id=str(uuid4()),
                raw_content=self.raw_content,
                source="upload",
                source_channel=self.source_channel,
                original_filename=self.original_filename,
                ingested_at=datetime.utcnow().isoformat(),
                content_hash=content_hash
            );
            here ++> doc;
            ingested_count += 1;
        }

        print(f"[DocumentIngest] Ingested {ingested_count} new documents for patient {here.name}");
        report ingested_count;
    }
}
