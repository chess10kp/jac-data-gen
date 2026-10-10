The panel load checker gives wrong answers for my workshop:

- On the 240 V sub-panel, `PanelLoad(volts=240.0)` reports the dryer and oven breakers as overloaded and the per-breaker loads are exactly double what my clamp meter shows. It looks like it isn't using the voltage I pass in.
- On the main panel, the garage breaker (10 A rating, a 960 W saw → exactly 8.0 A) is flagged as overloaded. The rule is "strictly above 80% of the rating", so exactly 80% is OK.
