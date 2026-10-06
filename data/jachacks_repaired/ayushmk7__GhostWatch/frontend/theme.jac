glob:pub APP_STYLES: str = """
@import url('https://fonts.googleapis.com/css2?family=Sora:wght@700;800&family=Manrope:wght@200;300;500;700&family=JetBrains+Mono:wght@500;700&display=swap');

:root {
  --font-display: 'Sora', 'Avenir Next', sans-serif;
  --font-body: 'Manrope', 'Helvetica Neue', sans-serif;
  --font-mono: 'JetBrains Mono', 'SFMono-Regular', monospace;
  --weight-light: 200;
  --weight-body: 300;
  --weight-label: 500;
  --weight-bold: 700;
  --weight-black: 800;
  --bg-0: #050608;
  --bg-1: #0a0c10;
  --bg-2: #10141a;
  --bg-3: #141b23;
  --surface-0: rgba(16, 20, 26, 0.58);
  --surface-1: rgba(21, 27, 35, 0.7);
  --surface-2: rgba(28, 36, 46, 0.8);
  --glass-highlight: rgba(255, 255, 255, 0.12);
  --glass-stroke: rgba(220, 239, 255, 0.12);
  --glass-stroke-strong: rgba(220, 239, 255, 0.2);
  --glass-fill: linear-gradient(180deg, rgba(255, 255, 255, 0.08), rgba(255, 255, 255, 0.02)), rgba(18, 24, 31, 0.58);
  --shadow-soft: 0 24px 80px rgba(0, 0, 0, 0.42);
  --text-primary: #f4f7fb;
  --text-secondary: #aab4c3;
  --text-tertiary: #7d8898;
  --accent-frost: #dcefff;
  --accent-cyan: #7dd3ff;
  --accent-aqua: #52e5d5;
  --accent-amber: #ffbf69;
  --accent-red: #ff7b90;
  --accent-lime: #a7f3b0;
  --ease-out: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-soft: cubic-bezier(0.23, 1, 0.32, 1);
  --page-width: min(1400px, calc(100vw - 48px));
  color-scheme: dark;
}

* {
  box-sizing: border-box;
}

html {
  scroll-behavior: smooth;
}

body {
  margin: 0;
  min-height: 100vh;
  background:
    radial-gradient(circle at top, rgba(125, 211, 255, 0.08), transparent 26%),
    linear-gradient(180deg, var(--bg-0), var(--bg-1) 32%, var(--bg-2));
  color: var(--text-primary);
  font-family: var(--font-body);
  font-weight: var(--weight-body);
  letter-spacing: 0.01em;
}

a {
  color: inherit;
  text-decoration: none;
}

button,
input {
  font: inherit;
}

button {
  background: none;
  border: 0;
  color: inherit;
}

input {
  color: inherit;
}

::selection {
  background: rgba(125, 211, 255, 0.24);
  color: var(--text-primary);
}

.gw-root {
  min-height: 100vh;
  position: relative;
  overflow-x: hidden;
}

.gw-page {
  position: relative;
  min-height: 100vh;
  overflow: hidden;
}

.gw-page-inner {
  position: relative;
  z-index: 2;
  width: var(--page-width);
  margin: 0 auto;
  padding: 24px 0 56px;
}

.gw-page-inner--landing {
  padding-top: 28px;
}

.gw-landing-fold {
  /* One viewport: match space inside .gw-page-inner (landing top 28px + bottom 56px). */
  min-height: calc(100svh - 84px);
  max-height: calc(100svh - 84px);
  display: flex;
  flex-direction: column;
  box-sizing: border-box;
  overflow-x: hidden;
  overflow-y: auto;
}

.gw-page-inner--auth {
  padding-top: 32px;
}

.gw-page-inner--app {
  padding-top: 24px;
}

.gw-ambient {
  position: absolute;
  inset: 0;
  overflow: hidden;
  pointer-events: none;
}

.gw-light-pool {
  position: absolute;
  border-radius: 999px;
  filter: blur(26px);
  opacity: 0.8;
}

.gw-light-pool-one {
  width: 36rem;
  height: 36rem;
  left: -8rem;
  top: -8rem;
  background: radial-gradient(circle, rgba(125, 211, 255, 0.3) 0%, rgba(125, 211, 255, 0.06) 45%, transparent 72%);
  animation: gwDrift 16s ease-in-out infinite alternate;
}

.gw-light-pool-two {
  width: 42rem;
  height: 42rem;
  right: -10rem;
  top: 10rem;
  background: radial-gradient(circle, rgba(82, 229, 213, 0.18) 0%, rgba(82, 229, 213, 0.04) 46%, transparent 72%);
  animation: gwDriftAlt 18s ease-in-out infinite alternate;
}

.gw-light-pool-three {
  width: 30rem;
  height: 30rem;
  left: 32%;
  bottom: -8rem;
  background: radial-gradient(circle, rgba(255, 191, 105, 0.12) 0%, rgba(255, 191, 105, 0.03) 48%, transparent 72%);
  animation: gwDrift 14s ease-in-out infinite alternate;
}

.gw-orb {
  position: absolute;
  border-radius: 999px;
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.14), rgba(255, 255, 255, 0.04)),
    rgba(255, 255, 255, 0.02);
  border: 1px solid rgba(220, 239, 255, 0.08);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.1),
    0 24px 60px rgba(0, 0, 0, 0.24);
  backdrop-filter: blur(18px);
  -webkit-backdrop-filter: blur(18px);
}

.gw-orb-one {
  width: 14rem;
  height: 14rem;
  right: 12%;
  top: 7%;
  animation: gwFloatSlow 15s var(--ease-soft) infinite;
}

.gw-orb-two {
  width: 9rem;
  height: 9rem;
  left: 12%;
  bottom: 18%;
  animation: gwFloatAlt 11s var(--ease-soft) infinite;
}

.gw-shield-mark-svg {
  width: 100%;
  height: 100%;
  display: block;
}

.gw-ambient-lines {
  position: absolute;
  inset: -2% -5%;
  width: 110%;
  height: 104%;
  opacity: 0.18;
}

.gw-ambient-auth .gw-ambient-lines {
  opacity: 0.14;
}

.gw-noise-layer {
  position: absolute;
  inset: 0;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 400 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E");
  opacity: 0.055;
  mix-blend-mode: soft-light;
}

.gw-glass-panel {
  position: relative;
  background: var(--glass-fill);
  border: 1px solid var(--glass-stroke);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.1),
    inset 0 0 24px rgba(255, 255, 255, 0.03),
    var(--shadow-soft);
  backdrop-filter: blur(24px) saturate(145%);
  -webkit-backdrop-filter: blur(24px) saturate(145%);
}

.gw-glass-panel::before {
  content: "";
  position: absolute;
  inset: 1px;
  border-radius: inherit;
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.05), transparent 40%);
  opacity: 0.8;
  pointer-events: none;
}

.gw-glass-button {
  position: relative;
  overflow: hidden;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.7rem;
  border-radius: 999px;
  padding: 0.92rem 1.35rem;
  border: 1px solid rgba(220, 239, 255, 0.15);
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.12), rgba(255, 255, 255, 0.04)),
    rgba(17, 22, 29, 0.74);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.12),
    0 16px 32px rgba(0, 0, 0, 0.28);
  color: var(--text-primary);
  cursor: pointer;
  transition:
    transform 220ms var(--ease-out),
    border-color 220ms var(--ease-out),
    background 220ms var(--ease-out),
    box-shadow 220ms var(--ease-out);
}

.gw-glass-button::before {
  content: "";
  position: absolute;
  inset: -150% 28%;
  transform: rotate(24deg);
  background: linear-gradient(180deg, transparent, rgba(255, 255, 255, 0.18), transparent);
  opacity: 0;
  transition: opacity 220ms var(--ease-out);
}

.gw-glass-button:hover,
.gw-glass-button:focus-visible {
  transform: translateY(-2px);
  border-color: rgba(220, 239, 255, 0.26);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.14),
    0 22px 40px rgba(0, 0, 0, 0.34);
}

.gw-glass-button:hover::before,
.gw-glass-button:focus-visible::before {
  opacity: 1;
}

.gw-glass-button:focus-visible,
.gw-nav-link:focus-visible,
.gw-sidebar-item:focus-visible,
.gw-feed-row:focus-visible,
.gw-provider-button:focus-visible,
.gw-auth-input:focus-visible {
  outline: 2px solid rgba(125, 211, 255, 0.62);
  outline-offset: 2px;
}

.gw-button-primary {
  background:
    linear-gradient(180deg, rgba(220, 239, 255, 0.18), rgba(220, 239, 255, 0.07)),
    rgba(125, 211, 255, 0.16);
  border-color: rgba(125, 211, 255, 0.28);
}

/* Primary CTAs: lift on hover only - no brighter border, shadow, or sheen sweep. */
.gw-glass-button.gw-cta-rise-only {
  transition: transform 220ms var(--ease-out);
}

.gw-glass-button.gw-cta-rise-only:hover,
.gw-glass-button.gw-cta-rise-only:focus-visible {
  transform: translateY(-4px);
  border-color: rgba(125, 211, 255, 0.28);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.12),
    0 16px 32px rgba(0, 0, 0, 0.28);
  background:
    linear-gradient(180deg, rgba(220, 239, 255, 0.18), rgba(220, 239, 255, 0.07)),
    rgba(125, 211, 255, 0.16);
}

.gw-glass-button.gw-cta-rise-only:hover::before,
.gw-glass-button.gw-cta-rise-only:focus-visible::before {
  opacity: 0;
}

.gw-landing-bottom-bar {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  flex-wrap: wrap;
  margin-top: 28px;
  padding: 10px 18px;
  border-radius: 18px;
  border: 1px solid rgba(220, 239, 255, 0.08);
  background: rgba(16, 20, 26, 0.45);
}

.gw-landing-bottom-bar-text {
  font-size: 0.92rem;
  color: var(--text-secondary);
  letter-spacing: 0.02em;
}

.gw-landing-bottom-cta {
  padding: 0.62rem 1.15rem;
  font-size: 0.9rem;
}

.gw-button-secondary {
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.08), rgba(255, 255, 255, 0.02)),
    rgba(17, 22, 29, 0.62);
}

.gw-button-ghost {
  background: transparent;
  border-color: rgba(220, 239, 255, 0.1);
}

.gw-pill {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  border-radius: 999px;
  padding: 0.4rem 0.8rem;
  border: 1px solid rgba(220, 239, 255, 0.12);
  background: rgba(255, 255, 255, 0.03);
  font-size: 0.78rem;
  color: var(--text-secondary);
}

.gw-kicker {
  display: inline-flex;
  align-items: center;
  gap: 0.65rem;
  font-size: 0.78rem;
  text-transform: uppercase;
  letter-spacing: 0.22em;
  font-weight: var(--weight-label);
  color: rgba(220, 239, 255, 0.76);
}

.gw-kicker::before {
  content: "";
  width: 44px;
  height: 1px;
  background: linear-gradient(90deg, rgba(82, 229, 213, 0), rgba(82, 229, 213, 0.8));
}

.gw-shell-nav {
  position: sticky;
  top: 18px;
  z-index: 10;
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 18px;
  padding: 18px 22px;
  border-radius: 28px;
}

/* True horizontal center for middle links: equal flex space left and right. */
.gw-shell-nav--balanced {
  grid-template-columns: 1fr auto 1fr;
}

.gw-shell-nav--balanced > .gw-wordmark {
  justify-self: start;
  min-width: 0;
}

.gw-shell-nav--balanced > .gw-header-links {
  justify-self: center;
}

.gw-shell-nav--balanced > .gw-nav-cta {
  justify-self: end;
}

.gw-header-links {
  display: flex;
  justify-content: center;
  gap: 1rem;
  flex-wrap: wrap;
}

.gw-nav-cta {
  white-space: nowrap;
  justify-self: end;
}

.gw-nav-link {
  padding: 0.7rem 0.92rem;
  border-radius: 999px;
  font-size: 0.9rem;
  color: var(--text-secondary);
  transition: color 180ms var(--ease-out), background 180ms var(--ease-out);
}

.gw-nav-link:hover {
  background: rgba(255, 255, 255, 0.04);
  color: var(--text-primary);
}

.gw-wordmark {
  display: inline-flex;
  align-items: center;
  gap: 0.95rem;
}

.gw-wordmark-copy {
  display: flex;
  flex-direction: column;
  gap: 0.16rem;
}

.gw-wordmark-title {
  font-family: var(--font-display);
  font-size: 1.08rem;
  font-weight: var(--weight-bold);
  letter-spacing: -0.03em;
}

.gw-wordmark-subtitle {
  color: var(--text-tertiary);
  font-size: 0.78rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.gw-mark {
  position: relative;
  width: 44px;
  height: 44px;
  border-radius: 14px;
  background:
    radial-gradient(circle at 30% 25%, rgba(255, 255, 255, 0.24), transparent 42%),
    linear-gradient(180deg, rgba(220, 239, 255, 0.18), rgba(17, 22, 29, 0.7));
  border: 1px solid rgba(220, 239, 255, 0.16);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.12),
    0 10px 26px rgba(0, 0, 0, 0.28);
}

.gw-mark-core {
  position: absolute;
  inset: 13px;
  border-radius: 999px;
  background: radial-gradient(circle, rgba(125, 211, 255, 0.9), rgba(82, 229, 213, 0.36) 54%, transparent 70%);
  filter: blur(0.5px);
}

.gw-mark-orbit {
  position: absolute;
  inset: 7px;
  border-radius: 999px;
  border: 1px solid rgba(220, 239, 255, 0.2);
}

.gw-mark-orbit-one {
  inset: 8px 11px 16px 11px;
}

.gw-mark-orbit-two {
  inset: 15px 8px 9px 15px;
}

.gw-role-panel {
  max-width: 920px;
  margin: 0 auto;
  padding-top: 48px;
}

.gw-role-head {
  text-align: center;
  margin-bottom: 36px;
}

.gw-role-title {
  margin: 12px 0 14px;
  font-family: var(--font-display);
  font-size: clamp(2rem, 4vw, 2.75rem);
  font-weight: var(--weight-black);
  letter-spacing: -0.04em;
  line-height: 1.1;
}

.gw-role-sub {
  margin: 0 auto;
  max-width: 52ch;
  color: var(--text-secondary);
  font-size: 1.05rem;
  line-height: 1.75;
}

.gw-role-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 18px;
}

.gw-role-card {
  display: block;
  padding: 26px 26px 24px;
  border-radius: 22px;
  color: inherit;
  text-decoration: none;
  text-align: center;
  border: 1px solid rgba(220, 239, 255, 0.14);
  transition: border-color 0.25s var(--ease-out), transform 0.25s var(--ease-out);
}

.gw-role-card:hover {
  border-color: rgba(125, 211, 255, 0.4);
  transform: translateY(-3px);
}

.gw-role-card-kicker {
  font-size: 0.78rem;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--accent-cyan);
  font-weight: var(--weight-label);
  margin: 0 auto 10px;
  max-width: 100%;
  text-wrap: balance;
}

.gw-role-card-title {
  font-family: var(--font-display);
  font-size: 1.35rem;
  margin: 0 0 10px;
  font-weight: var(--weight-bold);
}

.gw-role-card-body {
  margin: 0;
  color: var(--text-secondary);
  font-size: 0.98rem;
  line-height: 1.65;
}

.gw-role-back {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 22px;
  font-size: 0.92rem;
  color: var(--text-secondary);
}

.gw-role-back-icon {
  flex-shrink: 0;
  opacity: 0.9;
}

.gw-role-back:hover {
  color: var(--text-primary);
}

.gw-landing-main {
  display: grid;
  gap: 54px;
  padding-top: 0;
  margin-top: 54px;
}

.gw-hero {
  display: grid;
  grid-template-columns: minmax(0, 1.04fr) minmax(0, 0.96fr);
  gap: clamp(16px, 2.4vw, 32px);
  align-items: center;
}

.gw-landing-fold > header {
  flex-shrink: 0;
}

.gw-landing-fold .gw-hero-landing {
  flex: 1 1 auto;
  min-height: 0;
  display: flex;
  flex-direction: column;
}

.gw-hero-landing-center {
  flex: 1;
  width: 100%;
  min-height: 0;
  display: grid;
  grid-template-columns: 1fr;
  grid-template-rows: 1fr;
  justify-items: center;
  align-items: center;
}

.gw-hero-landing-backdrop {
  grid-column: 1;
  grid-row: 1;
  place-self: stretch;
  z-index: 0;
  pointer-events: none;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 0;
}

.gw-hero-landing-orb-anim {
  display: flex;
  align-items: center;
  justify-content: center;
}

.gw-hero-landing-orb {
  width: min(78vmin, 24rem);
  height: min(78vmin, 24rem);
  max-width: min(92vw, 400px);
  max-height: min(92vw, 400px);
  flex-shrink: 0;
  border-radius: 999px;
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.18), rgba(255, 255, 255, 0.05)),
    rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(220, 239, 255, 0.16);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.14),
    0 28px 80px rgba(0, 0, 0, 0.35),
    0 0 80px rgba(125, 211, 255, 0.08);
  backdrop-filter: blur(20px) saturate(145%);
  -webkit-backdrop-filter: blur(20px) saturate(145%);
  display: flex;
  align-items: center;
  justify-content: center;
}

.gw-hero-landing-orb-shield {
  width: 76%;
  height: 76%;
  min-width: 80px;
  min-height: 80px;
  max-width: 260px;
  max-height: 260px;
  display: flex;
  align-items: center;
  justify-content: center;
  pointer-events: none;
  filter: drop-shadow(0 0 20px rgba(125, 211, 255, 0.15));
}

.gw-hero-landing-content {
  grid-column: 1;
  grid-row: 1;
  place-self: center;
  position: relative;
  z-index: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  width: fit-content;
  max-width: min(42rem, 94vw);
  padding: 0 clamp(12px, 3vw, 22px);
  box-sizing: border-box;
}

.gw-landing-fold .gw-hero-title {
  margin: 0 0 clamp(10px, 1.6vh, 22px);
  padding-top: 0.04em;
  font-size: clamp(2rem, 3.8dvh + 2.4vw, 6.4rem);
  line-height: 1.07;
  letter-spacing: -0.055em;
  max-width: 22ch;
  position: relative;
  z-index: 1;
  text-shadow: 0 2px 28px rgba(0, 0, 0, 0.55);
}

.gw-landing-fold .gw-hero-text {
  margin: 0 0 clamp(10px, 1.8vh, 22px);
  font-size: clamp(0.9rem, 0.9dvh + 0.75vw, 1.2rem);
  line-height: 1.62;
  max-width: 52ch;
  text-shadow: 0 1px 18px rgba(0, 0, 0, 0.5);
}

.gw-landing-fold .gw-kicker {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: center;
  width: 100%;
  max-width: 100%;
  margin: 0 auto clamp(16px, 2.6vh, 28px);
  padding-top: 2px;
  position: relative;
  z-index: 2;
  text-align: center;
  color: rgba(236, 244, 255, 0.96);
  font-weight: var(--weight-label);
  text-shadow: 0 1px 18px rgba(0, 0, 0, 0.45);
}

.gw-landing-fold .gw-hero-title,
.gw-landing-fold .gw-hero-text {
  margin-left: auto;
  margin-right: auto;
}

.gw-landing-fold .gw-hero-pillars {
  width: 100%;
  max-width: 36rem;
  margin-left: auto;
  margin-right: auto;
}

@media (max-height: 520px) {
  .gw-landing-fold .gw-kicker {
    font-size: 0.68rem;
    letter-spacing: 0.16em;
    margin-bottom: 10px;
  }

  .gw-landing-fold .gw-hero-text {
    display: -webkit-box;
    -webkit-line-clamp: 3;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
}

.gw-hero-copy {
  position: relative;
  z-index: 2;
}

.gw-hero-title {
  margin: 18px 0 18px;
  font-family: var(--font-display);
  font-size: clamp(3.2rem, 7vw, 6.4rem);
  line-height: 0.92;
  letter-spacing: -0.06em;
  font-weight: var(--weight-black);
  max-width: 11ch;
}

.gw-hero-text {
  margin: 0 0 28px;
  max-width: 58ch;
  color: var(--text-secondary);
  font-size: clamp(1.02rem, 1.5vw, 1.24rem);
  line-height: 1.88;
}

.gw-hero-actions {
  display: flex;
  gap: 14px;
  flex-wrap: wrap;
  margin-bottom: 26px;
}

.gw-chip-row {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
  margin-bottom: 26px;
}

.gw-metric-chip {
  border-radius: 20px;
  padding: 18px;
}

.gw-metric-value {
  font-family: var(--font-display);
  font-size: 1.8rem;
  font-weight: var(--weight-black);
  letter-spacing: -0.05em;
}

.gw-metric-label {
  margin-top: 0.5rem;
  color: var(--text-secondary);
  font-size: 0.9rem;
}

.gw-metric-detail {
  margin-top: 0.25rem;
  color: var(--text-tertiary);
  font-size: 0.78rem;
}

.gw-system-strip {
  border-radius: 24px;
  padding: 16px 18px;
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

.gw-system-strip span {
  font-size: 0.82rem;
  font-weight: var(--weight-label);
  color: rgba(220, 239, 255, 0.84);
  padding: 0.58rem 0.78rem;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.06);
}

.gw-hero-pillars {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: clamp(8px, 1.2vw, 14px);
}

.gw-hero-pillar {
  border-radius: 18px;
  padding: clamp(12px, 1.6vh, 18px) clamp(10px, 1.2vw, 16px);
  min-height: 3.35rem;
  display: flex;
  align-items: center;
  justify-content: center;
  text-align: center;
  font-size: clamp(0.72rem, 0.55dvh + 0.55vw, 0.84rem);
  font-weight: var(--weight-label);
  letter-spacing: 0.02em;
  color: rgba(220, 239, 255, 0.9);
  line-height: 1.25;
}

.gw-hero-visual {
  position: relative;
  min-height: 640px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.gw-ghost-emblem {
  width: min(100%, 560px);
  height: auto;
}

.gw-hero-alert-card,
.gw-hero-telemetry {
  position: absolute;
  border-radius: 22px;
  padding: 18px 20px;
}

.gw-hero-alert-card {
  left: 2%;
  bottom: 6%;
  width: min(320px, 72%);
}

.gw-hero-alert-label,
.gw-telemetry-label {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--text-tertiary);
  font-size: 0.76rem;
  text-transform: uppercase;
  letter-spacing: 0.18em;
}

.gw-hero-alert-label::before,
.gw-telemetry-label::before {
  content: "";
  width: 8px;
  height: 8px;
  border-radius: 999px;
  background: var(--accent-red);
  box-shadow: 0 0 18px rgba(255, 123, 144, 0.65);
}

.gw-hero-alert-title,
.gw-telemetry-value {
  margin-top: 0.9rem;
  font-family: var(--font-display);
  font-size: 1.28rem;
  font-weight: var(--weight-bold);
  letter-spacing: -0.03em;
}

.gw-hero-alert-copy,
.gw-telemetry-copy {
  margin-top: 0.55rem;
  color: var(--text-secondary);
  line-height: 1.6;
  font-size: 0.92rem;
}

.gw-telemetry {
  width: min(240px, 46%);
}

.gw-telemetry-top {
  right: -2%;
  top: 10%;
}

.gw-telemetry-middle {
  left: 6%;
  top: 13%;
}

.gw-telemetry-bottom {
  right: 8%;
  bottom: 18%;
}

.gw-section {
  position: relative;
}

.gw-section-head {
  margin-bottom: 22px;
  max-width: 760px;
}

.gw-section-title {
  margin: 12px 0 10px;
  font-family: var(--font-display);
  font-size: clamp(2.2rem, 4.3vw, 3.6rem);
  line-height: 0.98;
  letter-spacing: -0.05em;
  font-weight: var(--weight-black);
}

.gw-section-copy {
  margin: 0;
  color: var(--text-secondary);
  font-size: 1rem;
  line-height: 1.8;
}

.gw-feature-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 20px;
}

.gw-feature-card {
  min-height: 250px;
  border-radius: 28px;
  padding: 24px;
}

.gw-feature-icon {
  width: 56px;
  height: 56px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 18px;
  background:
    radial-gradient(circle at 30% 25%, rgba(255, 255, 255, 0.14), transparent 46%),
    rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(220, 239, 255, 0.08);
  margin-bottom: 22px;
}

.gw-feature-title {
  margin: 0;
  font-family: var(--font-display);
  font-size: 1.34rem;
  letter-spacing: -0.03em;
}

.gw-feature-body {
  margin: 0.9rem 0 0;
  color: var(--text-secondary);
  line-height: 1.8;
}

.gw-flow-grid {
  display: grid;
  grid-template-columns: repeat(5, minmax(0, 1fr));
  gap: 18px;
}

.gw-flow-card {
  border-radius: 26px;
  padding: 22px 18px;
}

.gw-flow-step {
  color: rgba(220, 239, 255, 0.78);
  font-size: 0.74rem;
  font-weight: var(--weight-label);
  letter-spacing: 0.2em;
  text-transform: uppercase;
}

.gw-flow-name {
  margin-top: 0.9rem;
  font-family: var(--font-display);
  font-size: 1.18rem;
  letter-spacing: -0.03em;
}

.gw-flow-copy {
  margin-top: 0.7rem;
  color: var(--text-secondary);
  line-height: 1.7;
  font-size: 0.92rem;
}

.gw-flow-pulse {
  margin-top: 1.15rem;
  height: 2px;
  width: 100%;
  background: linear-gradient(90deg, rgba(125, 211, 255, 0), rgba(125, 211, 255, 0.92), rgba(82, 229, 213, 0));
  opacity: 0.82;
  animation: gwScan 4.8s linear infinite;
}

.gw-preview-shell {
  border-radius: 30px;
  padding: 22px;
}

.gw-preview-topbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 18px;
  margin-bottom: 18px;
}

.gw-preview-topbar-left,
.gw-preview-topbar-right {
  display: flex;
  gap: 10px;
  align-items: center;
}

.gw-preview-pill,
.gw-preview-dot {
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(220, 239, 255, 0.08);
}

.gw-preview-pill {
  height: 34px;
}

.gw-preview-pill-wide {
  width: 180px;
}

.gw-preview-pill-small {
  width: 98px;
}

.gw-preview-dot {
  width: 34px;
  height: 34px;
}

.gw-preview-body {
  display: grid;
  grid-template-columns: 170px minmax(0, 1fr);
  gap: 16px;
  min-height: 320px;
}

.gw-preview-sidebar {
  border-radius: 24px;
  padding: 16px;
  display: grid;
  gap: 12px;
}

.gw-preview-sidebar-line {
  height: 14px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.06);
}

.gw-preview-content {
  display: grid;
  gap: 16px;
}

.gw-preview-summary {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
}

.gw-preview-card {
  min-height: 92px;
  border-radius: 22px;
  padding: 16px;
}

.gw-preview-card-label {
  color: var(--text-tertiary);
  font-size: 0.76rem;
  text-transform: uppercase;
  letter-spacing: 0.18em;
}

.gw-preview-card-value {
  margin-top: 0.9rem;
  font-family: var(--font-display);
  font-size: 1.45rem;
  letter-spacing: -0.04em;
}

.gw-preview-graph {
  position: relative;
  min-height: 192px;
  border-radius: 26px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-secondary);
  text-align: center;
}

.gw-preview-graph::after {
  content: "";
  position: absolute;
  inset: 18px;
  border-radius: 20px;
  border: 1px dashed rgba(220, 239, 255, 0.18);
}

.gw-cta-panel {
  border-radius: 30px;
  padding: 30px;
  display: flex;
  justify-content: space-between;
  gap: 22px;
  align-items: flex-end;
}

.gw-cta-copy h3 {
  margin: 0 0 12px;
  font-family: var(--font-display);
  font-size: clamp(1.8rem, 4vw, 3rem);
  letter-spacing: -0.05em;
}

.gw-cta-copy p {
  margin: 0;
  color: var(--text-secondary);
  line-height: 1.8;
}

.gw-cta-actions {
  display: flex;
  gap: 14px;
  flex-wrap: wrap;
}

.gw-auth-grid {
  display: grid;
  grid-template-columns: minmax(0, 0.92fr) minmax(0, 1.08fr);
  gap: 30px;
  align-items: center;
  min-height: calc(100vh - 72px);
}

.gw-auth-story {
  position: relative;
  display: grid;
  gap: 20px;
}

.gw-auth-title {
  margin: 8px 0 0;
  max-width: 10ch;
  font-family: var(--font-display);
  font-size: clamp(2.8rem, 6vw, 5.2rem);
  line-height: 0.94;
  letter-spacing: -0.06em;
  font-weight: var(--weight-black);
}

.gw-auth-copy {
  margin: 0;
  max-width: 48ch;
  color: var(--text-secondary);
  line-height: 1.85;
}

.gw-auth-visual {
  width: min(100%, 520px);
  margin-top: 10px;
}

.gw-auth-surface {
  display: grid;
  gap: 18px;
}

.gw-auth-card,
.gw-auth-note-card {
  border-radius: 30px;
}

.gw-auth-card {
  padding: 30px;
}

.gw-auth-form {
  display: grid;
  gap: 16px;
}

.gw-auth-card-header h2 {
  margin: 0 0 10px;
  font-family: var(--font-display);
  font-size: 2rem;
  letter-spacing: -0.04em;
}

.gw-auth-card-header p {
  margin: 0;
  color: var(--text-secondary);
  line-height: 1.7;
}

.gw-provider-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

.gw-provider-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 0.96rem 1rem;
  border-radius: 18px;
  border: 1px solid rgba(220, 239, 255, 0.12);
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.08), rgba(255, 255, 255, 0.02)),
    rgba(18, 24, 31, 0.62);
  color: var(--text-primary);
  cursor: pointer;
  transition: transform 180ms var(--ease-out), border-color 180ms var(--ease-out);
}

.gw-provider-button:hover {
  transform: translateY(-2px);
  border-color: rgba(220, 239, 255, 0.2);
}

.gw-provider-icon {
  width: 20px;
  height: 20px;
}

.gw-auth-divider {
  display: flex;
  align-items: center;
  gap: 0.9rem;
  color: var(--text-tertiary);
  font-size: 0.82rem;
  text-transform: uppercase;
  letter-spacing: 0.18em;
}

.gw-auth-divider::before,
.gw-auth-divider::after {
  content: "";
  flex: 1;
  height: 1px;
  background: linear-gradient(90deg, rgba(220, 239, 255, 0), rgba(220, 239, 255, 0.18), rgba(220, 239, 255, 0));
}

.gw-auth-field {
  display: grid;
  gap: 0.55rem;
}

.gw-auth-label {
  font-size: 0.8rem;
  color: rgba(220, 239, 255, 0.7);
  letter-spacing: 0.16em;
  text-transform: uppercase;
}

.gw-auth-input {
  width: 100%;
  border-radius: 18px;
  border: 1px solid rgba(220, 239, 255, 0.12);
  background: rgba(8, 11, 15, 0.5);
  padding: 1rem 1.05rem;
  min-height: 56px;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.04);
  transition: border-color 180ms var(--ease-out), background 180ms var(--ease-out);
}

.gw-auth-input::placeholder {
  color: rgba(125, 136, 152, 0.72);
}

.gw-auth-input:hover,
.gw-auth-input:focus-visible {
  border-color: rgba(125, 211, 255, 0.3);
  background: rgba(10, 14, 19, 0.65);
}

.gw-auth-legal {
  color: var(--text-tertiary);
  font-size: 0.82rem;
  line-height: 1.7;
}

.gw-auth-note-card {
  padding: 22px 24px;
}

.gw-note-list {
  display: grid;
  gap: 12px;
  margin-top: 16px;
}

.gw-note-item {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  padding: 0.88rem 0.96rem;
  border-radius: 16px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(220, 239, 255, 0.06);
  color: var(--text-secondary);
}

.gw-note-item span:first-child {
  color: var(--text-primary);
}

.gw-app-shell {
  display: grid;
  grid-template-columns: 286px minmax(0, 1fr);
  gap: 22px;
  min-height: calc(100vh - 48px);
}

.gw-sidebar {
  border-radius: 32px;
  padding: 22px;
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.gw-sidebar-nav {
  display: grid;
  gap: 10px;
}

.gw-sidebar-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 0.85rem;
  padding: 0.92rem 1rem;
  border-radius: 20px;
  border: 1px solid transparent;
  cursor: pointer;
  color: var(--text-secondary);
  transition:
    background 180ms var(--ease-out),
    border-color 180ms var(--ease-out),
    transform 180ms var(--ease-out),
    color 180ms var(--ease-out);
}

.gw-sidebar-item:hover {
  background: rgba(255, 255, 255, 0.04);
  color: var(--text-primary);
}

.gw-sidebar-item.is-active {
  background:
    linear-gradient(180deg, rgba(220, 239, 255, 0.12), rgba(220, 239, 255, 0.03)),
    rgba(125, 211, 255, 0.08);
  border-color: rgba(125, 211, 255, 0.16);
  color: var(--text-primary);
  transform: translateX(2px);
}

.gw-sidebar-icon {
  width: 34px;
  height: 34px;
  border-radius: 12px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(220, 239, 255, 0.08);
  font-family: var(--font-mono);
  font-size: 0.74rem;
  color: rgba(220, 239, 255, 0.84);
}

.gw-sidebar-copy {
  display: grid;
  gap: 0.16rem;
  text-align: left;
}

.gw-sidebar-copy strong {
  font-size: 0.94rem;
  letter-spacing: -0.02em;
}

.gw-sidebar-copy span {
  font-size: 0.76rem;
  color: var(--text-tertiary);
}

.gw-sidebar-footer {
  margin-top: auto;
  display: grid;
  gap: 14px;
}

.gw-demo-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.6rem;
  width: fit-content;
  padding: 0.7rem 0.88rem;
  border-radius: 999px;
  background: rgba(82, 229, 213, 0.07);
  border: 1px solid rgba(82, 229, 213, 0.14);
  color: rgba(220, 255, 250, 0.92);
  font-size: 0.8rem;
  font-weight: var(--weight-label);
}

.gw-demo-badge::before {
  content: "";
  width: 8px;
  height: 8px;
  border-radius: 999px;
  background: var(--accent-aqua);
  box-shadow: 0 0 18px rgba(82, 229, 213, 0.5);
}

.gw-profile-card {
  display: flex;
  align-items: center;
  gap: 0.85rem;
  padding: 0.92rem 1rem;
  border-radius: 20px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(220, 239, 255, 0.08);
}

.gw-avatar {
  width: 42px;
  height: 42px;
  border-radius: 14px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background:
    radial-gradient(circle at 35% 30%, rgba(255, 255, 255, 0.18), transparent 40%),
    linear-gradient(180deg, rgba(125, 211, 255, 0.24), rgba(17, 22, 29, 0.8));
  border: 1px solid rgba(220, 239, 255, 0.16);
  font-family: var(--font-display);
  font-weight: var(--weight-bold);
}

.gw-profile-meta {
  display: grid;
  gap: 0.2rem;
}

.gw-profile-meta strong {
  font-size: 0.92rem;
}

.gw-profile-meta span {
  color: var(--text-tertiary);
  font-size: 0.78rem;
}

.gw-workspace {
  display: grid;
  gap: 18px;
}

.gw-workspace--connect {
  min-height: calc(100vh - 120px);
  place-content: center;
}

.gw-topbar {
  border-radius: 30px;
  padding: 18px 20px;
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 18px;
  align-items: center;
}

.gw-topbar-heading {
  display: grid;
  gap: 0.5rem;
}

.gw-topbar-heading h1 {
  margin: 0;
  font-family: var(--font-display);
  font-size: clamp(1.8rem, 3vw, 2.8rem);
  letter-spacing: -0.04em;
}

.gw-topbar-heading p {
  margin: 0;
  color: var(--text-secondary);
}

.gw-topbar-actions {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
  justify-content: flex-end;
}

.gw-repo-select,
.gw-icon-button,
.gw-search-shell {
  border-radius: 18px;
  border: 1px solid rgba(220, 239, 255, 0.1);
  background: rgba(8, 11, 15, 0.34);
  min-height: 52px;
}

.gw-repo-select {
  display: inline-flex;
  align-items: center;
  gap: 0.78rem;
  padding: 0 1rem;
}

.gw-repo-label {
  display: grid;
  gap: 0.16rem;
  text-align: left;
}

.gw-repo-label strong {
  font-size: 0.92rem;
}

.gw-repo-label span {
  font-size: 0.76rem;
  color: var(--text-tertiary);
}

.gw-search-shell {
  display: inline-flex;
  align-items: center;
  gap: 0.8rem;
  padding: 0 0.9rem;
  min-width: 280px;
}

.gw-search-shell svg {
  flex-shrink: 0;
  color: var(--text-tertiary);
}

.gw-search-input {
  width: 100%;
  background: transparent;
  border: 0;
  outline: none;
}

.gw-icon-button {
  width: 52px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  position: relative;
  cursor: pointer;
}

.gw-icon-badge {
  position: absolute;
  top: 9px;
  right: 9px;
  min-width: 18px;
  height: 18px;
  border-radius: 999px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 123, 144, 0.92);
  color: #10131a;
  font-size: 0.68rem;
  font-weight: var(--weight-bold);
}

.gw-command-banner {
  border-radius: 24px;
  padding: 16px 18px;
  display: flex;
  justify-content: space-between;
  gap: 18px;
  align-items: center;
}

.gw-command-banner strong {
  font-size: 0.88rem;
  text-transform: uppercase;
  letter-spacing: 0.16em;
  color: rgba(220, 239, 255, 0.78);
}

.gw-command-banner p {
  margin: 0.45rem 0 0;
  color: var(--text-secondary);
  line-height: 1.7;
}

.gw-main-grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 330px;
  gap: 20px;
}

.gw-main-grid--single {
  grid-template-columns: minmax(0, 1fr);
}

.gw-wordmark-link {
  text-decoration: none;
  color: inherit;
  border-radius: 20px;
  outline-offset: 4px;
}

.gw-wordmark-link:focus-visible {
  outline: 2px solid rgba(125, 211, 255, 0.45);
}

.gw-sidebar-item--no-icon {
  padding-left: 1.1rem;
}

.gw-repo-connect {
  border-radius: 28px;
  padding: 2rem 2.25rem;
  max-width: 560px;
  margin: 0 auto;
  align-self: center;
  display: grid;
  gap: 1.1rem;
}

.gw-repo-connect-title {
  margin: 0;
  font-size: 1.35rem;
  letter-spacing: -0.03em;
}

.gw-repo-connect-lede {
  margin: 0;
  color: var(--text-secondary);
  line-height: 1.65;
  font-size: 0.92rem;
}

.gw-repo-connect-code {
  font-family: var(--font-mono);
  font-size: 0.82rem;
  color: rgba(186, 230, 253, 0.92);
}

.gw-repo-connect-row {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  align-items: center;
}

.gw-repo-connect-input {
  flex: 1 1 220px;
  min-width: 0;
  border-radius: 16px;
  border: 1px solid rgba(220, 239, 255, 0.14);
  background: rgba(6, 10, 18, 0.55);
  color: var(--text-primary);
  padding: 0.75rem 1rem;
  font-size: 0.9rem;
}

.gw-repo-connect-input::placeholder {
  color: var(--text-tertiary);
}

.gw-table-panel {
  border-radius: 24px;
  padding: 1.25rem 1.35rem 1.35rem;
}

.gw-table-panel-title {
  margin: 0 0 1rem;
  font-size: 1.05rem;
  letter-spacing: -0.02em;
}

.gw-data-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.86rem;
}

.gw-data-table th,
.gw-data-table td {
  text-align: left;
  padding: 0.65rem 0.75rem;
  border-bottom: 1px solid rgba(220, 239, 255, 0.08);
  vertical-align: top;
}

.gw-data-table th {
  color: var(--text-tertiary);
  font-weight: var(--weight-label);
  text-transform: uppercase;
  letter-spacing: 0.12em;
  font-size: 0.68rem;
}

.gw-data-table--compact td {
  padding: 0.5rem 0.75rem;
}

.gw-repo-row-current {
  background: rgba(125, 211, 255, 0.06);
}

.gw-settings-column {
  gap: 16px;
}

.gw-settings-block {
  border-radius: 24px;
  padding: 1.25rem 1.35rem 1.35rem;
  display: grid;
  gap: 0.85rem;
}

.gw-settings-row {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  color: var(--text-secondary);
  font-size: 0.88rem;
  cursor: pointer;
}

.gw-settings-label {
  min-width: 160px;
  color: var(--text-secondary);
  font-size: 0.86rem;
}

.gw-settings-select {
  flex: 1;
  max-width: 220px;
  border-radius: 14px;
  border: 1px solid rgba(220, 239, 255, 0.14);
  background: rgba(6, 10, 18, 0.55);
  color: var(--text-primary);
  padding: 0.45rem 0.65rem;
  font-size: 0.86rem;
}

.gw-settings-hint {
  margin: 1rem 0 0;
  font-size: 0.8rem;
  color: var(--text-tertiary);
  line-height: 1.55;
}

.gw-main-column {
  display: grid;
  gap: 18px;
}

.gw-summary-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 18px;
}

.gw-summary-card {
  border-radius: 24px;
  padding: 20px;
  display: grid;
  gap: 1rem;
}

.gw-summary-card.is-frost {
  border-color: rgba(220, 239, 255, 0.18);
}

.gw-summary-card.is-cyan {
  border-color: rgba(125, 211, 255, 0.2);
}

.gw-summary-card.is-aqua {
  border-color: rgba(82, 229, 213, 0.2);
}

.gw-summary-card.is-amber {
  border-color: rgba(255, 191, 105, 0.22);
}

.gw-summary-label {
  color: var(--text-tertiary);
  font-size: 0.76rem;
  text-transform: uppercase;
  letter-spacing: 0.18em;
}

.gw-summary-value {
  font-family: var(--font-display);
  font-size: 2rem;
  font-weight: var(--weight-black);
  letter-spacing: -0.05em;
}

.gw-summary-delta {
  color: var(--text-secondary);
  font-size: 0.88rem;
}

.gw-summary-spark {
  width: 100%;
  height: 48px;
}

.gw-threat-panel,
.gw-graph-panel,
.gw-right-panel {
  border-radius: 28px;
  padding: 22px;
}

.gw-panel-head {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: flex-start;
  margin-bottom: 18px;
}

.gw-panel-head h2,
.gw-right-panel h3 {
  margin: 0;
  font-family: var(--font-display);
  font-size: 1.32rem;
  letter-spacing: -0.03em;
}

.gw-panel-head p,
.gw-right-panel p {
  margin: 0.55rem 0 0;
  color: var(--text-secondary);
  line-height: 1.65;
  font-size: 0.92rem;
}

.gw-feed-list {
  display: grid;
  gap: 12px;
}

.gw-feed-row {
  width: 100%;
  display: grid;
  grid-template-columns: auto auto minmax(0, 1fr) auto;
  gap: 12px;
  align-items: center;
  padding: 1rem 1.04rem;
  border-radius: 18px;
  background: rgba(255, 255, 255, 0.035);
  border: 1px solid rgba(220, 239, 255, 0.06);
  text-align: left;
  cursor: pointer;
  transition:
    transform 180ms var(--ease-out),
    border-color 180ms var(--ease-out),
    background 180ms var(--ease-out);
}

.gw-feed-row:hover {
  transform: translateY(-1px);
  border-color: rgba(220, 239, 255, 0.14);
  background: rgba(255, 255, 255, 0.05);
}

.gw-feed-time {
  color: var(--text-tertiary);
  font-family: var(--font-mono);
  font-size: 0.76rem;
}

.gw-feed-copy strong {
  display: block;
  font-size: 0.94rem;
  letter-spacing: -0.02em;
}

.gw-feed-copy span {
  display: block;
  margin-top: 0.32rem;
  color: var(--text-secondary);
  font-size: 0.84rem;
  line-height: 1.6;
}

.gw-feed-hint {
  color: rgba(220, 239, 255, 0.7);
  font-size: 0.8rem;
}

.gw-severity-pill,
.gw-state-pill {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 999px;
  padding: 0.44rem 0.7rem;
  font-size: 0.72rem;
  font-weight: var(--weight-label);
  letter-spacing: 0.14em;
  text-transform: uppercase;
}

.gw-severity-critical {
  background: rgba(255, 123, 144, 0.12);
  color: rgba(255, 189, 199, 0.94);
  border: 1px solid rgba(255, 123, 144, 0.18);
}

.gw-severity-high {
  background: rgba(255, 191, 105, 0.12);
  color: rgba(255, 214, 164, 0.96);
  border: 1px solid rgba(255, 191, 105, 0.18);
}

.gw-severity-medium {
  background: rgba(125, 211, 255, 0.12);
  color: rgba(210, 239, 255, 0.96);
  border: 1px solid rgba(125, 211, 255, 0.18);
}

.gw-state-active {
  background: rgba(82, 229, 213, 0.1);
  color: rgba(196, 255, 248, 0.94);
  border: 1px solid rgba(82, 229, 213, 0.18);
}

.gw-state-queued {
  background: rgba(255, 191, 105, 0.08);
  color: rgba(255, 224, 184, 0.92);
  border: 1px solid rgba(255, 191, 105, 0.16);
}

.gw-state-watching {
  background: rgba(125, 211, 255, 0.1);
  color: rgba(219, 244, 255, 0.94);
  border: 1px solid rgba(125, 211, 255, 0.16);
}

.gw-graph-panel {
  position: relative;
  min-height: 470px;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.gw-graph-inner-frame {
  position: absolute;
  inset: 22px;
  border-radius: 26px;
  border: 1px dashed rgba(220, 239, 255, 0.18);
  box-shadow:
    inset 0 0 80px rgba(125, 211, 255, 0.02),
    inset 0 1px 0 rgba(255, 255, 255, 0.04);
}

.gw-graph-copy {
  position: relative;
  z-index: 2;
  max-width: 560px;
  text-align: center;
}

.gw-graph-copy span {
  display: inline-flex;
  align-items: center;
  gap: 0.55rem;
  border-radius: 999px;
  padding: 0.48rem 0.82rem;
  border: 1px solid rgba(220, 239, 255, 0.12);
  background: rgba(255, 255, 255, 0.04);
  color: rgba(220, 239, 255, 0.84);
  font-size: 0.8rem;
  text-transform: uppercase;
  letter-spacing: 0.18em;
}

.gw-graph-copy span::before {
  content: "";
  width: 8px;
  height: 8px;
  border-radius: 999px;
  background: var(--accent-cyan);
  box-shadow: 0 0 14px rgba(125, 211, 255, 0.5);
}

.gw-graph-copy h2 {
  margin: 1.15rem 0 0.8rem;
  font-family: var(--font-display);
  font-size: clamp(2rem, 4vw, 3.1rem);
  line-height: 0.96;
  letter-spacing: -0.05em;
}

.gw-graph-copy p {
  margin: 0;
  color: var(--text-secondary);
  line-height: 1.8;
}

.gw-graph-foot {
  margin-top: 1.15rem;
  color: var(--text-tertiary);
  font-size: 0.88rem;
}

.gw-graph-constellation {
  position: absolute;
  inset: 6px;
  width: calc(100% - 12px);
  height: calc(100% - 12px);
  opacity: 0.42;
}

.gw-right-rail {
  display: grid;
  gap: 18px;
}

.gw-right-panel {
  border-radius: 28px;
}

.gw-right-list {
  display: grid;
  gap: 12px;
  margin-top: 14px;
}

.gw-right-item {
  display: flex;
  justify-content: space-between;
  gap: 14px;
  align-items: center;
  padding: 0.88rem 0.95rem;
  border-radius: 18px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(220, 239, 255, 0.06);
}

.gw-right-item strong {
  font-size: 0.9rem;
  letter-spacing: -0.02em;
}

.gw-right-item span {
  color: var(--text-secondary);
  font-size: 0.78rem;
}

.gw-session-notes {
  display: grid;
  gap: 10px;
  margin-top: 14px;
}

.gw-session-note {
  padding: 0.9rem 0.98rem;
  border-radius: 18px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(220, 239, 255, 0.06);
  color: var(--text-secondary);
  line-height: 1.7;
  font-size: 0.88rem;
}

.gw-fade-up {
  opacity: 0;
  transform: translateY(26px) scale(0.985);
  animation: gwFadeUp 0.88s var(--ease-out) forwards;
}

/* Opacity-only entrance: safe to combine with gw-float-* (transform) on a parent/child. */
.gw-fade-in {
  opacity: 0;
  animation: gwFadeInOnly 0.78s var(--ease-out) forwards;
}

@keyframes gwFadeInOnly {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

.gw-stagger-1 {
  animation-delay: 0.08s;
}

.gw-stagger-2 {
  animation-delay: 0.16s;
}

.gw-stagger-3 {
  animation-delay: 0.24s;
}

.gw-stagger-4 {
  animation-delay: 0.32s;
}

.gw-stagger-5 {
  animation-delay: 0.4s;
}

.gw-stagger-6 {
  animation-delay: 0.48s;
}

.gw-stagger-7 {
  animation-delay: 0.56s;
}

.gw-stagger-8 {
  animation-delay: 0.64s;
}

.gw-float-slow {
  animation: gwFloatSlow 14s var(--ease-soft) infinite;
}

.gw-float-medium {
  animation: gwFloatMedium 10s var(--ease-soft) infinite;
}

.gw-float-delay {
  animation: gwFloatAlt 12s var(--ease-soft) infinite;
}

@keyframes gwFadeUp {
  from {
    opacity: 0;
    transform: translateY(26px) scale(0.985);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

@keyframes gwFloatSlow {
  0%,
  100% {
    transform: translateY(0px);
  }
  50% {
    transform: translateY(-12px);
  }
}

@keyframes gwFloatMedium {
  0%,
  100% {
    transform: translate3d(0, 0, 0);
  }
  50% {
    transform: translate3d(0, -18px, 0);
  }
}

@keyframes gwFloatAlt {
  0%,
  100% {
    transform: translate3d(0, 0, 0);
  }
  50% {
    transform: translate3d(0, 12px, 0);
  }
}

@keyframes gwDrift {
  0% {
    transform: translate3d(0, 0, 0) scale(1);
  }
  100% {
    transform: translate3d(30px, 18px, 0) scale(1.04);
  }
}

@keyframes gwDriftAlt {
  0% {
    transform: translate3d(0, 0, 0) scale(1);
  }
  100% {
    transform: translate3d(-24px, -18px, 0) scale(1.05);
  }
}

@keyframes gwScan {
  0% {
    transform: scaleX(0.65);
    transform-origin: left center;
    opacity: 0.45;
  }
  50% {
    transform: scaleX(1);
    transform-origin: center center;
    opacity: 0.92;
  }
  100% {
    transform: scaleX(0.65);
    transform-origin: right center;
    opacity: 0.45;
  }
}

@media (max-width: 1240px) {
  .gw-hero {
    grid-template-columns: 1fr;
  }

  .gw-hero-copy {
    order: 1;
  }

  .gw-hero-visual {
    order: 0;
    min-height: 560px;
  }

  .gw-hero-pillars {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .gw-flow-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }

  .gw-main-grid {
    grid-template-columns: 1fr;
  }

  .gw-right-rail {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }

  .gw-summary-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 980px) {
  .gw-page-inner {
    width: min(100vw - 28px, 100%);
  }

  .gw-shell-nav {
    grid-template-columns: 1fr;
    justify-items: start;
  }

  .gw-shell-nav--balanced {
    grid-template-columns: 1fr auto 1fr;
    justify-items: stretch;
    gap: 10px;
    padding-left: 14px;
    padding-right: 14px;
  }

  .gw-shell-nav--balanced > .gw-wordmark {
    justify-self: start;
  }

  .gw-shell-nav--balanced > .gw-header-links {
    justify-self: center;
  }

  .gw-shell-nav--balanced > .gw-nav-cta {
    justify-self: end;
  }

  .gw-header-links {
    justify-content: flex-start;
  }

  .gw-shell-nav--balanced .gw-header-links {
    justify-content: center;
  }

  .gw-feature-grid,
  .gw-flow-grid,
  .gw-chip-row,
  .gw-summary-grid,
  .gw-right-rail,
  .gw-provider-grid {
    grid-template-columns: 1fr;
  }

  .gw-preview-body,
  .gw-auth-grid,
  .gw-app-shell {
    grid-template-columns: 1fr;
  }

  .gw-role-grid {
    grid-template-columns: 1fr;
  }

  .gw-sidebar {
    order: 0;
  }

  .gw-topbar {
    grid-template-columns: 1fr;
  }

  .gw-topbar-actions {
    justify-content: stretch;
  }

  .gw-search-shell {
    min-width: 0;
    width: 100%;
  }
}

@media (max-width: 720px) {
  .gw-page-inner {
    padding-top: 18px;
  }

  .gw-shell-nav {
    padding-top: 12px;
  }

  .gw-hero-telemetry,
  .gw-hero-alert-card {
    position: static;
    width: 100%;
    margin-top: 16px;
  }

  .gw-hero-visual {
    display: grid;
    justify-items: center;
    gap: 16px;
    min-height: auto;
  }

  .gw-hero-actions,
  .gw-cta-actions,
  .gw-topbar-actions {
    flex-direction: column;
    align-items: stretch;
  }

  .gw-provider-grid {
    grid-template-columns: 1fr;
  }

  .gw-feed-row {
    grid-template-columns: 1fr;
    justify-items: start;
  }

  .gw-command-banner {
    flex-direction: column;
    align-items: flex-start;
  }
}

/* Phone: hide secondary ambient orb; hero shield stays in landing backdrop. */
@media (max-width: 639px) {
  .gw-ambient-landing .gw-orb-two {
    display: none;
  }

  .gw-hero-landing-orb {
    max-width: min(88vw, 300px);
    max-height: min(88vw, 300px);
  }

  .gw-landing-fold {
    max-height: none;
    height: auto;
    min-height: calc(100svh - 84px);
  }
}

@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }

  .gw-fade-up {
    opacity: 1;
    transform: none;
  }

  .gw-fade-in {
    opacity: 1;
  }
}

/* ── Node animation keyframes ─────────────────────── */
@keyframes gw-node-pulse {
  0%, 100% { filter: drop-shadow(0 0 0px rgba(125,211,255,0)); }
  50%       { filter: drop-shadow(0 0 10px rgba(125,211,255,0.85)); }
}

@keyframes gw-node-scan {
  0%   { filter: drop-shadow(0 0 0px rgba(125,211,255,0)); opacity: 0.85; }
  20%  { filter: drop-shadow(0 0 18px rgba(125,211,255,1)); opacity: 1; }
  100% { filter: drop-shadow(0 0 0px rgba(125,211,255,0)); opacity: 0.85; }
}

/* ── ReactFlow canvas container ───────────────────── */
.gw-graph-canvas {
  height: 400px;
  width: 100%;
  background: rgba(0,0,0,0.2);
  border-radius: 8px;
  overflow: hidden;
  position: relative;
}

/* ── Node tooltip ───────────────────────────────────── */
.gw-node-tooltip {
  position: absolute;
  bottom: 12px;
  right: 12px;
  z-index: 20;
  background: rgba(8,20,40,0.88);
  backdrop-filter: blur(14px);
  -webkit-backdrop-filter: blur(14px);
  border: 1px solid rgba(125,211,255,0.28);
  border-radius: 8px;
  padding: 10px 13px;
  min-width: 200px;
  pointer-events: none;
}

.gw-node-tooltip-path {
  font-size: 10px;
  color: rgba(125,211,255,0.75);
  font-family: var(--gw-font-mono, monospace);
  word-break: break-all;
  margin-bottom: 8px;
  line-height: 1.4;
}

.gw-node-tooltip-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  margin-top: 4px;
}

.gw-node-tooltip-label {
  font-size: 10px;
  color: rgba(220,239,255,0.72);
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.gw-node-tooltip-value {
  font-size: 11px;
  color: #ffffff;
  font-weight: 500;
}

.gw-node-tooltip-value--high {
  color: rgba(239,68,68,0.9);
}

.gw-node-tooltip-value--med {
  color: rgba(251,191,36,0.9);
}
""";
