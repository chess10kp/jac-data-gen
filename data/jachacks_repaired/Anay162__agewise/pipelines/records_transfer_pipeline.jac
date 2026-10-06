"""RecordsTransferPipeline — full flow: detect need → generate HIPAA auth → initiate → follow up."""

import from graph.nodes.patient { Patient }
import from graph.walkers.records.transfer_need_detector { TransferNeedDetector }
import from graph.walkers.records.hipaa_auth_generator { HIPAAAuthGenerator }
import from graph.walkers.records.transfer_initiator { TransferInitiator }
import from graph.walkers.records.transfer_followup { TransferFollowup }

walker RecordsTransferPipeline {
    can run with Patient entry {
        here spawn TransferNeedDetector();
        here spawn HIPAAAuthGenerator();
        here spawn TransferInitiator();
        here spawn TransferFollowup();
        report {"pipeline": "records_transfer", "patient": here.name, "status": "complete"};
    }
}
