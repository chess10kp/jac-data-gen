import:jac from graph {SecurityTarget, ThreatIntel};

walker ScannerWalker {
    has scan_results: list = [];

    can scan_target with SecurityTarget entry {
        print(f"Scanning target: {here.ip_address}");
        here.status = "scanned";
        here.vulnerabilities.append("Open Port 22 (SSH)");
        here.vulnerabilities.append("Outdated OpenSSL");
        
        self.scan_results.append({
            "ip": here.ip_address,
            "vulns": here.vulnerabilities
        });
        
        visit -->;
    }

    can analyze_intel with ThreatIntel entry {
        print("Analyzing threat intel for current context.");
        if "CVE-2024-1234" in here.active_threats {
            print("Critical Threat Found on node!");
            self.scan_results.append({
                "intel_alert": "CVE-2024-1234 active",
                "threat_level": here.threat_level
            });
        }
    }
}

walker CoordinatorWalker {
    can coordinate with SecurityTarget entry {
        print("Coordinator initializing security sweeps.");
    }
}