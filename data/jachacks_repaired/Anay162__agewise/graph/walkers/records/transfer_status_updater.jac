"""TransferStatusUpdater walker — updates records transfer status from callbacks."""

import from graph.nodes.patient { Patient }
import from graph.nodes.records_transfer { RecordsTransfer }
import from datetime { datetime }

walker TransferStatusUpdater {
    has transfer_id: str,
        new_status: str,
        updated_count: int = 0;

    can update with Patient entry {
        for transfer in [here-->] {
            if isinstance(transfer, RecordsTransfer) and transfer.transfer_id == self.transfer_id {
                transfer.status = self.new_status;
                if self.new_status == "RECEIVED" {
                    transfer.received_date = datetime.utcnow().isoformat()[:10];
                }
                self.updated_count += 1;
            }
        }
        report {"updated": self.updated_count, "new_status": self.new_status};
    }
}
