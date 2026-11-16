"""Offline end-to-end repository install and lifecycle tests."""
import hashlib
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
MAKES = Path(os.environ.get('IN1_MAKES_REPO', ROOT / 'repos/makes')).resolve()


class RepositoryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.state = self.base / 'state'
        self.prefix = self.base / 'prefix with spaces'
        self.makes = self.state / 'makes'
        self.makes.mkdir(parents=True)
        # Use the real module, installer, and CLI with a private dependency stub.
        for path in MAKES.glob('*.mk'):
            if path.name != 'python.mk':
                (self.makes / path.name).symlink_to(path)
        (self.makes / 'python.mk').write_text(
            '$(eval $(call include-local))\nPYTHON := ' + sys.executable + '\n')
        (self.makes / 'util').mkdir()
        (self.makes / 'util/github-release.py').write_text('''
import io, json, os, runpy
from pathlib import Path
from urllib.parse import urlparse
module = runpy.run_path(os.environ['IN1_TEST_HELPER'])
original = module['urllib'].request.urlopen
def urlopen(request, **kwargs):
    url = request.full_url
    if url.startswith('https://api.github.com/repos/'):
        repo = url.split('/repos/')[1].split('/releases/')[0]
        tag = url.rsplit('/', 1)[1]
        if tag == 'latest':
            tag = 'v2'
        if tag == 'missing':
            raise OSError('Release not found')
        assets = json.loads(Path(os.environ['IN1_TEST_ASSETS']).read_text())
        return io.BytesIO(json.dumps({'tag_name': tag, 'assets': assets}).encode())
    return open(os.environ['IN1_TEST_ARCHIVE'], 'rb')
module['urllib'].request.urlopen = urlopen
module['main']()
''')
        archive = self.base / 'tools.tar.gz'
        binary = Path(shutil.which('echo')).read_bytes()
        with tarfile.open(archive, 'w:gz') as output:
            for name in ('pkg/bin/echo', 'pkg/bin/printf'):
                binary = Path(shutil.which(Path(name).name)).read_bytes()
                member = tarfile.TarInfo(name)
                member.mode = 0o755
                member.size = len(binary)
                output.addfile(member, io.BytesIO(binary))
        self.assets = self.base / 'assets.json'
        self.assets.write_text(json.dumps([{
            'name': 'tools-linux-amd64.tar.gz',
            'browser_download_url': 'https://github.com/example/tools/releases/download/v2/tools',
            'digest': 'sha256:' + hashlib.sha256(archive.read_bytes()).hexdigest(),
        }]))
        self.env = {k: v for k, v in os.environ.items() if not k.startswith('IN1_')}
        for name in ('MAKEFLAGS', 'MFLAGS', 'MAKELEVEL', 'GNUMAKEFLAGS',
                     'MAKEOVERRIDES', 'BASH_ENV', 'ENV', 'MAKES_LOCAL_DIR'):
            self.env.pop(name, None)
        self.env.update({
            'IN1_ROOT': str(self.state), 'IN1_OFFLINE': '1',
            'PREFIX': str(self.prefix), 'TMPDIR': str(self.base),
            'IN1_TEST_HELPER': str(MAKES / 'util/github-release.py'),
            'IN1_TEST_ASSETS': str(self.assets),
            'IN1_TEST_ARCHIVE': str(archive),
        })
        # Exercise --asset in fixtures to be independent of the host platform.
        self.asset = 'tools-linux-amd64.tar.gz'
        bootstrap_state = self.prefix / 'share/in-1/local'
        bootstrap_state.mkdir(parents=True)
        (bootstrap_state / 'makes').symlink_to(self.makes)
        bootstrap = self.base / 'in-1/bootstrap'
        (bootstrap / 'bin').mkdir(parents=True)
        (bootstrap / 'bin/in-1').symlink_to(ROOT / 'bin/in-1')
        for name in ('share', '.rc', 'rc', 'man'):
            (bootstrap / name).symlink_to(ROOT / name)

    def run_cli(self, *args, ok=True):
        result = subprocess.run([str(ROOT / 'bin/in-1'), *args], env=self.env,
                                capture_output=True, text=True)
        if ok:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout)
        return result

    def install(self, selector='example/tools', **kwargs):
        return self.run_cli('--asset', self.asset, selector, **kwargs)

    def command(self, name, *args):
        return subprocess.check_output([str(self.prefix / 'bin' / name), *args], text=True)

    def test_install_show_uninstall(self):
        self.install()
        self.assertEqual(self.command('echo', 'works'), 'works\n')
        self.assertEqual(self.command('printf', 'also\n'), 'also\n')
        self.assertTrue((self.prefix / 'bin/echo+github+example+tools+v2').exists())
        shown = self.run_cli('--show', 'example/tools').stdout
        self.assertIn('example/tools', shown)
        self.assertIn('v2', shown)
        self.assertNotIn('github+example+tools  ', shown)
        # Lifecycle operations must work without Makes or GitHub access.
        shutil.rmtree(self.makes)
        self.run_cli('--uninstall', 'example/tools')
        self.assertFalse((self.prefix / 'bin/echo').exists())

    def test_switch_prune_and_exact_uninstall(self):
        self.install('example/tools@v1')
        self.install()
        self.install('example/tools@v1')
        self.run_cli('--prune', 'example/tools')
        root = self.prefix / 'share/github+example+tools'
        self.assertEqual([p.name for p in root.iterdir()], ['v1'])
        self.assertIn('v1', os.readlink(self.prefix / 'bin/echo'))
        self.run_cli('--uninstall', 'example/tools@v1')
        self.assertFalse(root.exists())

    def test_last_repository_wins(self):
        self.install('first/tools@v1')
        self.install('second/tools@v1')
        self.assertIn('github+second+tools', os.readlink(self.prefix / 'bin/echo'))
        self.assertTrue((self.prefix / 'bin/echo+github+first+tools+v1').exists())
        self.run_cli('--uninstall', 'first/tools')
        self.assertEqual(self.command('echo', 'still works'), 'still works\n')

    def test_unmanaged_conflict(self):
        (self.prefix / 'bin').mkdir(parents=True)
        foreign = self.prefix / 'bin/printf'
        foreign.write_text('unmanaged\n')
        self.install(ok=False)
        self.assertEqual(foreign.read_text(), 'unmanaged\n')
        self.assertFalse((self.prefix / 'bin/echo').exists())

    def test_bad_release_keeps_active(self):
        self.install('example/tools@v1')
        self.install('example/tools@missing', ok=False)
        assets = json.loads(self.assets.read_text())
        assets[0]['digest'] = 'sha256:' + '0' * 64
        self.assets.write_text(json.dumps(assets))
        self.install(ok=False)
        self.assertIn('v1', os.readlink(self.prefix / 'bin/echo'))
        self.assertFalse((self.prefix / 'share/github+example+tools/v2').exists())

    def test_reset(self):
        self.install()
        self.run_cli('--reset')
        self.assertFalse((self.prefix / 'bin/echo').exists())
        self.assertFalse((self.prefix / 'share/github+example+tools').exists())

    def test_selector_validation(self):
        for selector in ('../tools', 'owner/repo/extra', 'a/b@../bad',
                         'github+owner+repo', 'owner/repo@'):
            with self.subTest(selector=selector):
                self.install(selector, ok=False)
        self.run_cli('--asset', self.asset, 'example/tools', 'other/tools', ok=False)
        self.run_cli('--asset', self.asset, '--show', ok=False)
        self.run_cli('--prune', 'example/tools@v1', ok=False)

    def test_sourced_shells(self):
        # Bootstrap chooses its state under PREFIX. Makes state paths must not
        # contain spaces; direct repository prefix coverage above is separate.
        self.prefix = self.base / 'source-prefix'
        self.env['PREFIX'] = str(self.prefix)
        state = self.prefix / 'share/in-1/local'
        state.mkdir(parents=True)
        (state / 'makes').symlink_to(self.makes)
        for shell in ('bash', 'zsh', 'fish'):
            executable = shutil.which(shell)
            if not executable:
                continue
            with self.subTest(shell=shell):
                if shell == 'fish':
                    code = (f"source '{ROOT / 'rc'}' --asset {self.asset} example/tools; "
                            'or exit 1; command echo sourced')
                    args = [executable, '--no-config', '-c', code]
                else:
                    code = (f"source '{ROOT / 'rc'}' --asset {self.asset} example/tools "
                            '|| exit; command echo sourced')
                    args = [executable, '-c', code]
                result = subprocess.run(args, env=self.env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, 'sourced\n')

    def test_sourced_command_function(self):
        for shell in ('bash', 'zsh', 'fish'):
            executable = shutil.which(shell)
            if not executable:
                continue
            with self.subTest(shell=shell):
                code = (f"source '{ROOT / '.rc'}'; "
                        f'in-1 --asset {self.asset} example/tools; '
                        'command echo "$IN1_TOOLS"')
                args = [executable]
                if shell == 'fish':
                    args.append('--no-config')
                result = subprocess.run([*args, '-c', code], env=self.env,
                                        capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, 'example/tools\n')

    def test_quiet_install(self):
        result = self.run_cli('-q', '--asset', self.asset, 'example/tools')
        self.assertEqual(result.stdout, '')
        self.assertEqual(result.stderr, '')

    def test_mixed_catalog_and_repo(self):
        # Existing catalog Make recipes require a prefix without spaces.
        self.prefix = self.base / 'mixed-prefix'
        self.env['PREFIX'] = str(self.prefix)
        (self.makes / 'fixture.mk').write_text('''
FIXTURE-VERSION := 1
$(eval $(call include-local))
SHELL-DEPS += $(LOCAL-BIN)/fixture
$(LOCAL-BIN)/fixture:
\tprintf '%s\\n' '#!/bin/sh' 'echo "$$@"' > $@
\tchmod +x $@
''')
        self.run_cli('--asset', self.asset, 'example/tools', 'fixture')
        self.assertEqual(self.command('fixture', 'catalog'), 'catalog\n')
        self.assertEqual(self.command('echo', 'repo'), 'repo\n')


if __name__ == '__main__':
    unittest.main()
