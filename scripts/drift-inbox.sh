#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

HOSTNAME_OVERRIDE=""

usage() {
  cat <<'EOF'
Usage: scripts/drift-inbox.sh [--host HOSTNAME]

Report live workstation drift against the current alan-chezmoi model:
- manual apt packages that are not modeled for the selected host
- modeled apt packages that are not currently installed
- global npm tools that are installed but not modeled
- modeled global npm tools that are not currently installed
- VS Code extensions that are installed but not modeled
- modeled VS Code extensions that are not currently installed

By default the selected host is the current short hostname.
EOF
}

while (($# > 0)); do
  case "$1" in
    --host)
      HOSTNAME_OVERRIDE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

python3 - "$REPO_ROOT" "$HOSTNAME_OVERRIDE" <<'PY'
import socket
import subprocess
import sys
from pathlib import Path

import yaml


IGNORED_PACKAGE_NAMES = {
    "acl",
    "adduser",
    "apt",
    "apt-transport-https",
    "apt-listchanges",
    "apt-utils",
    "asciidoc",
    "b43-fwcutter",
    "base-files",
    "base-passwd",
    "bash",
    "bind9-dnsutils",
    "bind9-host",
    "bsdutils",
    "build-essential",
    "busybox",
    "bzip2",
    "ca-certificates",
    "chezmoi",
    "cmake",
    "console-setup",
    "coreutils",
    "cpio",
    "cron",
    "cron-daemon-common",
    "dash",
    "dbus",
    "debconf",
    "debconf-i18n",
    "debhelper",
    "debian-archive-keyring",
    "debian-faq",
    "debianutils",
    "dhcpcd-base",
    "diffutils",
    "dmidecode",
    "doc-debian",
    "docbook-xsl",
    "dosfstools",
    "dpkg",
    "dpkg-dev",
    "e2fsprogs",
    "fdisk",
    "file",
    "findutils",
    "firmware-intel-graphics",
    "firmware-iwlwifi",
    "firmware-realtek",
    "firmware-sof-signed",
    "gawk",
    "gcc-14-base",
    "gettext-base",
    "gnupg",
    "gpg",
    "grep",
    "groff-base",
    "grub-common",
    "grub-efi-amd64",
    "gzip",
    "hostname",
    "ifupdown",
    "inetutils-telnet",
    "init",
    "init-system-helpers",
    "initramfs-tools",
    "installation-report",
    "intel-microcode",
    "iproute2",
    "iputils-ping",
    "iw",
    "keyboard-configuration",
    "kmod",
    "krb5-locales",
    "laptop-detect",
    "less",
    "linux-image-amd64",
    "linux-sysctl-defaults",
    "locales",
    "login",
    "login.defs",
    "logrotate",
    "logsave",
    "lsof",
    "make",
    "man-db",
    "manpages",
    "mawk",
    "media-types",
    "mount",
    "nano",
    "ncurses-base",
    "ncurses-bin",
    "ncurses-term",
    "netbase",
    "openssh-client",
    "openssh-server",
    "openssl-provider-legacy",
    "os-prober",
    "passwd",
    "pciutils",
    "perl",
    "perl-base",
    "pkg-config",
    "procps",
    "python3",
    "python3-apt",
    "python3-psutil",
    "python3-venv",
    "python3-yaml",
    "quilt",
    "readline-common",
    "reportbug",
    "rsync",
    "sed",
    "sensible-utils",
    "shim-signed",
    "sqv",
    "sudo",
    "systemd",
    "systemd-sysv",
    "systemd-timesyncd",
    "sysvinit-utils",
    "tar",
    "task-english",
    "task-laptop",
    "tasksel",
    "traceroute",
    "tzdata",
    "ucf",
    "udev",
    "unzip",
    "usbutils",
    "util-linux",
    "util-linux-extra",
    "vim-common",
    "vim-tiny",
    "wamerican",
    "wget",
    "whiptail",
    "wtmpdb",
    "xsltproc",
    "xz-utils",
    "zip",
    "zlib1g",
    "zstd",
}


def read_yaml(path: Path):
    return yaml.safe_load(path.read_text())


def run_lines(cmd: list[str]) -> set[str]:
    return {
        line.strip()
        for line in subprocess.check_output(cmd, text=True).splitlines()
        if line.strip()
    }


def main() -> int:
    repo_root = Path(sys.argv[1])
    host_override = sys.argv[2].strip()
    hostname = host_override or socket.gethostname().split(".", 1)[0]

    packages = read_yaml(repo_root / ".chezmoidata/packages.yaml")["packages"]["linux"]
    vscode = read_yaml(repo_root / ".chezmoidata/vscode.yaml")["vscode"]

    host = packages.get("hosts", {}).get(hostname, {})
    desktop_family = host.get("desktop_family", "none")
    roles = host.get("roles", []) or []

    modeled_packages: list[str] = []
    modeled_packages.extend(packages.get("apt_core_common", []) or [])
    modeled_packages.extend(packages.get("apt_gui_common", []) or [])
    modeled_packages.extend(packages.get("external_deb_common", []) or [])
    modeled_packages.extend(packages.get("desktop_packages", {}).get(desktop_family, []) or [])
    for role_name in roles:
        modeled_packages.extend(packages.get("role_packages", {}).get(role_name, []) or [])
    modeled_packages.extend(host.get("apt_extra", []) or [])

    modeled_package_set = set(modeled_packages)
    manual_packages = run_lines(["bash", "-lc", "apt-mark showmanual | sort"])
    installed_vscode_extensions = (
        run_lines(["bash", "-lc", "code --list-extensions | sort"])
        if subprocess.run(
            ["bash", "-lc", "command -v code >/dev/null 2>&1"],
            check=False,
        ).returncode == 0
        else set()
    )
    installed_npm_tools = (
        {
            line.strip()
            for line in subprocess.check_output(
                [
                    "python3",
                    "-c",
                    "\n".join(
                        [
                            "import json, subprocess",
                            "data = json.loads(subprocess.check_output(['npm', '-g', 'ls', '--depth=0', '--json'], text=True))",
                            "for name in sorted((data.get('dependencies') or {}).keys()):",
                            "    print(name)",
                        ]
                    ),
                ],
                text=True,
            ).splitlines()
            if line.strip()
        }
        if subprocess.run(
            ["bash", "-lc", "command -v npm >/dev/null 2>&1"],
            check=False,
        ).returncode == 0
        else set()
    )
    modeled_npm_tools = {
        package["name"]
        for package in (packages.get("npm_global_tools", []) or [])
        if package.get("name")
    }
    modeled_vscode_extensions = set(vscode.get("extensions", []) or [])

    extra_packages = sorted(
        pkg
        for pkg in (manual_packages - modeled_package_set)
        if pkg not in IGNORED_PACKAGE_NAMES and not pkg.startswith("lib")
    )
    missing_packages = sorted(modeled_package_set - manual_packages)
    extra_npm_tools = sorted(installed_npm_tools - modeled_npm_tools)
    missing_npm_tools = sorted(modeled_npm_tools - installed_npm_tools)
    extra_extensions = sorted(installed_vscode_extensions - modeled_vscode_extensions)
    missing_extensions = sorted(modeled_vscode_extensions - installed_vscode_extensions)

    print(f"Host: {hostname}")
    print()

    def print_section(title: str, items: list[str]) -> None:
        print(title)
        if items:
            for item in items:
                print(f"- {item}")
        else:
            print("(none)")
        print()

    print_section("Manual packages not modeled", extra_packages)
    print_section("Modeled packages not installed", missing_packages)
    if installed_npm_tools or modeled_npm_tools:
        print_section("Global npm tools installed but not modeled", extra_npm_tools)
        print_section("Modeled global npm tools not installed", missing_npm_tools)
    else:
        print("Global npm tool drift")
        print("(npm not installed and no global npm tools modeled)")
        print()

    if installed_vscode_extensions or modeled_vscode_extensions:
        print_section("VS Code extensions installed but not modeled", extra_extensions)
        print_section("Modeled VS Code extensions not installed", missing_extensions)
    else:
        print("VS Code extension drift")
        print("(VS Code not installed and no extensions modeled)")
        print()

    return 0


raise SystemExit(main())
PY
