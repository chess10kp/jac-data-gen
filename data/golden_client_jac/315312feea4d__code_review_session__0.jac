import from datetime { datetime }

walker:pub health {
    can check with Root entry {
        try {
            _ = [-->];
            report {"status": "healthy", "checked_at": datetime.now().isoformat()};
        } except Exception as e {
            report {"status": "unhealthy", "error": str(e)};
        }
    }
}
