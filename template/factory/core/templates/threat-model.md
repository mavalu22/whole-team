# Threat model - {{product name}}

<!-- Owned by Security in factory/output/threat-model.md, in English. Written in Discovery step 6 (STRIDE-lite), updated by required security reviews and audits. Keep entries short and concrete. -->

- **Last updated:** {{YYYY-MM-DD}} · **By:** {{Discovery step 6 | T-xxx required review | AUDIT-YYYY-MM-DD}}
- **Sources:** 01-product-vision.md, 03-platform-architecture.md, 06-constraints.md

## 1. Assets

<!-- What must be protected: data (by category), accounts, money, availability, reputation. Rate the impact of compromise. -->

| Asset | Description | Impact if compromised |
|---|---|---|
| {{asset}} | {{description}} | {{high|medium|low}} |

## 2. Actors

<!-- Legitimate actors and their privileges, and adversaries with their likely capabilities. -->

| Actor | Type | Privileges or capabilities |
|---|---|---|
| {{anonymous visitor, user, admin, third-party service, external attacker, malicious insider}} | {{legitimate|adversary}} | {{capabilities}} |

## 3. Trust boundaries

<!-- Where data crosses from less trusted to more trusted zones. Reference the component diagram in factory/output/architecture.md. -->

| ID | Boundary | Data crossing |
|---|---|---|
| TB-{{n}} | {{browser -> API}} | {{credentials, form data}} |

## 4. STRIDE table

<!-- One row per relevant threat. Likelihood and impact: high, medium, low. Status: mitigated, planned (task ID), accepted (with reason). -->

| ID | Boundary | Category | Threat | Likelihood | Impact | Mitigation | Status |
|---|---|---|---|---|---|---|---|
| TH-{{nn}} | TB-{{n}} | {{Spoofing|Tampering|Repudiation|Information disclosure|Denial of service|Elevation of privilege}} | {{threat}} | {{level}} | {{level}} | {{mitigation}} | {{status}} |

## 5. Mitigations

<!-- The controls the product implements, each linked to the threats it addresses and the tasks that deliver it. -->

| Mitigation | Addresses | Delivered by |
|---|---|---|
| {{control}} | TH-{{nn}} | T-{{xxx}} |

## 6. Items requiring a required security review

<!-- Features and areas that must get "Security review: required" in the backlog. -->

- {{area or feature}}: {{reason}}

## 7. Open risks

<!-- Risks not yet mitigated or explicitly accepted by the user, with the owner of the decision. -->

| Risk | Why open | Decision |
|---|---|---|
| {{risk}} | {{reason}} | {{accepted by user on YYYY-MM-DD | pending}} |
