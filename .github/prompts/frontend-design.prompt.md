---
name: frontend-design
description: Create distinctive, production-grade frontend interfaces for AppTorneos. Use this prompt when building or restyling screens, dashboards, landing pages, or interactive UI in the front Flutter app. Favor bold visual systems, clear hierarchy, and working code that matches the product context.
license: Complete terms in LICENSE.txt
---

Use this prompt for AppTorneos UI work with a strong aesthetic point of view.

Context:
- Project: AppTorneos
- Frontend: Flutter app in `front/`
- Main screen to improve: `Inicio` in `front/lib/screens/main_shell/tabs/inicio_tab.dart`
- Data should come from real backend endpoints, not hardcoded mock content.

Design goals:
- Build interfaces that feel intentional, modern, and memorable.
- Prefer a bold hero section, layered cards, gradient atmosphere, and clear CTA hierarchy.
- Use real content structure: categories, upcoming tournaments, quick stats, and actionable buttons.
- Keep layouts responsive and production-ready.

Implementation guidance:
- Reuse existing app components when they fit, especially category avatars and shared cards.
- If the UI needs curated data, add the backend endpoint first and then wire the frontend to it.
- Keep the code readable and easy to maintain.