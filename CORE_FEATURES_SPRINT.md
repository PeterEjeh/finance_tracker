# Core Features Enhancement Sprint

## Overview

This sprint focuses on strengthening the core user experience with high-impact, low-cost features that improve retention, engagement, and demonstrate AI-readiness to investors.

---

## 1. Strengthen Core User Experience

### Tasks

- [x] **Smart Categorization (AI-lite)**

  - [x] Implement keyword-based auto-categorization using regex
  - [x] Create category mapping rules (e.g., "Jumia" → Shopping, "Uber" → Transport)
  - [x] Add manual override option for users
  - [x] Plan for future TensorFlow Lite on-device ML model upgrade

- [x] **Analytics Dashboard**

  - [x] Build monthly/weekly spending summary view
  - [x] Add pie chart for expense distribution
  - [x] Add bar graph for spending trends
  - [x] Display "Top 3 Spending Categories"
  - [x] Show "Most Improved Goal" metric
  - [x] Add period comparison (vs last month/week)

- [x] **Reminder & Notification Engine**
  - [x] Set up Firebase Cloud Messaging / local notifications
  - [x] Create smart reminders for upcoming bills
  - [x] Add goal progress notifications
  - [x] Implement budget exceeded alerts
  - [x] Allow users to customize notification preferences

### Deliverables

- [x] Auto-categorization working for common merchants/keywords
- [x] Interactive analytics dashboard with charts
- [x] Smart notification system for bills, budgets, and goals

---

## 2. Automate Small but Useful Tasks

### Tasks

- [ ] **Recurring Transactions**

  - [ ] Add "Mark as Recurring" option to transactions
  - [ ] Support multiple frequencies (daily, weekly, monthly, yearly)
  - [ ] Auto-log recurring transactions with editable amounts
  - [ ] Add recurring transaction management page
  - [ ] Send reminders before recurring transactions are logged

- [ ] **Expense Notes + Attachments**
  - [ ] Add notes field to transactions
  - [ ] Implement photo attachment for receipts
  - [ ] Set up Firebase Storage / local storage for images
  - [ ] Add image preview and management
  - [ ] Prepare for future OCR integration

### Deliverables

- [ ] Recurring transaction system for salaries, rent, subscriptions
- [ ] Receipt photo attachment functionality
- [ ] Notes system for transaction context

---

## 3. Build Early "AI Hooks"

### Tasks

- [ ] **Predictive Insights (Phase 1 - Rule-Based)**

  - [ ] Implement spending comparison logic (week-over-week, month-over-month)
  - [ ] Create insight generation rules (e.g., "30% increase in Food category")
  - [ ] Build insights banner/card component
  - [ ] Display 2-3 key insights on dashboard
  - [ ] Track which insights users engage with

- [ ] **Simulated Advisory Section**
  - [ ] Create mock NSE Advisory card component
  - [ ] Pull sample insights from public financial sources
  - [ ] Display daily/weekly financial tips
  - [ ] Add disclaimer for simulated content
  - [ ] Design for future live trading integration

### Deliverables

- [ ] Rule-based insights displayed on dashboard
- [ ] Mock advisory section showing investment readiness
- [ ] Foundation for future full AI/ML integration

---

## 4. Encourage Financial Habits (Gamification)

### Tasks

- [ ] **Streak System**

  - [ ] Track consecutive days of expense logging
  - [ ] Track savings goal update streaks
  - [ ] Display streak counter on dashboard
  - [ ] Add streak freeze/recovery mechanism
  - [ ] Send encouragement notifications

- [ ] **Milestones + Rewards**
  - [ ] Define milestone criteria (e.g., "First ₦100k Saved," "30-Day Streak")
  - [ ] Design badge system and icons
  - [ ] Create achievements page
  - [ ] Implement unlock animations/celebrations
  - [ ] Add social sharing option for milestones

### Deliverables

- [ ] Streak tracking system with visual indicators
- [ ] Badge/achievement system with multiple milestones
- [ ] Gamification elements that boost retention

---

## 5. Early Data & Feedback Loop

### Tasks

- [ ] **In-App Feedback System**

  - [ ] Add thumbs up/down for insights
  - [ ] Create feedback form component
  - [ ] Implement feedback submission to backend
  - [ ] Set up feedback analytics dashboard
  - [ ] Add optional comment field

- [ ] **Data Export Features**

  - [ ] Implement CSV export for transactions
  - [ ] Implement PDF report generation
  - [ ] Add date range selection for exports
  - [ ] Include budget and goal summaries in exports
  - [ ] Design export templates (branded PDF)

- [ ] **Usage Metrics Tracking**
  - [ ] Track app open frequency
  - [ ] Monitor expense/income addition rates
  - [ ] Track feature usage (budgets, goals, categories)
  - [ ] Measure time spent in app
  - [ ] Create internal analytics dashboard for team

### Deliverables

- [ ] Feedback collection system with analytics
- [ ] CSV and PDF export functionality
- [ ] Usage metrics dashboard for investor presentations

---

## Success Metrics

### User Engagement

- Daily Active Users (DAU) / Monthly Active Users (MAU) ratio
- Average session duration
- Expense logging frequency
- Feature adoption rates

### Feature Performance

- % of transactions auto-categorized correctly
- Notification open rates
- Streak retention rate (% users maintaining streaks)
- Export feature usage

### User Satisfaction

- In-app feedback ratings
- Feature request frequency
- User retention rate (Week 1, Week 4, Month 3)

---

## Timeline Suggestion

### Week 1-2: Foundation

- Smart Categorization
- Recurring Transactions
- Basic Analytics Dashboard

### Week 3-4: Engagement

- Notification Engine
- Streak System
- Milestones & Badges

### Week 5-6: Intelligence

- Predictive Insights (Rule-Based)
- Advisory Section Mock
- Enhanced Analytics

### Week 7-8: Polish & Data

- Expense Notes + Attachments
- Export Features (CSV/PDF)
- Usage Metrics Dashboard
- In-App Feedback System

---

## Notes

- Prioritize features that show immediate user value
- Build with future AI/ML upgrade path in mind
- Focus on metrics that demonstrate traction to investors
- Keep infrastructure costs low while maximizing impact
- Collect user feedback continuously throughout implementation
