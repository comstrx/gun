use std::{fs, env, io, sync::OnceLock, path::PathBuf, io::IsTerminal};
use {semver::Version, regex::Regex, rustix::process};

use super::arch::{Manager, Path};

impl Manager {

    pub fn name () -> &'static str {

        Self::detect().map(|manager| manager.as_str()).unwrap_or_else(|_| "unknown")

    }

    pub fn os_name () -> &'static str {

        if cfg!(target_os = "linux") { "linux" }
        else if cfg!(target_os = "windows") { "windows" }
        else if cfg!(target_os = "macos") { "macos" }
        else { "another" }

    }

    pub fn os_distro () -> &'static str {

        #[cfg(target_os = "linux")]
        {
            let text = fs::read_to_string("/etc/os-release")
                .or_else(|_| fs::read_to_string("/usr/lib/os-release"))
                .unwrap_or_default();

            for line in text.lines() {

                let line = line.trim();
                if line.is_empty() || line.starts_with('#') { continue; }

                let Some((key, value)) = line.split_once('=') else { continue; };
                if key.trim() != "ID" { continue; }

                let value = value.trim().trim_matches('"').trim_matches('\'');

                return match value {
                    "ubuntu"              => "ubuntu",
                    "debian"              => "debian",
                    "fedora"              => "fedora",
                    "rhel"                => "rhel",
                    "centos"              => "centos",
                    "rocky"               => "rocky",
                    "almalinux"           => "almalinux",
                    "arch"                => "arch",
                    "manjaro"             => "manjaro",
                    "alpine"              => "alpine",
                    "opensuse-tumbleweed" => "opensuse-tumbleweed",
                    "opensuse-leap"       => "opensuse-leap",
                    "opensuse"            => "opensuse",
                    "sles"                => "sles",
                    "nixos"               => "nixos",
                    "void"                => "void",
                    "gentoo"              => "gentoo",
                    "pop"                 => "pop",
                    "linuxmint"           => "linuxmint",
                    "elementary"          => "elementary",
                    "kali"                => "kali",
                    "raspbian"            => "raspbian",
                    "ol"                  => "oraclelinux",
                    "amzn"                => "amazonlinux",
                    "clear-linux-os"      => "clearlinux",
                    "mariner"             => "mariner",
                    "azurelinux"          => "azurelinux",
                    _                     => "linux",
                };

            }

            "linux"
        }

        #[cfg(target_os = "macos")]
        {
            "macos"
        }

        #[cfg(target_os = "windows")]
        {
            "windows"
        }

        #[cfg(not(any(target_os = "linux", target_os = "macos", target_os = "windows")))]
        {
            "another"
        }

    }

    pub fn os_arch () -> String {

        os_info::get().architecture().unwrap_or("unknown").to_string()

    }

    pub fn os_version () -> String {

        os_info::get().version().to_string()

    }


    pub fn group_id () -> Option<u32> {

        #[cfg(unix)]
        {
            Some(process::getegid().as_raw())
        }

        #[cfg(not(unix))]
        {
            None
        }

    }

    pub fn user_id () -> Option<u32> {

        #[cfg(unix)]
        {
            Some(process::geteuid().as_raw())
        }

        #[cfg(not(unix))]
        {
            None
        }

    }

    pub fn user_name () -> Option<String> {

        whoami::username().ok().filter(|value| !value.trim().is_empty())

    }

    pub fn host_name () -> Option<String> {

        whoami::hostname().ok().map(|value| value.trim().to_string()).filter(|value| !value.is_empty())

    }

    pub fn path ( bin: &str ) -> Option<PathBuf> {

        if let Some(path) = Path::find_path(bin) { return Some(path); }

        if let Ok(spec) = Self::spec(bin) {

            if !spec.path.is_empty() {
                let path = PathBuf::from(spec.path);
                if path.is_file() { return Some(path); }
            }

            return Path::find_path(spec.bin);

        }

        None

    }

    pub fn version ( bin: &str ) -> Option<String> {

        static RE: OnceLock<Regex> = OnceLock::new();

        let regex = r"(?i)(?:^|[^0-9])(?:[a-z]+)?(\d+)\.(\d+)(?:\.(\d+))?([0-9a-z.+-]*)";
        let re = RE.get_or_init(|| Regex::new(regex).expect("invalid version regex"));

        let bin = Self::path(bin)
            .map(|path| path.to_string_lossy().into_owned())
            .unwrap_or_else(|| bin.to_string());

        for args in [&["--version"][..], &["-v"][..], &["-V"][..], &["version"][..]] {

            let output = match Self::run_capture(bin.as_str(), args) {
                Ok(output) => output,
                Err(_) => continue,
            };

            for text in [&output.stdout[..], &output.stderr[..]] {

                let text = String::from_utf8_lossy(text);

                if let Some(caps) = re.captures(&text) {

                    let major = &caps[1];
                    let minor = &caps[2];
                    let patch = caps.get(3).map_or("0", |m| m.as_str());
                    let tail  = caps.get(4).map_or("", |m| m.as_str()).trim_start_matches(['.', '-', '+']);

                    let pre = if tail.is_empty() { String::new() } else {

                        let tail = tail
                            .split(['.', '-', '+'])
                            .filter(|part| !part.is_empty())
                            .collect::<Vec<_>>()
                            .join(".");

                        if tail.is_empty() { String::new() }
                        else { format!("-{tail}") }

                    };

                    let version = format!("{major}.{minor}.{patch}{pre}");

                    if Version::parse(&version).is_ok() { return Some(version); }

                }

            }

        }

        None

    }


    pub fn is_windows () -> bool {

        cfg!(target_os = "windows")

    }

    pub fn is_macos () -> bool {

        cfg!(target_os = "macos")

    }

    pub fn is_linux () -> bool {

        cfg!(target_os = "linux")

    }

    pub fn is_unix () -> bool {

        cfg!(unix)

    }

    pub fn is_wsl () -> bool {

        if !Self::is_linux() { return false; }

        if env::var_os("WSL_DISTRO_NAME").is_some() { return true; }
        if env::var_os("WSL_INTEROP").is_some() { return true; }

        let has_microsoft = |path: &str| {
            fs::read_to_string(path)
                .map(|text| text.to_ascii_lowercase().contains("microsoft"))
                .unwrap_or(false)
        };

        has_microsoft("/proc/sys/kernel/osrelease") || has_microsoft("/proc/version")

    }

    pub fn is_vm () -> bool {

        #[cfg(any(target_arch = "x86", target_arch = "x86_64"))]
        {
            #[cfg(target_arch = "x86")]
            use std::arch::x86::__cpuid;

            #[cfg(target_arch = "x86_64")]
            use std::arch::x86_64::__cpuid;

            unsafe {
                let leaf = __cpuid(1);
                return (leaf.ecx & (1 << 31)) != 0;
            }
        }

        #[cfg(not(any(target_arch = "x86", target_arch = "x86_64")))]
        {
            false
        }

    }

    pub fn is_ci () -> bool {

        let has = |key: &str| std::env::var_os(key).is_some();

        has("CI")
            || has("GITHUB_ACTIONS")
            || has("GITLAB_CI")
            || has("CIRCLECI")
            || has("TRAVIS")
            || has("JENKINS_URL")
            || has("BUILDKITE")
            || has("TEAMCITY_VERSION")
            || has("TF_BUILD")
            || has("APPVEYOR")
            || has("DRONE")
            || has("BITBUCKET_BUILD_NUMBER")
            || has("CODEBUILD_BUILD_ID")

    }

    pub fn is_terminal () -> bool {

        io::stdin().is_terminal() && io::stdout().is_terminal()


    }

    pub fn is_container () -> bool {

        #[cfg(target_os = "linux")]
        {
            if std::path::Path::new("/.dockerenv").exists() { return true; }
            if std::path::Path::new("/run/.containerenv").exists() { return true; }
            if std::path::Path::new("/run/systemd/container").exists() { return true; }
            if env::var_os("container").is_some() { return true; }

            let has_marker = |path: &str| {
                fs::read_to_string(path)
                    .map(|text| {
                        let text = text.to_ascii_lowercase();

                        text.contains("docker")
                            || text.contains("podman")
                            || text.contains("containerd")
                            || text.contains("kubepods")
                            || text.contains("lxc")
                            || text.contains("libpod")
                    })
                    .unwrap_or(false)
            };

            has_marker("/proc/1/cgroup")
                || has_marker("/proc/self/cgroup")
                || has_marker("/proc/1/mountinfo")
        }

        #[cfg(not(target_os = "linux"))]
        {
            return false;
        }

    }

    pub fn is_root () -> bool {

        #[cfg(unix)]
        {
            return process::geteuid().as_raw() == 0;
        }

        #[cfg(windows)]
        {

            use windows_sys::Win32::Security::{AllocateAndInitializeSid, CheckTokenMembership, FreeSid, SECURITY_NT_AUTHORITY};
            use windows_sys::Win32::System::SystemServices::{DOMAIN_ALIAS_RID_ADMINS, SECURITY_BUILTIN_DOMAIN_RID};

            unsafe {

                let mut is_member = 0i32;
                let mut admin_group = std::ptr::null_mut();
                let nt_authority = SECURITY_NT_AUTHORITY;

                let ok = AllocateAndInitializeSid(
                    &nt_authority,
                    2,
                    SECURITY_BUILTIN_DOMAIN_RID as u32,
                    DOMAIN_ALIAS_RID_ADMINS as u32,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    &mut admin_group,
                );

                if ok == 0 || admin_group.is_null() { return false; }

                let result = CheckTokenMembership(std::ptr::null_mut(), admin_group, &mut is_member);
                let _ = FreeSid(admin_group);

                result != 0 && is_member != 0

            }

        }
    
    }

}
