# Migrations

The installer replaces `factory/core/` on update but never touches `factory/config.yaml` or `factory/state.yaml`, because it cannot safely merge YAML that holds comments. The Orchestrator migrates those two files at the start of `Let's code` (startup step 2 in `factory/core/FACTORY.md`), using this procedure.

## Sections

1. Detect
2. Merge the config
3. Apply numbered steps
4. Record
5. Report
6. Numbered migration steps

## 1. Detect

1. Read `config_version` from `factory/config.yaml` and from `factory/core/config.defaults.yaml`.
2. Read `factory_version` and `config_version_applied` from `factory/state.yaml`, and the version in `factory/core/VERSION`.
3. A migration is needed when any of these is true:
   - `config.yaml` `config_version` is lower than the defaults' `config_version`;
   - `state.yaml` `config_version_applied` is lower than the defaults' `config_version`;
   - `state.yaml` `factory_version` differs from `factory/core/VERSION`.
4. If none is true, skip the rest of this file.
5. If `config.yaml` `config_version` is **higher** than the defaults', stop and tell the user: the installed core is older than their config. Ask them to update the WholeTeam clone (`git pull`) and run the installer in update mode.

## 2. Merge the config

Run this only when `config.yaml` `config_version` is lower than the defaults'.

1. Walk `factory/core/config.defaults.yaml` key by key, keeping the nesting path (for example `security.audit_tier`).
2. For each key that is missing in `factory/config.yaml`:
   1. copy the key with its default value and the whole comment block directly above it;
   2. insert it inside the same parent block, after the key that precedes it in the defaults file (or as the first child when there is none);
   3. keep indentation identical to the defaults file.
3. Never change a value the user already has, and never remove a key, even if the defaults no longer contain it. Mention removed keys in the report instead.
4. Set `config_version` in `factory/config.yaml` to the defaults' value. Replace only that line.
5. Re-read the edited file and check that it still parses as YAML and that every key sits on its own line with its comments above it. If it does not parse, restore the previous content and tell the user which key failed.

## 3. Apply numbered steps

1. List the entries of section 6 whose version is higher than `state.yaml` `factory_version` (treat `null` as `0.0.0`) and lower than or equal to `factory/core/VERSION`.
2. Apply them in ascending version order. Each step says exactly which file and key it changes.
3. Apply each step with a small in-place edit. Never rewrite `state.yaml` or `config.yaml` as a whole.

## 4. Record

1. Set `factory_version` in `factory/state.yaml` to the quoted content of `factory/core/VERSION` (for example `factory_version: "1.0.0"`).
2. Set `config_version_applied` to the defaults' `config_version`.
3. Append one line to `log`: `- "<ISO date> migrated <old version> -> <new version>: <short list of changes>"`.
4. The config may now contain new `models` keys, so let startup step 3 (agent model sync) compare the `models` block again.

## 5. Report

Tell the user in one short line, in `config.language`, what changed. Examples:

- `Updated WholeTeam 1.0.0 -> 1.1.0. Added 2 settings with defaults: security.x, git.y.`
- `Updated WholeTeam 1.0.0 -> 1.0.1. No setting changes.`

## 6. Numbered migration steps

Format of an entry, added by each future release that needs one:

```text
### <version>
1. <file>: <exact change>. Reason: <one line>.
```

Entries, in ascending version order:

### 1.0.0

No steps. This is the first release; the config and state templates are the reference.

### 1.0.1

No steps. The config and state formats are unchanged.
