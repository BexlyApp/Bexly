# Bexly — Shinhan Hackathon Live Pitch (4 minutes)

**Format:** 9 slides · ~25s per slide · bilingual-ready (English slide content, Vietnamese speaker notes).
**Goal:** Prove Bexly is the self-hosted AI Financial Coach that solves SB1, runs on Shinhan's own infrastructure, and is ready to ship.

---

## Slide 1 — Title (0:00 – 0:15, 15s)

**On screen**
> **Bexly**
> The Self-Hosted AI Financial Coach for SOL
> *Shinhan Bank Vietnam Hackathon · SB1*
> Team Bexly · April 2026

**Visual:** Bexly logo, "Shinhan x Bexly" lockup, single hero phone mockup of chat screen with a Vietnamese coaching reply.

**Speaker (VI):**
> "Xin chào BGK. Bexly là một AI Financial Coach chạy hoàn toàn trên server của Shinhan — không một byte dữ liệu khách hàng nào rời khỏi ngân hàng. Trong 4 phút tới tôi sẽ chứng minh tại sao đây là fit chính xác cho SB1."

---

## Slide 2 — The Problem (0:15 – 0:40, 25s)

**On screen — title**
> Banking apps track money. They don't coach.

**Bullets (3 lines, large font)**
- 80% of SOL users open the app, check balance, leave.
- Cross-sell today = banner ads → low conversion.
- **Cloud AI APIs cannot be used in production** — Vietnamese banking regulation requires data sovereignty; customer financial data cannot leave the bank's infrastructure.

**Visual:** Split screen — left: typical banking app (cold transaction list). Right: a banner ad ignored by user. Red "❌ data leaves bank" stamp on a cloud AI logo.

**Speaker (VI):**
> "Banking app hôm nay chỉ show lịch sử giao dịch — chưa hiểu hành vi tài chính của khách. Cross-sell dựa vào banner, tỉ lệ convert thấp. Và quan trọng nhất — AI cloud **không dùng được production** vì quy định tại Việt Nam yêu cầu dữ liệu tài chính phải ở trong hạ tầng ngân hàng. Đó là rào cản mà mọi giải pháp AI thông thường không vượt qua được."

---

## Slide 3 — Our Solution (0:40 – 1:00, 20s)

**On screen — title**
> Bexly: a conversational AI that *acts* on financial data

**3-pillar layout**
| 💬 Coach | ⚡ Action Engine | 🏦 On-Premise |
|---------|-----------------|---------------|
| Proactive coaching in 14 languages | 15+ structured actions via natural language | 100% open-source, self-hosted on Shinhan GPUs |

**Visual:** Three equal-weight tiles. Under each, a small icon and one-liner. Bottom strip: "Qwen 3.5 · vLLM · Supabase · Flutter — all Apache 2.0 / open-source."

**Speaker (VI):**
> "Bexly làm được ba việc cùng lúc: (1) **coach** khách hàng bằng tiếng Việt với tông giọng thân thiện; (2) biến câu nói thường thành **action** trên database — tạo giao dịch, budget, goal, đăng ký sản phẩm; và (3) toàn bộ stack là **open-source, chạy trên GPU của Shinhan** — không gọi API ngoài."

---

## Slide 4 — What the AI Does (1:00 – 1:30, 30s)

**On screen — title**
> Beyond chat: 15+ banking actions from plain language

**Two-column list**

**Finance actions**
- `create_expense` · `create_income`
- `create_budget` · `create_goal`
- `create_recurring` · `get_summary`
- `list_transactions` · `get_balance`

**Shinhan banking actions**
- `apply_credit_card` (cashback)
- `open_savings_account` (CASA)
- `apply_loan` (personal)
- `transfer_to_savings`

**Proactive intelligence (footer strip)**
- Financial Health Score (0–100) · Spending Forecast · Anomaly Alerts · Daily Digest

**Visual:** Two columns of chips. Below, a single chat bubble: *"Tôi trả Netflix 200k/tháng"* → arrow → green ACTION_JSON → green check → "Recurring charge created".

**Speaker (VI):**
> "Khác biệt cốt lõi: LLM không chỉ trả chữ — nó trả ra **ACTION_JSON** mà app thực thi ngay. Khách nói 'tôi trả Netflix 200k mỗi tháng', AI tự hiểu đây là recurring charge và tạo bản ghi. Khách nói 'số dư nhàn rỗi quá nhiều', AI gợi ý mở tài khoản tiết kiệm Shinhan — và một action duy nhất `open_savings_account` mở luôn flow mở tài khoản. Đó là cross-sell *contextual*, không phải banner."

---

## Slide 5 — Live Demo (1:30 – 2:30, 60s) 🎬

**On screen — title**
> Live: @BexlyBot on Telegram · Demo account *Minh*

**Demo script (hit these 4 beats)**

1. **`/start` → pick "Minh — Office Worker 20M VND/month"** (5s)
2. **User: `Ăn tối hôm qua hết 1tr500k`** → bot replies with ✅ saved, shows balance update (10s)
3. **User: `Các giao dịch gần đây của tôi?`** → bot lists 10 recent tx with Financial Health Score context (15s)
4. **User: `Làm sao để tôi tiết kiệm nhiều hơn?`** → bot analyzes real spending and recommends **Shinhan Premium Savings** + **Cashback Credit Card** with actual numbers (25s)
5. **Close:** *"Mọi câu trả lời các bạn vừa thấy đều do Qwen 3.5 chạy trên server on-premise của chúng tôi sinh ra — không một request nào ra cloud."* (5s)

**Visual:** Laptop screen mirrored on slide. Pre-open Telegram and the demo bot. Prepare Minh's account with seeded data (already done).

**Speaker (VI):**
> "Đây là demo thật trên Telegram. [thao tác 4 bước trên]. Lưu ý: mọi lời tư vấn các bạn vừa thấy đều được tạo ra bởi Qwen 3.5 chạy trên GPU server của team — zero cloud API."

**Backup:** Nếu internet fail, có video recording 45s của demo này làm fallback.

---

## Slide 6 — On-Premise Architecture (2:30 – 2:55, 25s) ⭐

**On screen — title**
> Zero data leaves the bank. Ever.

**Architecture diagram (simple boxes + arrows, all inside one big "Shinhan Data Center" frame)**

```
┌─────────── Shinhan Data Center (on-premise) ───────────┐
│                                                         │
│   [SOL App] ──► [Supabase self-host] ──► [vLLM + Qwen] │
│         │              (Postgres)            (GPU)      │
│         └──► [Core Banking API]                         │
│                                                         │
└─────────────────────────────────────────────────────────┘
            ❌ No external API calls
```

**License table (right side, compact)**
| Stack | License |
|-------|---------|
| Qwen 3.5 35B-A3B | Apache 2.0 |
| vLLM | Apache 2.0 |
| Supabase | Apache 2.0 |
| SQLite/Drift | Public Domain |
| Flutter | BSD-3 |

**Speaker (VI):**
> "Đây là thứ không đối thủ nào chạy cloud-AI có thể làm: **toàn bộ stack open-source, deploy trên hạ tầng Shinhan, zero data leakage**. Compliance-ready từ ngày đầu."

---

## Slide 7 — SB1 Expected Outcomes: Delivered (2:55 – 3:20, 25s)

**On screen — title**
> 5/5 SB1 outcomes already shipped

| # | Shinhan Outcome | Bexly Feature | ✓ |
|---|-----------------|---------------|---|
| 1 | Increase DAU/MAU | Daily Digest, Health Score, streaks | ✅ |
| 2 | Cross-sell conversion | 6 product triggers + banking actions | ✅ |
| 3 | Reduce churn | Anomaly alerts, forecast, proactive AI | ✅ |
| 4 | NPS/CSAT | Coach persona, personalized dialogue, in-app survey | ✅ |
| 5 | Grow CASA balance | Auto-Suggest Savings + `transfer_to_savings` | ✅ |

**Visual:** Clean table with green ✅ down the rightmost column. Subtitle: "Not a roadmap — all 5 are running in the demo you just saw."

**Speaker (VI):**
> "Năm kết quả Shinhan đặt ra cho SB1 — Bexly đã triển khai cả năm. Đây không phải roadmap, đây là tính năng đã chạy trong demo các bạn vừa xem."

---

## Slide 8 — Roadmap & Integration Path (3:20 – 3:45, 25s)

**On screen — title**
> From hackathon prototype → SOL production in 90 days

**3-phase timeline (horizontal)**

**Phase 1 — Weeks 1–4:** SOL SDK integration via Flutter platform channel · Core Banking API feed · Security audit
**Phase 2 — Weeks 5–8:** Multi-instance vLLM cluster on Shinhan GPUs · Load testing at SOL scale · Vietnamese prompt tuning with Shinhan product team
**Phase 3 — Weeks 9–12:** Soft launch to 10K pilot users · A/B test cross-sell lift · NPS tracking · Full rollout

**Bottom strip:** *"We bring the AI. Shinhan brings the users and the product catalog. Open-source means you own the stack forever."*

**Speaker (VI):**
> "90 ngày là lộ trình đưa Bexly vào SOL production. Team chúng tôi mang AI stack + 33 feature modules; Shinhan mang người dùng và catalog sản phẩm. Vì open-source — Shinhan **sở hữu** stack này vĩnh viễn, không lock-in."

---

## Slide 9 — Close & CTA (3:45 – 4:00, 15s)

**On screen — big, centered**
> **Bexly**
> Self-hosted. Open-source. SB1-ready.
>
> Try it: **@BexlyBot** on Telegram
> Repo: github.com/BexlyApp/Bexly
>
> *Thank you. Questions?*

**Visual:** QR code to Telegram bot (left) + QR code to GitHub repo (right). Team name + contact.

**Speaker (VI):**
> "Bexly — self-hosted, open-source, SB1-ready. QR bên trái mở Telegram bot thật, bên phải là repo. Cảm ơn BGK — mời đặt câu hỏi."

---

## Timing Cheat Sheet

| Slide | Time | Cumulative | Core message in 1 line |
|-------|------|------------|------------------------|
| 1 Title | 15s | 0:15 | Self-hosted AI coach for SOL |
| 2 Problem | 25s | 0:40 | Cloud AI can't comply with VN banking regs |
| 3 Solution | 20s | 1:00 | Coach + Action Engine + On-Premise |
| 4 What it does | 30s | 1:30 | 15+ actions from plain language |
| 5 **LIVE DEMO** | 60s | 2:30 | See it work on Telegram |
| 6 **Architecture** | 25s | 2:55 | Zero data leaves the bank |
| 7 SB1 outcomes | 25s | 3:20 | 5/5 delivered, not promised |
| 8 Roadmap | 25s | 3:45 | 90-day path into SOL |
| 9 Close | 15s | 4:00 | CTA + QR codes |

**Total: 4:00 exact.** Leave 15s buffer for demo hiccups by cutting Slide 4 to 20s if needed.

---

## Delivery Tips

- **Slide 5 is the emotional peak** — don't rush. Let the audience *see* the bot reply. Silence for 2s while reading is OK.
- **Slide 6 is the logical peak** — this is where you win SB1 on the "on-premise / compliance" axis. Say "zero data leaves the bank" twice.
- **Slide 7 is the proof** — point at the checkmarks with a laser pointer if available.
- **Avoid slide animations** beyond simple fades. Hackathon judges watch 10+ pitches, clarity > flash.
- **Backup plan if demo fails:** 45s pre-recorded MP4 of the Telegram flow, embedded in Slide 5. Switch to it without apologizing — just "here's a recording for speed."
- **What to wear:** Business casual. Shinhan is a conservative bank — no hoodies.
- **Q&A prep:** Most likely judge questions → see `docs/hackathon-qa-prep.md` (TODO if not done: cover "How do you handle PII?", "What's your accuracy on OCR?", "Can Qwen handle SOL's scale?").

---

## Assets Needed Before Pitch Day

- [ ] Logo lockup Bexly + Shinhan (Slide 1)
- [ ] Phone mockup with Vietnamese chat screenshot (Slide 1)
- [ ] Architecture diagram as clean SVG (Slide 6)
- [ ] 45s demo video MP4 as backup (Slide 5 fallback)
- [ ] QR code for @BexlyBot (Slide 9)
- [ ] QR code for GitHub repo (Slide 9)
- [ ] Seeded demo account "Minh" verified working 10 min before pitch
- [ ] Phone hotspot as internet backup
