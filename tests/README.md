# Installer regression tests

Run from the WholeTeam repository with Python 3.8+ and git. Python is only a test dependency; the installers still require only their shell, git, and the existing system utilities.

```sh
python3 tests/test_installers.py --shell bash
python3 tests/test_installers.py --shell /bin/bash --shell pwsh
```

On Windows, run the suite against Windows PowerShell 5.1 and PowerShell 7:

```powershell
python tests/test_installers.py --shell powershell --shell pwsh
```

Each test installs into a disposable git repository, prepares a different replacement version, then runs the real installer. Fault wrappers inject failed copies, incomplete copies reporting success, failed promotions, terminated processes, and failed or interrupted recovery. Tests compare file bytes, permissions, and links, including project data and unrelated agent files, and check that a running update is protected from another invocation. Supplying both Bash and PowerShell also tests recovery using the other installer. No test modifies the source repository or downloads dependencies.
