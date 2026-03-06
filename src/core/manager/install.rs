use std::{path::PathBuf, process::Command};
use rand::distr::{Alphabetic, SampleString};
use os_info::Type;
use which::which;

use crate::core::error::{AppResult, AppError};
use super::base::Manager;

impl Manager {

    fn resolve_binary ( package: &str ) -> &str {

        match package.trim().to_ascii_lowercase().as_str() {
            "rust" | "rustc"                       => "rustc",
            "rustup"                               => "rustup",
            "cargo"                                => "cargo",
            "c" | "cc" | "cpp" | "c++" | "hpp"     => "clang",
            "zig"                                  => "zig",
            "mojo"                                 => "mojo",
            "pixi"                                 => "pixi",
            "go" | "golang"                        => "go",
            "dotnet" | "c#" | "csharp" | "cs"      => "dotnet",
            "dart"                                 => "dart",
            "node" | "npm" | "npx"                 => "node",
            "pnpm"                                 => "pnpm",
            "yarn"                                 => "yarn",
            "bun"                                  => "bun",
            "php"                                  => "php",
            "composer"                             => "composer",
            "python" | "python3" | "py" | "pip"    => "python",
            "uv"                                   => "uv",
            "lua"                                  => "lua",
            "luarocks"                             => "luarocks",
            "perl"                                 => "perl",
            "docker" | "docker-ce"                 => "docker",
            "kubectl" | "kubernetes" | "k8s"       => "kubectl",
            "minikube"                             => "minikube",
            "helm"                                 => "helm",
            "kind"                                 => "kind",
            "kustomize"                            => "kustomize",
            "argocd" | "argo" | "argo-cd"          => "argocd",
            "terraform" | "tf"                     => "terraform",
            "tofu" | "opentofu"                    => "tofu",
            "grafana"                              => "grafana",
            "loki"                                 => "loki",
            "prometheus" | "prom"                  => "prometheus",
            "otel" | "otelcol" | "opentelemetry"   => "otelcol",
            "git"                                  => "git",
            "gh" | "github"                        => "gh",
            "llvm" | "llvm-config"                 => "llvm-config",
            "curl"                                 => "curl",
            "unzip"                                => "unzip",
            "wrk"                                  => "wrk",
            "cmake"                                => "cmake",
            "xmake"                                => "xmake",
            "7z"                                   => "7z",
            "mise"                                 => "mise",
            "aqua"                                 => "aqua",
            "nix"                                  => "nix",
            _                                      => package,
        }

    }

    fn find_binary ( package: &str ) -> Option<PathBuf> {

        let mut paths = Vec::new();

        let bin = Self::resolve_binary(package);
        if let Ok(path) = which::which(bin) { return Some(path); }

        #[cfg(unix)]
        {
            if let Some(home) = Self::env_path("HOME") {
                paths.push(home.join(".local").join("bin").join(bin));
                paths.push(home.join(".cargo").join("bin").join(bin));
                paths.push(home.join(".nix-profile").join("bin").join(bin));
                paths.push(home.join(".local").join("share").join("mise").join("shims").join(bin));
                paths.push(home.join(".config").join("mise").join("shims").join(bin));
                paths.push(home.join(".local").join("share").join("aquaproj-aqua").join("bin").join(bin));
            }
        }

        #[cfg(target_os = "macos")]
        {
            let formula = match bin {
                "llvm-config" | "clang" => Some("llvm"),
                _                       => None,
            };

            if let Some(formula) = formula {
                let output = Command::new("brew").args(["--prefix", formula]).output().ok()?;

                if output.status.success() {
                    let prefix = String::from_utf8_lossy(&output.stdout).trim().to_string();

                    if !prefix.is_empty() {
                        let path = PathBuf::from(prefix).join("bin").join(bin);
                        if path.is_file() { return Some(path); }
                    }
                }
            }
        }

        #[cfg(windows)]
        {
            if let Some(local) = Self::env_path("LOCALAPPDATA") {
                paths.push(local.join("Microsoft").join("WinGet").join("Links").join(format!("{bin}.exe")));
                paths.push(local.join("mise").join("shims").join(format!("{bin}.exe")));
            }

            if let Some(user) = Self::env_path("USERPROFILE") {
                paths.push(user.join(".cargo").join("bin").join(format!("{bin}.exe")));
                paths.push(user.join("scoop").join("shims").join(format!("{bin}.exe")));
            }

            if let Some(program_data) = Self::env_path("ProgramData") {
                paths.push(program_data.join("chocolatey").join("bin").join(format!("{bin}.exe")));
            }
        }

        for path in paths {
            if path.is_file() {
                return Some(path);
            }
        }

        None

    }

    fn resolve_package ( manager: Manager, package: &str ) -> &str {

        match manager {
            Self::Brew => match package {
                "rustc"       => "rust",
                "cargo"       => "rust",
                "python"      => "python",
                "clang"       => "llvm",
                "7z"          => "sevenzip",
                "llvm-config" => "llvm",
                _             => package,
            },
            Self::Apt => match package {
                "node"        => "nodejs",
                "yarn"        => "yarnpkg",
                "python"      => "python3",
                "go"          => "golang-go",
                "7z"          => "7zip",
                "llvm-config" => "llvm",
                "lua"         => "lua5.4",
                _             => package,
            },
            Self::Dnf => match package {
                "rustc"       => "rust",
                "node"        => "nodejs",
                "yarn"        => "yarnpkg",
                "python"      => "python3",
                "go"          => "golang",
                "7z"          => "7zip",
                "llvm-config" => "llvm",
                _             => package,
            },
            Self::Yum => match package {
                "rustc"       => "rust",
                "node"        => "nodejs",
                "yarn"        => "yarnpkg",
                "python"      => "python3",
                "go"          => "golang",
                "7z"          => "7zip",
                "llvm-config" => "llvm",
                _             => package,
            },
            Self::Pacman => match package {
                "rustc"       => "rust",
                "cargo"       => "rust",
                "node"        => "nodejs",
                "gh"          => "github-cli",
                "7z"          => "7zip",
                "llvm-config" => "llvm",
                _             => package,
            },
            Self::Zypper => match package {
                "rustc"       => "rust",
                "node"        => "nodejs",
                "python"      => "python3",
                "7z"          => "7zip",
                "llvm-config" => "llvm",
                "lua"         => "lua54",
                "luarocks"    => "lua54-luarocks",
                _             => package,
            },
            Self::Apk => match package {
                "rustc"       => "rust",
                "node"        => "nodejs",
                "python"      => "python3",
                "7z"          => "7zip",
                "llvm-config" => "llvm",
                "lua"         => "lua5",
                "luarocks"    => "luarocks5",
                _             => package,
            },
            Self::Winget => match package {
                "rustup"      => "Rustlang.Rustup",
                "rustc"       => "Rustlang.Rustup",
                "cargo"       => "Rustlang.Rustup",
                "node"        => "OpenJS.NodeJS",
                "npm"         => "OpenJS.NodeJS",
                "pnpm"        => "pnpm.pnpm",
                "xmake"       => "Xmake-io.Xmake",
                "bun"         => "Oven-sh.Bun",
                "uv"          => "astral-sh.uv",
                "python"      => "Python.Python",
                "git"         => "Git.Git",
                "gh"          => "GitHub.cli",
                "go"          => "GoLang.Go",
                "clang"       => "LLVM.LLVM",
                "7z"          => "7zip.7zip",
                "cmake"       => "Kitware.CMake",
                "dart"        => "Google.DartSDK",
                "llvm-config" => "LLVM.LLVM",
                "lua"         => "DEVCOM.Lua",
                "luarocks"    => "DEVCOM.Lua",
                "unzip"       => "GnuWin32.UnZip",
                _             => package,
            },
            Self::Scoop => match package {
                "rustc"       => "rustup",
                "cargo"       => "rustup",
                "node"        => "nodejs",
                "npm"         => "nodejs",
                "clang"       => "llvm",
                "llvm-config" => "llvm",
                _             => package,
            },
            Self::Choco => match package {
                "rustup"      => "rustup.install",
                "rustc"       => "rustup.install",
                "cargo"       => "rustup.install",
                "node"        => "nodejs",
                "npm"         => "nodejs",
                "go"          => "golang",
                "clang"       => "llvm",
                "llvm-config" => "llvm",
                _             => package,
            },
        }

    }

    fn install_shell ( package: &str, url: &str, args: &[&str], bash: bool, sudo: bool ) -> AppResult<()> {

        match Self::detect()? {
            Self::Apt | Self::Dnf | Self::Yum | Self::Pacman | Self::Zypper | Self::Apk => {
                let name = Alphabetic.sample_string(&mut rand::rng(), 6).to_lowercase();
                let path = std::env::temp_dir().join(format!("installer-{name}"));

                let path = path.to_str().ok_or_else(|| AppError::message("failed to resolve installer path"))?;
                let cmd = if bash { "bash" } else { "sh" };
                let runner = if sudo { Self::sudo_run } else { Self::run };

                let result = (|| -> AppResult<()> {
                    Self::run("curl", &["-sSfL", url, "-o", path])?;
                    runner(cmd, &[&[path], args].concat())?;
                    Ok(())
                })();

                let _ = std::fs::remove_file(path);
                result
            }
            _ => Self::install_package(&[package], "_"),
        }

    }

    fn install_package ( packages: &[&str], source: &str ) -> AppResult<()> {

        let manager = Self::detect()?;

        for &package in packages {

            let package = if source == "_" { Self::resolve_package(manager, package) } else { package };

            match source {
                "aqua" => {
                    Self::run("mise", &["use", "--global", &format!("aqua:{package}")])?;
                },
                "repo" => {
                    Self::run("mise", &["use", "--global", &format!("github:{package}")])?;
                },
                "nix" => {
                    Self::run("nix", &["profile", "install", package])?;
                },
                _ => match manager {
                    Self::Apt    => Self::sudo_run("apt-get", &["install", "-y", package])?,
                    Self::Dnf    => Self::sudo_run("dnf", &["install", "-y", package])?,
                    Self::Yum    => Self::sudo_run("yum", &["install", "-y", package])?,
                    Self::Pacman => Self::sudo_run("pacman", &["-S", "--needed", "--noconfirm", "--noprogressbar", package])?,
                    Self::Zypper => Self::sudo_run("zypper", &["install", "-y", package])?,
                    Self::Apk    => Self::sudo_run("apk", &["add", package])?,
                    Self::Brew   => Self::run("brew", &["install", package])?,
                    Self::Scoop  => Self::run("scoop", &["install", package])?,
                    Self::Choco  => Self::run("choco", &["install", "-y", package])?,
                    Self::Winget => Self::run("winget", &["install", "-e", "--id", package, "--source", "winget", "--accept-package-agreements", "--accept-source-agreements", "--disable-interactivity"])?,
                },
            }

        }

        Ok(())

    }

    fn remove_package ( packages: &[&str], source: &str ) -> AppResult<()> {

        let manager = Self::detect()?;

        for &package in packages {

            let package = if source == "_" { Self::resolve_package(manager, package) } else { package };

            if source == "aqua" && which("mise").is_ok() {
                Self::run("mise", &["unuse", "--global", &format!("aqua:{package}")])?;
            }

            if source == "repo" && which("mise").is_ok() {
                Self::run("mise", &["unuse", "--global", &format!("github:{package}")])?;
            }

            if source == "nix" && which("nix").is_ok() {
                Self::run("nix", &["profile", "remove", package])?;
            }

            let _ = match manager {
                Self::Apt    => Self::sudo_run("apt-get", &["remove", "-y", package]),
                Self::Dnf    => Self::sudo_run("dnf", &["remove", "-y", package]),
                Self::Yum    => Self::sudo_run("yum", &["remove", "-y", package]),
                Self::Pacman => Self::sudo_run("pacman", &["-R", "--noconfirm", package]),
                Self::Zypper => Self::sudo_run("zypper", &["remove", "-y", package]),
                Self::Apk    => Self::sudo_run("apk", &["del", package]),
                Self::Brew   => Self::run("brew", &["uninstall", package]),
                Self::Scoop  => Self::run("scoop", &["uninstall", package]),
                Self::Choco  => Self::run("choco", &["uninstall", "-y", package]),
                Self::Winget => Self::run("winget", &["uninstall", "-e", "--id", package, "--source", "winget", "--disable-interactivity"]),
            };

        }

        Ok(())

    }


    pub fn has ( binary: &str ) -> bool {

        which(binary).is_ok()
        // Self::find_binary(binary).is_some()

    }

    pub fn need ( binary: &str ) -> AppResult<()> {

        if Self::has(binary) { Ok(()) }
        else { Err(AppError::missing_binary(binary)) }

    }

    pub fn install ( package: &str ) -> AppResult<()> {

        let bin = Self::resolve_binary(package);

        match bin {
            "kubectl"        => Self::install_package(&["nixpkgs#kubectl"], "nix"),
            "minikube"       => Self::install_package(&["minikube/minikube"], "aqua"),
            "helm"           => Self::install_package(&["helm/helm"], "aqua"),
            "kind"           => Self::install_package(&["kubernetes-sigs/kind"], "aqua"),
            "kustomize"      => Self::install_package(&["kubernetes-sigs/kustomize"], "aqua"),
            "argocd"         => Self::install_package(&["argoproj/argo-cd"], "aqua"),
            "terraform"      => Self::install_package(&["hashicorp/terraform"], "aqua"),
            "tofu"           => Self::install_package(&["opentofu/opentofu"], "aqua"),
            "grafana"        => Self::install_package(&["nixpkgs#grafana"], "nix"),
            "loki"           => Self::install_package(&["grafana/loki"], "repo"),
            "prometheus"     => Self::install_package(&["prometheus/prometheus"], "aqua"),
            "otelcol"        => Self::install_package(&["open-telemetry/opentelemetry-collector-releases"], "repo"),

            "bun"            => Self::install_shell("bun", "https://bun.sh/install", &[], true, false),
            "docker"         => Self::install_shell("docker", "https://get.docker.com", &[], false, true),
            "mise"           => Self::install_shell("mise", "https://mise.run/bash", &[], false, false),
            "nix"            => Self::install_shell("nix", "https://artifacts.nixos.org/nix-installer", &["install", "--no-confirm"], false, false),
            "aqua"           => Self::install_shell("aqua", "https://raw.githubusercontent.com/aquaproj/aqua-installer/v4.0.2/aqua-installer", &[], true, false),

            _                => Self::install_package(&[bin], "_"),
        }

    }

    pub fn remove ( package: &str ) -> AppResult<()> {

        let bin = Self::resolve_binary(package);

        match bin {
            "kubectl"        => Self::remove_package(&["nixpkgs#kubectl"], "nix"),
            "minikube"       => Self::remove_package(&["minikube/minikube"], "aqua"),
            "helm"           => Self::remove_package(&["helm/helm"], "aqua"),
            "kind"           => Self::remove_package(&["kubernetes-sigs/kind"], "aqua"),
            "kustomize"      => Self::remove_package(&["kubernetes-sigs/kustomize"], "aqua"),
            "argocd"         => Self::remove_package(&["argoproj/argo-cd"], "aqua"),
            "terraform"      => Self::remove_package(&["hashicorp/terraform"], "aqua"),
            "tofu"           => Self::remove_package(&["opentofu/opentofu"], "aqua"),
            "grafana"        => Self::remove_package(&["nixpkgs#grafana"], "nix"),
            "loki"           => Self::remove_package(&["grafana/loki"], "repo"),
            "prometheus"     => Self::remove_package(&["prometheus/prometheus"], "aqua"),
            "otelcol"        => Self::remove_package(&["open-telemetry/opentelemetry-collector-releases"], "repo"),

            "docker"         => Self::remove_package(&[
                "docker", "docker-ce", "docker-ce-cli", "containerd.io", "docker-buildx-plugin",
                "docker-compose-plugin", "docker-ce-rootless-extras"
            ], "_"),

            _                => Self::remove_package(&[bin], "_"),
        }

    }

    pub fn ensure ( package: &str ) -> AppResult<()> {

        if Self::has(package) { return Ok(()); }
        Self::install(package)
        // if !Self::has(package) { return Err(AppError::missing_binary(package)); }
        // Ok(())

    }

    pub fn upgrade ( package: &str ) -> AppResult<()> {

        Self::remove(package)?;
        Self::install(package)

    }


    pub fn has_all ( packages: &[&str] ) -> bool {

        packages.iter().all(|package| Self::has(package))

    }

    pub fn need_all ( packages: &[&str] ) -> AppResult<()> {

        for &package in packages { Self::need(package)?; }

        Ok(())

    }

    pub fn install_all ( packages: &[&str] ) -> AppResult<()> {

        for &package in packages { Self::install(package)?; }

        Ok(())

    }

    pub fn remove_all ( packages: &[&str] ) -> AppResult<()> {

        for &package in packages { Self::remove(package)?; }

        Ok(())

    }

    pub fn ensure_all ( packages: &[&str] ) -> AppResult<()> {

        for &package in packages { Self::ensure(package)?; }

        Ok(())

    }

    pub fn upgrade_all ( packages: &[&str] ) -> AppResult<()> {

        for &package in packages { Self::upgrade(package)?; }

        Ok(())

    }

}
