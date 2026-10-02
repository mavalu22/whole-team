"""Run real installers in disposable repositories with copy/move fault injection.

Requires Python 3 for tests only. Examples:
    python3 tests/test_installers.py --shell bash
    python tests/test_installers.py --shell powershell
    python3 tests/test_installers.py --shell /path/to/pwsh
"""

import argparse
import os
from pathlib import Path
import shlex
import shutil
import stat
import subprocess
import sys
import tempfile
import time
import unittest


REPOSITORY = Path(__file__).resolve().parents[1]


def snapshot(root):
    files = {}
    for path in root.rglob('*'):
        relative = path.relative_to(root)
        if relative.parts[0] == '.git' or '.wholeteam-update' in relative.parts:
            continue
        if path.is_symlink():
            files[relative.as_posix()] = ('link', os.readlink(path))
        elif path.is_file():
            files[relative.as_posix()] = (path.read_bytes(), stat.S_IMODE(path.stat().st_mode))
    return files


class InstallerTests(unittest.TestCase):
    shell = ''
    alternate_shell = ''

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='wholeteam-regression-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.source = self.base / 'source with spaces'
        self.project = self.base / 'project with spaces'
        self.source.mkdir()
        self.project.mkdir()
        for name in ('install.sh', 'install.ps1', 'VERSION'):
            shutil.copy2(REPOSITORY / name, self.source / name)
        shutil.copytree(REPOSITORY / 'template', self.source / 'template')
        self.git('init', '-q')
        self.write('CLAUDE.md', 'Tracked user instructions\n')
        self.write('AGENTS.md', 'User instructions before the block\n')
        self.write('.gitignore', '# User ignore rules\n/user-output/\n')
        self.git('add', 'CLAUDE.md', '.gitignore')
        self.assert_success(self.run_installer())
        self.git('add', '.gitignore')
        # Replace all project data with distinctive bytes; update must preserve it.
        for path in (self.project / 'factory').rglob('*'):
            relative = path.relative_to(self.project / 'factory')
            if path.is_file() and relative.parts[0] != 'core' and not path.name.startswith('.'):
                path.write_bytes(path.read_bytes() + b'\nUSER DATA\x00\r\n')
        for name in ('factory/user-notes.md', 'factory/.user-state',
                     'factory/input/user.txt', 'factory/output/result.txt',
                     'factory/attachments/evidence.txt', '.claude/agents/user-helper.md',
                     '.codex/agents/user-helper.toml', '.claude/settings.json', '.codex/config.toml'):
            self.write(name, 'User-owned contents\n')
        if os.name != 'nt':
            (self.project / 'factory/config.yaml').chmod(0o640)
            (self.project / 'AGENTS.md').chmod(0o640)
            (self.project / 'factory/output/user-link').symlink_to('../user-notes.md')
            # A dangling user link must not be overwritten by a starting file.
            (self.project / 'factory/dangling-starting-file.txt').symlink_to('user-missing-file')
        self.write('factory/core/retired-core.md', 'Retired managed file\n')
        for tool, extension in (('.claude', 'md'), ('.codex', 'toml')):
            self.write(tool + '/agents/factory-retired.' + extension, 'Retired agent\n')
            # Preserve local model edits if the transaction fails.
            agent = self.project / tool / 'agents' / ('factory-architect.' + extension)
            agent.write_bytes(agent.read_bytes() + b'\nCUSTOM MODEL\n')
        self.write('AGENTS.md', (self.project / 'AGENTS.md').read_text() + '\nUser instructions after the block\n')
        (self.project / 'factory/.models-sync-needed').unlink()
        self.before = snapshot(self.project)
        (self.source / 'VERSION').write_text('9.9.9\n')
        core = self.source / 'template/factory/core/FACTORY.md'
        core.write_bytes(core.read_bytes() + b'\nReplacement core\n')
        for tool, extension in (('.claude', 'md'), ('.codex', 'toml')):
            agent = self.source / 'template/root' / tool / 'agents' / ('factory-architect.' + extension)
            agent.write_bytes(agent.read_bytes() + b'\nReplacement agent\n')
        guide = self.source / 'template/root/AGENTS.md'
        guide.write_text(guide.read_text().replace('<!-- <<< whole-team <<< -->', 'Replacement instructions\n<!-- <<< whole-team <<< -->'))
        (self.source / 'template/factory/new-starting-file.txt').write_text('New starting file\n')
        if self.is_bash and os.name != 'nt':
            (self.source / 'template/factory/dangling-starting-file.txt').write_text('Starting file\n')
        self.fired = self.base / 'fault-fired'
        self.wrappers = self.base / 'bin'
        self.wrappers.mkdir()
        self.real_tools = {}
        if self.is_bash:
            for name in ('cp', 'mv', 'rm'):
                self.real_tools[name] = shutil.which(name)
                wrapper = self.wrappers / name
                wrapper.write_text('#!/bin/sh\nexec ' + shlex.quote(sys.executable) + ' ' +
                                   shlex.quote(str(REPOSITORY / 'tests/faults.py')) + ' ' + name + ' "$@"\n')
                wrapper.chmod(0o755)

    @property
    def is_bash(self):
        return 'bash' in Path(self.shell).name.lower()

    @property
    def journal(self):
        return self.project / 'factory/.wholeteam-update'

    def git(self, *arguments):
        return subprocess.run(['git', '-C', str(self.project)] + list(arguments),
                              check=True, capture_output=True, text=True)

    def write(self, relative, contents):
        path = self.project / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents)

    def run_installer(self, fault='', interactive=False, background=False):
        environment = dict(os.environ, WHOLETEAM_FAULT=fault)
        if fault:
            self.fired.unlink(missing_ok=True)
            environment.update(WHOLETEAM_FAULT_FIRED=str(self.fired))
        if self.is_bash:
            command = [self.shell, str(self.source / 'install.sh'), '--path', str(self.project)]
            if fault:
                environment['PATH'] = str(self.wrappers) + os.pathsep + environment['PATH']
                for name, tool in self.real_tools.items():
                    environment['WHOLETEAM_REAL_' + name.upper()] = tool
            if not interactive:
                command.append('--yes')
        else:
            command = [self.shell, '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File']
            if fault:
                command.append(str(REPOSITORY / 'tests/faults.ps1'))
                environment.update(WHOLETEAM_INSTALLER=str(self.source / 'install.ps1'),
                                   WHOLETEAM_PROJECT=str(self.project))
            else:
                command.extend([str(self.source / 'install.ps1'), '-Path', str(self.project)])
                if not interactive:
                    command.append('-Yes')
        if background:
            return subprocess.Popen(command, env=environment, stdin=subprocess.DEVNULL,
                                    stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        result = subprocess.run(command, env=environment, input='n\n' if interactive else '',
                                capture_output=True, text=True, timeout=90)
        if fault:
            self.assertTrue(self.fired.exists(), 'Fault did not fire: ' + fault + '\n' + result.stdout + result.stderr)
        return result

    def assert_success(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def assert_unchanged(self):
        self.assertEqual(snapshot(self.project), self.before)
        self.assertFalse(self.journal.exists())

    def assert_updated(self):
        self.assertFalse(self.journal.exists())
        self.assertEqual((self.project / 'factory/core/VERSION').read_text(), '9.9.9\n')
        expected_core = snapshot(self.source / 'template/factory/core')
        actual_core = snapshot(self.project / 'factory/core')
        del actual_core['VERSION']
        self.assertEqual(actual_core, expected_core)
        for tool, extension in (('.claude', 'md'), ('.codex', 'toml')):
            directory = self.project / tool / 'agents'
            expected = {p.name: p.read_bytes() for p in (self.source / 'template/root' / tool / 'agents').glob('factory-*.' + extension)}
            actual = {p.name: p.read_bytes() for p in directory.glob('factory-*.' + extension)}
            self.assertEqual(actual, expected)
        after = snapshot(self.project)
        mutable = {'AGENTS.md', 'CLAUDE.local.md', '.gitignore', 'factory/.install-manifest'}
        for name, contents in self.before.items():
            if name.startswith('factory/core/') or '/agents/factory-' in name or name in mutable:
                continue
            self.assertEqual(after.get(name), contents, 'User data changed: ' + name)
        guide = (self.project / 'AGENTS.md').read_text()
        self.assertTrue(guide.startswith('User instructions before the block\n'))
        self.assertTrue(guide.endswith('\nUser instructions after the block\n'))
        self.assertIn('Replacement instructions', guide)
        self.assertEqual(after['AGENTS.md'][1], self.before['AGENTS.md'][1])
        self.assertTrue((self.project / 'factory/.models-sync-needed').is_file())
        self.assertEqual((self.project / 'factory/new-starting-file.txt').read_text(), 'New starting file\n')

    def test_success_and_repeat_update(self):
        self.assert_success(self.run_installer())
        self.assert_updated()
        after = snapshot(self.project)
        self.assert_success(self.run_installer())
        self.assertEqual(snapshot(self.project), after)

    def test_running_update_is_not_recovered_by_another_invocation(self):
        process = self.run_installer('pause:core', background=True)
        try:
            deadline = time.monotonic() + 15
            while not self.fired.exists() and process.poll() is None and time.monotonic() < deadline:
                time.sleep(0.02)
            self.assertTrue(self.fired.exists(), 'First installer did not reach staging.')
            result = self.run_installer()
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('update is still running', result.stderr)
            self.assertTrue(self.journal.exists())
            self.assertEqual(snapshot(self.project), self.before)
        finally:
            (self.base / 'fault-release').touch()
            stdout, stderr = process.communicate(timeout=90)
        self.assertEqual(process.returncode, 0, stdout + stderr)
        self.assert_updated()

    def test_copy_failures_leave_previous_installation(self):
        for location in ('core', 'claude', 'codex', 'guide', 'starter'):
            with self.subTest(location=location):
                result = self.run_installer('copy:' + location)
                self.assertNotEqual(result.returncode, 0)
                self.assert_unchanged()
        self.assert_success(self.run_installer())
        self.assert_updated()

    def test_incomplete_copies_are_rejected(self):
        for location in ('core', 'claude', 'codex'):
            with self.subTest(location=location):
                result = self.run_installer('corrupt:' + location)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('validation failed', result.stderr)
                self.assert_unchanged()

    def test_promotion_failures_restore_all_files(self):
        for location in ('core', 'claude', 'codex', 'guide', 'starter'):
            with self.subTest(location=location):
                result = self.run_installer('move:' + location)
                self.assertNotEqual(result.returncode, 0)
                self.assert_unchanged()
        self.assert_success(self.run_installer())
        self.assert_updated()

    def test_interrupted_staging_is_discarded(self):
        result = self.run_installer('stage-interrupt:codex')
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(self.journal.exists())
        self.assertEqual(snapshot(self.project), self.before)
        self.assert_success(self.run_installer())
        self.assert_updated()

    def test_interrupted_core_recovers_before_version_detection(self):
        self.assertNotEqual(self.run_installer('interrupt:core').returncode, 0)
        self.assertFalse((self.project / 'factory/core/VERSION').exists())
        self.assertTrue((self.journal / 'entries/000001/old/VERSION').is_file())
        result = self.run_installer()
        self.assert_success(result)
        self.assertIn('previous WholeTeam version was restored', result.stdout)
        self.assert_updated()

    def test_interrupted_update_recovers_with_other_installer(self):
        if not self.alternate_shell:
            self.skipTest('Supply Bash and PowerShell with --shell to test shared recovery.')
        self.assertNotEqual(self.run_installer('interrupt:core').returncode, 0)
        self.shell = self.alternate_shell
        self.assert_success(self.run_installer(interactive=True))
        self.assert_unchanged()

    def test_interrupted_agents_recover_on_declined_update(self):
        self.assertNotEqual(self.run_installer('interrupt:codex').returncode, 0)
        self.assertEqual((self.project / 'factory/core/VERSION').read_text(), '9.9.9\n')
        self.assert_success(self.run_installer(interactive=True))
        self.assert_unchanged()

    def test_interrupted_root_files_recover_on_retry(self):
        self.assertNotEqual(self.run_installer('interrupt:starter').returncode, 0)
        # Root blocks, agent removals, manifest and sync marker have been promoted.
        self.assertIn('Replacement instructions', (self.project / 'AGENTS.md').read_text())
        self.assert_success(self.run_installer(interactive=True))
        self.assert_unchanged()

    def test_failed_recovery_keeps_backup_for_next_invocation(self):
        self.assertNotEqual(self.run_installer('interrupt:core').returncode, 0)
        self.assertNotEqual(self.run_installer('recover:core').returncode, 0)
        self.assertTrue((self.journal / 'entries/000001/old/VERSION').is_file())
        self.assert_success(self.run_installer())
        self.assert_updated()

    def test_interrupted_recovery_can_be_retried(self):
        self.assertNotEqual(self.run_installer('interrupt:starter').returncode, 0)
        self.assertNotEqual(self.run_installer('recover-interrupt:codex').returncode, 0)
        # The core has already been restored; retry must leave it intact.
        self.assertEqual((self.project / 'factory/core/VERSION').read_bytes(), self.before['factory/core/VERSION'][0])
        self.assert_success(self.run_installer(interactive=True))
        self.assert_unchanged()

    def test_interrupted_committed_cleanup_keeps_new_version(self):
        self.assertNotEqual(self.run_installer('cleanup-interrupt:').returncode, 0)
        self.assertTrue(self.journal.exists())
        self.assertFalse((self.journal / 'ready').exists())
        after = snapshot(self.project)
        self.assert_success(self.run_installer(interactive=True))
        self.assertEqual(snapshot(self.project), after)
        self.assert_updated()

    def test_invalid_template_leaves_old_version(self):
        (self.source / 'template/factory/core/FACTORY.md').unlink()
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('replacement core is missing', result.stderr)
        self.assert_unchanged()

    def test_empty_agent_template_leaves_old_version(self):
        for path in (self.source / 'template/root/.codex/agents').glob('*'):
            path.unlink()
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('agents are missing', result.stderr)
        self.assert_unchanged()

    def test_root_preflight_refusal_leaves_old_version(self):
        path = self.project / 'AGENTS.md'
        path.write_text(path.read_text().replace('<!-- <<< whole-team <<< -->', ''))
        self.before = snapshot(self.project)
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('incomplete WholeTeam block', result.stderr)
        self.assert_unchanged()

    def test_unrecognized_transaction_directory_is_preserved(self):
        self.journal.mkdir()
        (self.journal / 'user-file').write_text('Do not delete\n')
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((self.journal / 'user-file').read_text(), 'Do not delete\n')
        self.assertEqual(snapshot(self.project), self.before)

    def test_absolute_ignore_target_rolls_back_with_other_files(self):
        external = self.base / 'external ignore file'
        external.write_text('# User exclusions\n')
        manifest = self.project / 'factory/.install-manifest'
        manifest.write_text(manifest.read_text().replace('.gitignore', str(external)))
        self.before = snapshot(self.project)
        self.assertNotEqual(self.run_installer('move:starter').returncode, 0)
        self.assertEqual(external.read_text(), '# User exclusions\n')
        self.assert_unchanged()
        self.assert_success(self.run_installer())
        self.assertIn('# User exclusions\n', external.read_text())
        self.assertIn('# >>> whole-team >>>', external.read_text())


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--shell', action='append', help='Bash or PowerShell executable; may be repeated')
    arguments = parser.parse_args()
    shells = arguments.shell or [name for name in ('bash', 'pwsh', 'powershell') if shutil.which(name)]
    if not shells:
        parser.error('No installer shell found; use --shell <executable>.')
    suite = unittest.TestSuite()
    for shell in shells:
        executable = shutil.which(shell)
        if not executable:
            parser.error('Shell not found: ' + shell)
        case = type('InstallerTests_' + Path(shell).name, (InstallerTests,), {'shell': executable})
        alternatives = [shutil.which(other) for other in shells
                        if ('bash' in Path(other).name.lower()) != ('bash' in Path(shell).name.lower())]
        case.alternate_shell = next((other for other in alternatives if other), '')
        suite.addTests(unittest.defaultTestLoader.loadTestsFromTestCase(case))
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    sys.exit(not result.wasSuccessful())
