---
step: s7_testing
status: draft        # draft | approved
approved_at: null
language: null       # set to input_language when first written
---

# Testing

## 1. Level
<!-- The testing level chosen (none, critical, full) and what it means for this product. -->

## 2. Coverage target
<!-- Minimum line coverage in percent when the level is full (default 70), or "Not enforced". -->

## 3. Tools
<!-- Unit, integration and E2E tools and the coverage tool, taken from 04-stack-profile.md. -->

## 4. Critical areas
<!-- The areas treated as critical (auth, payments, personal data, core business rules, data integrity) that apply, with the features they cover. -->

## 5. E2E flows
<!-- The end-to-end flows to automate, one per main journey, each with its steps and user story IDs. -->

## 6. Test data strategy
<!-- Factories or fixtures, seed data, isolation per test and per parallel slot, and the rule that no real personal data is used. -->

## 7. CI policy
<!-- What runs on each push and pull request (lint, type-check, tests, coverage), and what runs only at checkpoints. -->

## 8. Open questions
<!-- Questions still unanswered; remove each when resolved, or mark it "accepted as open" with the user's agreement. -->
