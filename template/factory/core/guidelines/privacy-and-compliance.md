# Privacy and compliance

How the product handles personal data. The applicable laws, retention rules and sensitive data types are in `factory/input/06-constraints.md`; this file gives the practices that apply to all of them. This is engineering guidance, not legal advice: when the constraints name a regulation, the user remains responsible for legal review. Search this file for the heading you need.

Sections: 1. Personal data inventory · 2. Data minimization · 3. Consent and lawful basis · 4. Retention and deletion · 5. Access and export requests · 6. LGPD and GDPR notes · 7. Audit trails · 8. Review checklist

## 1. Personal data inventory

- Personal data is any information about an identifiable person: names, emails, phone numbers, addresses, IP addresses, device IDs, location, photos, identifiers such as tax numbers, and any data linked to them.
- **Sensitive data** needs extra protection: health, biometrics, genetic data, racial or ethnic origin, religion, political opinions, sexual life or orientation, union membership, children's data, and financial data such as card numbers.
- Keep an inventory in `factory/output/architecture.md` (data model section): for each entity field with personal data, record the category, purpose, where it is stored and sent (third parties), retention, and protection (hashed, encrypted, masked).
- Every item that adds a personal data field updates the inventory in the same change.

## 2. Data minimization

- Collect only what a user story needs. If a field has no purpose in the inputs, don't collect it.
- Prefer less precise data when enough: birth year instead of birth date, city instead of address.
- Don't copy personal data into logs, analytics, error reports, caches or test fixtures unless the purpose requires it; use IDs instead.
- Mask or truncate for display where the full value is not needed (`••••1234`).
- Send third parties only the fields their purpose requires, and record them in the inventory.

## 3. Consent and lawful basis

- Each purpose of processing needs a lawful basis recorded in the constraints (for example contract, consent, legal obligation, legitimate interest).
- Where the basis is consent (marketing emails, non-essential cookies, optional analytics):
  - ask with a clear, specific, unticked option, separate from the terms of service;
  - store the consent record: who, what purpose, when, which text version;
  - make withdrawal as easy as giving consent, and stop the processing when it is withdrawn.
- Don't load non-essential trackers or cookies before consent where the constraints require it.

## 4. Retention and deletion

- Every personal data category has a retention period from the constraints; implement it (scheduled deletion or anonymization), don't just document it.
- Account deletion removes or anonymizes the user's personal data across tables, files and object storage, and asks third parties to delete their copies where required. Keep only what a legal obligation requires, with a recorded reason.
- Anonymization must be irreversible: removing the name but keeping a unique email is not anonymization.
- Backups: document how long deleted data can persist in backups and how restores avoid resurrecting it.

## 5. Access and export requests

- Users can see the personal data the product holds about them, and export it in a structured, machine-readable format (for example JSON or CSV), when the constraints require it.
- Users can correct inaccurate data.
- Requests are authenticated (the requester is the data subject) and logged in the audit trail.
- Design the data model so a user's data can be found by user ID across all modules; this makes access, export and deletion feasible.

## 6. LGPD and GDPR notes

Apply when the constraints list them; both share the same core principles:

- **Principles:** purpose limitation, minimization, accuracy, storage limitation, security, accountability, transparency.
- **Data subject rights:** confirmation and access, correction, deletion or anonymization, portability, information about sharing, withdrawal of consent, objection. LGPD (Brazil) and GDPR (EU) both require responding within set deadlines; the product needs the technical means to do it (sections 4 and 5).
- **Sensitive data** (LGPD "dados sensíveis", GDPR "special categories") needs a stricter legal basis and stronger protection.
- **International transfers:** record where each third party stores data.
- **Breach readiness:** security events are logged well enough to know what was exposed (section 7).
- **Children's data:** requires parental consent rules; flag any feature for minors as a decision for the user.

Other regimes (PCI DSS for card data, HIPAA for US health data) add specific controls: for card data, never store full card numbers or CVV; use the payment provider's hosted fields or tokens.

## 7. Audit trails

- Record who did what and when for: access to sensitive data by staff or admins, changes to permissions and roles, data exports, deletions, and consent changes.
- Audit entries: timestamp (UTC), actor ID, action, target ID, outcome, and correlation ID. No sensitive values.
- Audit trails are append-only for the application: no update or delete through normal code paths. Their retention comes from the constraints.

## 8. Review checklist

- [ ] New personal data fields are needed by a user story, and the inventory is updated.
- [ ] Sensitive data has the protection the constraints require.
- [ ] No personal data in logs, analytics, error reports or fixtures beyond the purpose.
- [ ] Consent is captured, stored and withdrawable where consent is the basis.
- [ ] Retention and deletion are implemented for the new data, including files and third parties.
- [ ] Access and export cover the new data where required.
- [ ] Sensitive actions write audit entries without sensitive values.
