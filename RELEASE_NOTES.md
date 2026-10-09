# Release notes

**Google Play listing copy** lives in the `play_store/` folder (`short_description.txt`, `full_description.txt`, `what_s_new_1.0.0.txt`). See `play_store/PLAY_STORE_CHECKLIST.md` for screenshots, 512×512 store icon, privacy policy, and Data safety.

**Launcher icon:** source `assets/branding/app_icon.png` — regenerate with `dart run flutter_launcher_icons` after changes.

---

## Version 1.1.5

### App & Web Blocker

- **Adult-website filter now works.** The accessibility service was not allowed to read window content, so the filter never triggered even though the app advertised it. The service can now read the address bar of Chrome, Brave, Edge, Vivaldi, Kiwi, Samsung Internet, Firefox, Firefox Focus, Opera, Opera Mini and DuckDuckGo. Other browsers are not covered, and the app says so.
- **Interventions show after a cold start.** Opening a blocked app while Break Free was not running used to open the dashboard instead of the intervention screen.
- **Companion notifications only when linked.** Blocked-app and adult-website events are sent to Firestore only if a companion is linked; otherwise nothing leaves the device.
- **Accurate disclosure.** The accessibility disclosure and the system settings description now list exactly what is read, which browsers are covered, and what a linked companion receives.

### Accountability

- **Removed the unfinished SMS partner feature.** It never sent anything: its channel name did not match the native side and the SMS permission had already been dropped. Settings now leads to Companion Sync, which notifies a linked companion by push notification.

---

## Version 1.0.0 (Initial release)

**Break Free** – A gamified coach to help you build better habits and stay on track.

### What’s new

- **Habit tracking** – Add habits, check in daily, and watch your streaks grow.
- **Streak protection** – Use **Freezes** (1 per week) and **Streak Shield** (unlocked at Level 3) so one slip doesn’t wipe your progress.
- **Levels & rewards** – Earn XP and coins for check-ins. Level up from Beginner to Hero of Break Free and unlock rewards.
- **Streak milestones** – Hit 3, 7, 14, 30+ days and see your progress with badges and “days to next goal.”
- **Relapse support** – Log a slip with triggers, choose to use a freeze or shield when available, or confirm before resetting your streak.
- **Panic button** – Quick access when you need support.
- **Mind City** – Your city grows as you level up.
- **Journal** – Reflect and stay mindful.
- **Modern design** – Clean UI, smooth animations, and a focused experience.

---

### Short release notes (for Play Store “What’s new” – under 500 characters)

```
Welcome to Break Free 1.0.

• Track habits and build streaks
• Protect streaks with Freezes and Streak Shield (Level 3+)
• Earn XP and coins; level up from Beginner to Hero
• Streak milestones at 3, 7, 14, 30+ days
• Log slips with triggers; confirm before resetting
• Panic button, Mind City, and Journal
• New design and animations

Thanks for trying Break Free.
```

---

### One-line (for store subtitle or social)

**Break Free 1.0** – Gamified habit coach with streak protection, levels, and rewards.
