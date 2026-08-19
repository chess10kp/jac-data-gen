node ProcessedPayment {
    has payment_id: str;
}

@restspec(protocol=APIProtocol.WEBHOOK)
walker PaymentReceived {
    has payment_id: str,
        amount: float,
        currency: str = 'USD';

    can process with Root entry {
        if self.amount <= 0.0 {
            report {"status": "rejected", "reason": "amount must be positive"};
            return;
        }

        # Idempotency: skip if we've already recorded this payment_id.
        seen = [p for p in [-->][?:ProcessedPayment] if p.payment_id == self.payment_id];
        if seen {
            report {"status": "duplicate", "payment_id": self.payment_id};
            return;
        }

        root ++> ProcessedPayment(payment_id=self.payment_id);
        report {
            "status": "success",
            "message": f"Payment {self.payment_id} received",
            "amount": self.amount,
            "currency": self.currency
        };
    }
}
