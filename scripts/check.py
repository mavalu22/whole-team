#!/usr/bin/env python3
"""Read-only consistency checks for WholeTeam's hand-maintained copies."""

from collections import Counter
from itertools import zip_longest
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parent.parent
ROLES = ROOT / "template/factory/core/roles"
AGENTS = (
    (ROOT / "template/root/.claude/agents", ".md"),
    (ROOT / "template/root/.codex/agents", ".toml"),
)


def problem(problems, path, message):
    problems.append("{}: {}".format(path.relative_to(ROOT), message))


def read_bytes(path, problems):
    try:
        return path.read_bytes()
    except OSError as error:
        problem(problems, path, "cannot read file ({})".format(error.strerror))
        return None


def read_text(path, problems):
    data = read_bytes(path, problems)
    if data is None:
        return None
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError:
        problem(problems, path, "expected UTF-8 text")
        return None


def extract_agent(path, text, slug, problems):
    if path.suffix == ".md":
        front = re.match(r"\A---\n(.*?)\n---\n", text, re.DOTALL)
        if front is None:
            problem(problems, path, "expected YAML front matter between --- lines")
            return None
        header = front.group(1)
        body = text[front.end():]
        # Claude has exactly one blank line before the preamble; Codex has none.
        if not body.startswith("\nYou are "):
            problem(problems, path, "expected one blank line before the preamble")
            return None
        body = body[1:]
        names = re.findall(r"^name: ([^\n]+)$", header, re.MULTILINE)
        expected_name = "factory-" + slug
    else:
        instructions = re.fullmatch(
            r"(.*?)^developer_instructions = '''\n(.*?)'''\n",
            text,
            re.DOTALL | re.MULTILINE,
        )
        if instructions is None or "'''" in instructions.group(2):
            problem(problems, path, "expected developer_instructions = '''...''' ending the file")
            return None
        header, body = instructions.groups()
        names = re.findall(r'^name = "([^"\n]+)"$', header, re.MULTILINE)
        # Codex names use underscores for both the prefix and the role slug.
        expected_name = "factory_" + slug.replace("-", "_")

    if names != [expected_name]:
        problem(problems, path, "expected name {}".format(expected_name))

    preamble, separator, role_text = body.partition("\n---\n")
    if not separator or not role_text.startswith("# "):
        problem(problems, path, "expected preamble closing --- followed by the role heading")
        return None
    first_line = re.match(r"\AYou are the ([^\n]+) role of WholeTeam\.", preamble)
    if first_line is None:
        problem(problems, path, "expected role display name in the preamble's first line")
        return None
    start, end = first_line.span(1)
    preamble = preamble[:start] + "<ROLE>" + preamble[end:]
    return preamble, role_text


def first_differing_line(expected, actual):
    for number, (left, right) in enumerate(
        zip_longest(expected.splitlines(keepends=True), actual.splitlines(keepends=True)),
        1,
    ):
        if left != right:
            return number


def main():
    problems = []
    for directory in (ROLES,) + tuple(directory for directory, _ in AGENTS):
        if not directory.is_dir():
            problem(problems, directory, "missing directory")

    roles = {path.stem: path for path in sorted(ROLES.glob("*.md"))}
    role_texts = {}
    for slug, path in roles.items():
        role_texts[slug] = read_text(path, problems)
        if role_texts[slug] is not None and "'''" in role_texts[slug]:
            problem(problems, path, "contains '''; unsafe in a Codex TOML literal string")
    roles.pop("orchestrator", None)  # The main session intentionally has no agent.
    preambles = []
    agent_count = 0
    for directory, suffix in AGENTS:
        for path in sorted(directory.glob("factory-*")):
            slug = path.stem[len("factory-"):]
            if slug not in roles:
                problem(problems, path, "no matching role file (stale agent)")
            elif path.suffix != suffix:
                problem(problems, path, "unexpected agent extension; expected {}".format(suffix))

    for slug, role_path in roles.items():
        role_text = role_texts[slug]
        for directory, suffix in AGENTS:
            path = directory / ("factory-" + slug + suffix)
            if not path.is_file():
                problem(problems, path, "missing agent for {}".format(role_path.relative_to(ROOT)))
                continue
            agent_count += 1
            text = read_text(path, problems)
            if text is None:
                continue
            extracted = extract_agent(path, text, slug, problems)
            if extracted is None:
                continue
            preamble, embedded = extracted
            preambles.append((path, preamble))
            # All current copies include the same final newline: tolerate no
            # trailing newline difference, extra blank lines or other whitespace.
            if role_text is not None and embedded != role_text:
                line = first_differing_line(role_text, embedded)
                problem(problems, path, "role text differs from {} at line {}".format(
                    role_path.relative_to(ROOT), line))

    if preambles:
        majority, count = Counter(value for _, value in preambles).most_common(1)[0]
        for path, value in preambles:
            if count * 2 <= len(preambles):
                problem(problems, path, "preamble has no majority to compare against")
            elif value != majority:
                problem(problems, path, "preamble differs from the majority at line {}".format(
                    first_differing_line(majority, value)))

    config_path = ROOT / "template/factory/config.yaml"
    defaults_path = ROOT / "template/factory/core/config.defaults.yaml"
    config = read_bytes(config_path, problems)
    defaults = read_bytes(defaults_path, problems)
    if config is not None and defaults is not None and config != defaults:
        problem(problems, config_path, "bytes differ from {}".format(defaults_path.relative_to(ROOT)))

    if problems:
        print("\n".join(problems))
        return 1
    print("OK: {} roles, {} agents, config in sync".format(len(roles), agent_count))
    return 0


if __name__ == "__main__":
    sys.exit(main())
