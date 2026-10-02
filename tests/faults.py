"""Fault injection for Bash installer subprocesses; never used by installers."""

import os
from pathlib import Path
import signal
import subprocess
import sys


operation, *arguments = sys.argv[1:]
paths = [value.replace('\\', '/') for value in arguments if not value.startswith('-')]
source, target = (paths[0], paths[-1]) if paths else ('', '')
fault = os.environ.get('WHOLETEAM_FAULT', '')
kind, _, location = fault.partition(':')
fired = Path(os.environ['WHOLETEAM_FAULT_FIRED'])

suffixes = {
    'core': '/factory/core',
    'claude': '/.claude/agents/factory-architect.md',
    'codex': '/.codex/agents/factory-architect.toml',
    'guide': '/AGENTS.md',
    'starter': '/new-starting-file.txt',
}
matches = False
if operation == 'cp' and kind in ('copy', 'corrupt', 'stage-interrupt', 'pause'):
    matches = source.endswith(suffixes[location])
elif operation == 'mv' and kind in ('move', 'interrupt'):
    matches = source.endswith('/new') and target.endswith(suffixes[location])
elif operation == 'mv' and kind in ('recover', 'recover-interrupt'):
    matches = source.endswith('/old') and target.endswith(suffixes[location])
elif operation == 'rm' and kind == 'cleanup-interrupt':
    matches = target.endswith('/.wholeteam-update')

if matches and not fired.exists():
    fired.write_text(fault)
    if kind == 'pause':
        import time
        while not fired.with_name('fault-release').exists():
            time.sleep(0.02)
    elif kind == 'corrupt':
        destination = Path(target)
        if Path(source).is_dir():
            destination.mkdir()
            (destination / 'FACTORY.md').write_text('Incomplete copy\n')
        else:
            destination.write_text('Incomplete copy\n')
        sys.exit(0)
    elif 'interrupt' in kind:
        if kind == 'cleanup-interrupt':
            # Simulate cleanup having removed some of the original backups.
            import shutil
            shutil.rmtree(Path(target) / 'entries' / '000001', ignore_errors=True)
        os.kill(os.getppid(), signal.SIGKILL)
        sys.exit(99)
    else:
        print('Injected ' + fault + ' failure', file=sys.stderr)
        sys.exit(73)

result = subprocess.run([os.environ['WHOLETEAM_REAL_' + operation.upper()]] + arguments)
sys.exit(result.returncode if result.returncode >= 0 else 128 - result.returncode)
