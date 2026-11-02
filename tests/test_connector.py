"""Run on macOS: python3 -m unittest discover -s tests -v.

Protocol tests use the real compiled host. Installer tests substitute the compiler
and downloader to exercise installation and failure handling without network or GUI.
"""
import json
import os
from pathlib import Path
import struct
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


def frame(value):
    body = json.dumps(value).encode()
    return struct.pack('=I', len(body)) + body


def responses(data):
    result = []
    while data:
        assert len(data) >= 4, 'Unframed output'
        length = struct.unpack('=I', data[:4])[0]
        assert len(data) >= 4 + length, 'Truncated output'
        result.append(json.loads(data[4:4 + length]))
        data = data[4 + length:]
    return result


class ConnectorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workspace = tempfile.TemporaryDirectory()
        cls.binary = Path(cls.workspace.name) / 'macshare_host'
        subprocess.run(['swiftc', '-module-cache-path', str(Path(cls.workspace.name) / 'cache'),
                        str(ROOT / 'macshare.swift'), '-o', str(cls.binary)], check=True)

    @classmethod
    def tearDownClass(cls):
        cls.workspace.cleanup()

    def call_host(self, payload):
        proc = subprocess.run([str(self.binary)], input=payload, capture_output=True, timeout=10)
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(proc.stderr, b'')
        return responses(proc.stdout)

    def test_multiple_messages_and_long_utf8_payload(self):
        messages = [{'url': 'file:///private/test'}, {'url': 'javascript:alert(1)'},
                    {'url': 'invalid-' + '界' * 300}]
        result = self.call_host(b''.join(map(frame, messages)))
        self.assertEqual([r['status'] for r in result], ['error'] * len(messages))

    def test_malformed_json(self):
        self.assertEqual(self.call_host(struct.pack('=I', 2) + b'xx')[0]['status'], 'error')

    def test_invalid_lengths_and_truncated_body(self):
        for payload in [struct.pack('=I', 0), struct.pack('=I', 1024 * 1024 + 1),
                        struct.pack('=I', 50) + b'{}']:
            with self.subTest(payload=payload):
                self.assertEqual(self.call_host(payload)[0]['status'], 'error')

    def test_manifest_escapes_paths(self):
        path = '/Users/test/Library/Application Support/"quoted"/host'
        data = subprocess.check_output([str(self.binary), '--manifest', path, 'a' * 32])
        config = json.loads(data)
        self.assertEqual(config['path'], path)
        self.assertEqual(config['allowed_origins'], ['chrome-extension://' + 'a' * 32 + '/'])

    def installer(self, home, *args, fail_compile=False, fail_download=False, stdin=False):
        tools = home / 'tools'
        tools.mkdir(exist_ok=True)
        compiler = tools / 'swiftc'
        compiler.write_text('#!/bin/bash\n[ "${FAIL_COMPILE:-}" != 1 ] || exit 42\n'
                            'while [ "$#" -gt 0 ]; do\n'
                            'if [ "$1" = -o ]; then cp "$TEST_BINARY" "$2"; exit; fi\nshift\ndone\nexit 1\n')
        downloader = tools / 'curl'
        downloader.write_text('#!/bin/bash\n[ "${FAIL_DOWNLOAD:-}" != 1 ] || exit 22\n'
                              'while [ "$#" -gt 0 ]; do\n'
                              'if [ "$1" = -o ]; then cp "$TEST_SOURCE" "$2"; exit; fi\nshift\ndone\nexit 1\n')
        compiler.chmod(0o755)
        downloader.chmod(0o755)
        env = dict(os.environ, HOME=str(home), PATH=str(tools) + ':' + os.environ['PATH'],
                   TEST_BINARY=str(self.binary), TEST_SOURCE=str(ROOT / 'macshare.swift'),
                   FAIL_COMPILE='1' if fail_compile else '0', FAIL_DOWNLOAD='1' if fail_download else '0')
        command = ['bash', '-s', '--'] if stdin else ['bash', str(ROOT / 'install.sh')]
        return subprocess.run(command + list(args), input=(ROOT / 'install.sh').read_bytes() if stdin else None,
                              cwd=home, env=env, capture_output=True, timeout=15)

    def test_fresh_streamed_install_and_backup(self):
        with tempfile.TemporaryDirectory(prefix='reeder home ') as directory:
            home = Path(directory)
            result = self.installer(home, stdin=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            support = home / 'Library/Application Support'
            manifest = support / 'Google/Chrome/NativeMessagingHosts/com.reeder.macshare.json'
            config = json.loads(manifest.read_text())
            self.assertEqual(config['path'], str(support / 'ReederChromeConnector/macshare_host'))
            self.assertNotIn('__EXTENSION_ID__', manifest.read_text())
            original = manifest.read_bytes()
            result = self.installer(home, '--source-dir', str(ROOT))
            self.assertEqual(result.returncode, 0, result.stderr)
            backups = list((support / 'ReederChromeConnector').glob('backup.*/com.reeder.macshare.json'))
            self.assertEqual(len(backups), 1)
            self.assertEqual(backups[0].read_bytes(), original)
            self.assertFalse((support / 'BraveSoftware').exists())

    def test_custom_id_and_browser(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            result = self.installer(home, '--source-dir', str(ROOT), '--browser', 'edge', '--extension-id', 'a' * 32)
            self.assertEqual(result.returncode, 0, result.stderr)
            config = json.loads((home / 'Library/Application Support/Microsoft Edge/NativeMessagingHosts/com.reeder.macshare.json').read_text())
            self.assertEqual(config['allowed_origins'], ['chrome-extension://' + 'a' * 32 + '/'])

    def test_failures_preserve_existing_installation(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            self.assertEqual(self.installer(home).returncode, 0)
            binary = home / 'Library/Application Support/ReederChromeConnector/macshare_host'
            original = binary.read_bytes()
            for options in [dict(fail_compile=True), dict(fail_download=True)]:
                self.assertNotEqual(self.installer(home, **options).returncode, 0)
                self.assertEqual(binary.read_bytes(), original)
            self.assertNotEqual(self.installer(home, '--extension-id', 'invalid').returncode, 0)
            self.assertNotEqual(self.installer(home, '--browser', 'unknown').returncode, 0)


if __name__ == '__main__':
    unittest.main()
