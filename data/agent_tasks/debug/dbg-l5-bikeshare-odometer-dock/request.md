Fleet maintenance escalated two things about the bike-share service:

- Wear levelling is broken. `rent_bike` is supposed to hand out the least-worn bike (lowest km, ties by serial), but high-mileage bikes keep going out because after a ride their odometer looks almost new — e.g. A-10 had 10 km, came back from a 4.5 km ride and now reads 4.5 km.
- Station S2 has one dock but `network_status` showed 2 bikes there yesterday; a return was accepted into a full station. Returns to a full station must be refused with "station full".
