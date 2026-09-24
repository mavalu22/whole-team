# UI, UX and accessibility

Rules for every change that touches the interface. Tokens, components, screens and the accessibility target are in `factory/input/05-design-spec.md`; prototypes, if any, are in `factory/input/prototypes/`. The default accessibility target is WCAG 2.2 AA. Search this file for the heading you need.

Sections: 1. Design tokens · 2. Component states · 3. Responsive rules · 4. Accessibility checks · 5. Forms · 6. Microcopy · 7. Review checklist

## 1. Design tokens

- Use tokens for every color, font, size, spacing, radius, shadow and duration. No literal values in components (`#1a73e8`, `13px`), except `0` and `100%`.
- Map tokens to the framework's theme once (the design system base task); components read the theme.
- Semantic tokens over raw ones: `color.text.danger`, not `red-600`, so themes (light and dark) can change values without touching components.
- A missing token is a spec change: add it to the design spec first, then use it.

| Don't | Do |
|---|---|
| `color: #d93025` | `color: var(--color-text-danger)` |
| `margin: 12px 18px` | `margin: var(--space-3) var(--space-4)` |

## 2. Component states

Every interactive component defines and implements each state that applies:

| State | Requirement |
|---|---|
| Default | Matches the spec |
| Hover | Visible change for pointer devices; never the only indicator |
| Focus | Visible focus indicator (section 4) |
| Active | Feedback while pressed |
| Disabled | Visibly disabled, not focusable when it cannot be used, with the reason available when not obvious |
| Loading | Indicator within 100 ms for actions taking longer; prevent double submission |
| Empty | Helpful message and the next action ("No orders yet. Create your first order.") |
| Error | Clear message, what to do next, and a retry where possible |

Screens also handle: first load, slow network, partial data, and permission denied.

## 3. Responsive rules

- Design mobile first; support every breakpoint in the spec. No horizontal scrolling at 320 CSS pixels wide, except for content that needs two dimensions (tables, maps), which scrolls inside its own container.
- Touch targets at least 24 by 24 CSS pixels (WCAG 2.2 minimum), 44 by 44 recommended for primary actions.
- Text reflows at 200% zoom without loss of content or function.
- Use relative units for type and layout; images scale and have explicit dimensions to avoid layout shift.

## 4. Accessibility checks

- **Contrast:** text 4.5:1 (large text 3:1); UI components and focus indicators 3:1 against adjacent colors.
- **Keyboard:** every action works with the keyboard alone, in a logical order; no keyboard traps; modals trap focus while open and return it on close; skip link to main content on pages with navigation.
- **Focus visible:** a clear focus indicator on every focusable element; never `outline: none` without a replacement. Focused elements are not hidden by sticky headers or overlays.
- **Semantics:** native elements first (`button`, `a`, `label`, `input`, `nav`, `main`); headings in order; landmarks; lists as lists. ARIA only when no native element fits, and then with the right roles, states and names.
- **Labels:** every input has a visible label bound to it; icon-only buttons have an accessible name.
- **Alt text:** informative images describe their content or purpose; decorative images use empty `alt=""`.
- **Motion:** respect `prefers-reduced-motion`; nothing flashes more than 3 times per second; no auto-playing motion longer than 5 seconds without a pause control.
- **Status messages:** announce async results (saved, error, results loaded) with a live region.
- **Language:** set the page language; mark content in another language.
- **Authentication:** no cognitive tests (puzzles, transcription) without an alternative; allow paste and password managers.

## 5. Forms

- Labels above or beside fields, never placeholder-only. Mark required fields, or optional ones when most are required, consistently.
- Use the right input types and `autocomplete` attributes (`email`, `current-password`, `new-password`, `one-time-code`).
- Validate on submit, and inline after the user leaves a field; don't show errors while the user is still typing the first time.
- Error messages: next to the field, linked to it (`aria-describedby`), saying what is wrong and how to fix it. On submit with errors, move focus to an error summary or the first invalid field.
- Keep what the user typed after an error; never clear the form.
- Don't ask for information the user already gave (WCAG 2.2 redundant entry).
- Confirm destructive actions, or offer undo.

## 6. Microcopy

- Follow the tone of voice in the spec. Write in the product's language, short and specific.
- Buttons say what they do (`Save changes`, `Delete order`), not `OK` or `Submit`.
- Errors explain what happened and what to do, without blame or codes: "We couldn't save your changes. Check your connection and try again."
- Use the same term for the same thing everywhere (the domain glossary from the vision).
- Numbers, dates and currencies are formatted for the user's locale.
- Keep all interface text in one place per the stack profile (translation files when i18n is required), never hard-coded in many components.

## 7. Review checklist

- [ ] Only tokens are used; no literal colors, sizes or spacing.
- [ ] Every applicable state is implemented (default, hover, focus, active, disabled, loading, empty, error).
- [ ] Layout works at every spec breakpoint and at 320 px, and reflows at 200% zoom.
- [ ] Contrast, keyboard access, visible focus, labels, alt text and reduced motion pass.
- [ ] Forms follow section 5: labels, types, autocomplete, inline errors linked to fields.
- [ ] Microcopy follows the tone of voice and names actions clearly.
- [ ] The screen matches the spec and prototypes, or deviations are reported.
