---
step: s5_design
status: draft        # draft | approved
approved_at: null
language: null       # set to input_language when first written
---

# Interface and design spec

<!-- One part per interface in project.interfaces: sections 1-14 for gui, then sections 15-19. Each part starts with a scope line, "In scope." or "Not in scope: <reason>.", so readers skip what does not apply. -->

## 1. Mode
<!-- The gui scope line, then the design mode chosen (spec, html_prototypes, user_prototypes) and what it means for this product. Without gui, keep only the scope line here and leave out sections 2-14. -->

## 2. Brand and personality
<!-- Three adjectives, existing brand assets (logo, colors, fonts), references and inspirations, light and/or dark mode. -->

## 3. Color tokens
<!-- Named tokens with values per theme: brand, neutral scale, semantic (success, warning, danger, info), surface and text; contrast checked. -->

## 4. Typography
<!-- Font families, type scale (size and line height per step), weights, and usage per text role. -->

## 5. Spacing and grid
<!-- Spacing scale tokens, layout grid (columns, gutters, max widths) per breakpoint. -->

## 6. Radius and elevation
<!-- Radius tokens and shadow or elevation tokens, with where each is used. -->

## 7. Iconography and imagery
<!-- Icon set and sizes, illustration and photo style, image aspect ratios, alt text rules. -->

## 8. Components and states
<!-- Each component with its variants and states: default, hover, focus, active, disabled, loading, empty, error. -->

## 9. Layout and breakpoints
<!-- Breakpoints with target devices, page layouts (navigation, headers, content areas), responsive behavior. -->

## 10. Key flows
<!-- Mermaid flowcharts of the key user flows, derived from the journeys, referencing user story IDs. -->

## 11. Screens
<!-- One row per screen: ID (e.g. s03), name, user stories, main content and actions, states to design. -->

## 12. Accessibility
<!-- Target (default WCAG 2.2 AA) and product-specific rules: contrast, keyboard, focus, motion, forms. -->

## 13. Tone of voice
<!-- Voice attributes, do and don't examples, terminology, how errors and empty states speak. -->

## 14. Prototype index
<!-- Prototype files in factory/input/prototypes/ with their screen ID and user stories, or "No prototypes (mode: spec)". -->

## 15. API
<!-- Scope line. Resources and operations mapped to user stories; the contract file and its path in the product repository (e.g. docs/openapi.yaml); versioning; error format (default RFC 9457 problem details); pagination, filtering, idempotency, authentication, rate limits; naming conventions. -->

## 16. CLI
<!-- Scope line. Command tree mapped to user stories; argument and flag conventions; help text; exit codes; output formats (human-readable, and JSON for scripts); stdin and stdout behavior; configuration files and environment variables; error messages; color and TTY detection; shell completion when wanted. -->

## 17. Service
<!-- Scope line. Inputs and outputs with their message or event schemas; triggers and schedules; delivery guarantees (at least once, idempotent handlers); retries and dead letters; configuration; health checks, logs and metrics; graceful shutdown. -->

## 18. Library
<!-- Scope line. Public API surface mapped to user stories; naming; error model; supported runtime versions; semantic versioning and deprecation policy; package entry points; usage examples. -->

## 19. Plugin
<!-- Scope line. Host and supported versions; extension points and the manifest; activation events; permissions (least privilege); settings; commands or menus exposed in the host; packaging; how to load it in the host's development mode. -->

## 20. Open questions
<!-- Questions still unanswered; remove each when resolved, or mark it "accepted as open" with the user's agreement. -->
