# BinSight

## Inspiration

Dining halls in the U.S. waste an estimated **$1.8B** of food each year. BinSight turns that gut feeling into proof: take one bin photo, and managers see what was wasted, what it cost, and what to change next week.

Over a semester, this can save thousands of dollars and keep hundreds of meals out of the trash.

## What it does

- **Instant waste analysis:** Upload a bin photo to get item-level waste, estimated weight, cost, and avoidable vs. unavoidable waste.
- **Automatic menu scraping:** Pulls the day's menu from the dining hall site so the model knows what was served.
- **Cost and waste tracking:** Dashboard shows trends over time, category breakdowns, and avoidable/unavoidable split.
- **AI recommendations:** Uses scan history to suggest concrete procurement and portioning changes.

## Local configuration

Create `binsight/.env` for local secrets and runtime options.

```env
ANTHROPIC_API_KEY=your_key_here
ANTHROPIC_VISION_MODEL=claude-sonnet-4-6
ANTHROPIC_TEXT_MODEL=claude-sonnet-4-6
OPENROUTER_VISION_MODEL=openai/gpt-4o
OPENROUTER_TEXT_MODEL=openai/gpt-4o-mini
RESET_ANALYSES_ON_LOAD=false
```

`RESET_ANALYSES_ON_LOAD=false` keeps saved analysis JSON and uploaded images across reloads. Set it to `true` for demo mode where each page load starts clean. The in-app Reset button still clears saved analyses manually.

`LLM_PROVIDER=anthropic` uses the Anthropic model settings. `LLM_PROVIDER=openrouter` uses the OpenRouter model settings. The older `VISION_MODEL` and `TEXT_MODEL` env names still work as OpenRouter fallbacks.

# BinSight

Food-waste analysis demo app.
