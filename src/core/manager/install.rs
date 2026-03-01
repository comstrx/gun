use which::which;

use super::arch::Manager;
use super::error::{ManagerResult, ManagerError};

impl Manager {

    fn resolve_package ( manager: Self, package: &str ) -> &str {

        match manager {
            Self::Brew => match package {
                "cargo"       => "rust",
                "rustup"      => "rustup",
                "rustc"       => "rust",
                "node"        => "node",
                "npm"         => "node",
                "pnpm"        => "pnpm",
                "yarn"        => "yarn",
                "npx"         => "node",
                "dotnet"      => "dotnet",
                "xmake"       => "xmake",
                "bun"         => "bun",
                "uv"          => "uv",
                "python"      => "python@3.14",
                "curl"        => "curl",
                "tofu"        => "opentofu",
                "grafana"     => "grafana",
                "prometheus"  => "prometheus",
                "terraform"   => "terraform",
                "kubectl"     => "kubernetes-cli",
                "helm"        => "helm",
                "argocd"      => "argocd",
                "git"         => "git",
                "gh"          => "gh",
                "go"          => "go",
                "zig"         => "zig",
                "mojo"        => "mojo",
                "pixi"        => "pixi",
                "clang"       => "llvm",
                "gcc"         => "gcc",
                "perl"        => "perl",
                "7z"          => "sevenzip",
                "cmake"       => "cmake",
                "dart"        => "dart",
                "composer"    => "composer",
                "php"         => "php",
                "wrk"         => "wrk",
                "llvm-config" => "llvm",
                "lua"         => "lua",
                "luarocks"    => "luarocks",
                "unzip"       => "unzip",
                _             => package,
            },
            Self::Apt => match package {
                "cargo"       => "cargo",
                "rustup"      => "rustup",
                "rustc"       => "rustc",
                "node"        => "nodejs",
                "npm"         => "npm",
                "pnpm"        => "pnpm",
                "yarn"        => "yarnpkg",
                "npx"         => "npm",
                "dotnet"      => "dotnet",
                "xmake"       => "xmake",
                "bun"         => "bun",
                "uv"          => "uv",
                "python"      => "python3",
                "curl"        => "curl",
                "tofu"        => "opentofu",
                "grafana"     => "grafana",
                "prometheus"  => "prometheus",
                "terraform"   => "terraform",
                "kubectl"     => "kubectl",
                "helm"        => "helm",
                "argocd"      => "argocd",
                "git"         => "git",
                "gh"          => "gh",
                "go"          => "golang-go",
                "zig"         => "zig",
                "mojo"        => "mojo",
                "pixi"        => "pixi",
                "clang"       => "clang",
                "gcc"         => "gcc",
                "perl"        => "perl",
                "7z"          => "7zip",
                "cmake"       => "cmake",
                "dart"        => "dart",
                "composer"    => "composer",
                "php"         => "php",
                "wrk"         => "wrk",
                "llvm-config" => "llvm",
                "lua"         => "lua5.4",
                "luarocks"    => "luarocks",
                "unzip"       => "unzip",
                _             => package,
            },
            Self::Dnf => match package {
                "cargo"       => "cargo",
                "rustup"      => "rustup",
                "rustc"       => "rust",
                "node"        => "nodejs",
                "npm"         => "npm",
                "pnpm"        => "pnpm",
                "yarn"        => "yarnpkg",
                "npx"         => "npm",
                "dotnet"      => "dotnet",
                "xmake"       => "xmake",
                "bun"         => "bun",
                "uv"          => "uv",
                "python"      => "python3",
                "curl"        => "curl",
                "tofu"        => "opentofu",
                "grafana"     => "grafana",
                "prometheus"  => "prometheus",
                "terraform"   => "terraform",
                "kubectl"     => "kubectl",
                "helm"        => "helm",
                "argocd"      => "argocd",
                "git"         => "git",
                "gh"          => "gh",
                "go"          => "golang",
                "zig"         => "zig",
                "mojo"        => "mojo",
                "pixi"        => "pixi",
                "clang"       => "clang",
                "gcc"         => "gcc",
                "perl"        => "perl",
                "7z"          => "7zip",
                "cmake"       => "cmake",
                "dart"        => "dart",
                "composer"    => "composer",
                "php"         => "php",
                "wrk"         => "wrk",
                "llvm-config" => "llvm",
                "lua"         => "lua",
                "luarocks"    => "luarocks",
                "unzip"       => "unzip",
                _             => package,
            },
            Self::Yum => match package {
                "cargo"       => "cargo",
                "rustup"      => "rustup",
                "rustc"       => "rust",
                "node"        => "nodejs",
                "npm"         => "npm",
                "pnpm"        => "pnpm",
                "yarn"        => "yarnpkg",
                "npx"         => "npm",
                "dotnet"      => "dotnet",
                "xmake"       => "xmake",
                "bun"         => "bun",
                "uv"          => "uv",
                "python"      => "python3",
                "curl"        => "curl",
                "tofu"        => "opentofu",
                "grafana"     => "grafana",
                "prometheus"  => "prometheus",
                "terraform"   => "terraform",
                "kubectl"     => "kubectl",
                "helm"        => "helm",
                "argocd"      => "argocd",
                "git"         => "git",
                "gh"          => "gh",
                "go"          => "golang",
                "zig"         => "zig",
                "mojo"        => "mojo",
                "pixi"        => "pixi",
                "clang"       => "clang",
                "gcc"         => "gcc",
                "perl"        => "perl",
                "7z"          => "7zip",
                "cmake"       => "cmake",
                "dart"        => "dart",
                "composer"    => "composer",
                "php"         => "php",
                "wrk"         => "wrk",
                "llvm-config" => "llvm",
                "lua"         => "lua",
                "luarocks"    => "luarocks",
                "unzip"       => "unzip",
                _             => package,
            },
            Self::Pacman => match package {
                "cargo"       => "rust",
                "rustup"      => "rustup",
                "rustc"       => "rust",
                "node"        => "nodejs",
                "npm"         => "npm",
                "pnpm"        => "pnpm",
                "yarn"        => "yarn",
                "npx"         => "npm",
                "dotnet"      => "dotnet",
                "xmake"       => "xmake",
                "bun"         => "bun",
                "uv"          => "uv",
                "python"      => "python",
                "curl"        => "curl",
                "tofu"        => "opentofu",
                "grafana"     => "grafana",
                "prometheus"  => "prometheus",
                "terraform"   => "terraform",
                "kubectl"     => "kubectl",
                "helm"        => "helm",
                "argocd"      => "argocd",
                "git"         => "git",
                "gh"          => "github-cli",
                "go"          => "go",
                "zig"         => "zig",
                "mojo"        => "mojo",
                "pixi"        => "pixi",
                "clang"       => "clang",
                "gcc"         => "gcc",
                "perl"        => "perl",
                "7z"          => "7zip",
                "cmake"       => "cmake",
                "dart"        => "dart",
                "composer"    => "composer",
                "php"         => "php",
                "wrk"         => "wrk",
                "llvm-config" => "llvm",
                "lua"         => "lua",
                "luarocks"    => "luarocks",
                "unzip"       => "unzip",
                _             => package,
            },
            Self::Zypper => match package {
                "cargo"       => "cargo",
                "rustup"      => "rustup",
                "rustc"       => "rust",
                "node"        => "nodejs",
                "npm"         => "npm",
                "pnpm"        => "pnpm",
                "yarn"        => "yarn",
                "npx"         => "npm",
                "dotnet"      => "dotnet",
                "xmake"       => "xmake",
                "bun"         => "bun",
                "uv"          => "uv",
                "python"      => "python3",
                "curl"        => "curl",
                "tofu"        => "opentofu",
                "grafana"     => "grafana",
                "prometheus"  => "prometheus",
                "terraform"   => "terraform",
                "kubectl"     => "kubectl",
                "helm"        => "helm",
                "argocd"      => "argocd",
                "git"         => "git",
                "gh"          => "gh",
                "go"          => "go",
                "zig"         => "zig",
                "mojo"        => "mojo",
                "pixi"        => "pixi",
                "clang"       => "clang",
                "gcc"         => "gcc",
                "perl"        => "perl",
                "7z"          => "7zip",
                "cmake"       => "cmake",
                "dart"        => "dart",
                "composer"    => "composer",
                "php"         => "php",
                "wrk"         => "wrk",
                "llvm-config" => "llvm",
                "lua"         => "lua54",
                "luarocks"    => "lua54-luarocks",
                "unzip"       => "unzip",
                _             => package,
            },
            Self::Apk => match package {
                "cargo"       => "cargo",
                "rustup"      => "rustup",
                "rustc"       => "rust",
                "node"        => "nodejs",
                "npm"         => "npm",
                "pnpm"        => "pnpm",
                "yarn"        => "yarn",
                "npx"         => "npm",
                "dotnet"      => "dotnet",
                "xmake"       => "xmake",
                "bun"         => "bun",
                "uv"          => "uv",
                "python"      => "python3",
                "curl"        => "curl",
                "tofu"        => "opentofu",
                "grafana"     => "grafana",
                "prometheus"  => "prometheus",
                "terraform"   => "terraform",
                "kubectl"     => "kubectl",
                "helm"        => "helm",
                "argocd"      => "argocd",
                "git"         => "git",
                "gh"          => "gh",
                "go"          => "go",
                "zig"         => "zig",
                "mojo"        => "mojo",
                "pixi"        => "pixi",
                "clang"       => "clang",
                "gcc"         => "gcc",
                "perl"        => "perl",
                "7z"          => "7zip",
                "cmake"       => "cmake",
                "dart"        => "dart",
                "composer"    => "composer",
                "php"         => "php",
                "wrk"         => "wrk",
                "llvm-config" => "llvm",
                "lua"         => "lua5.4",
                "luarocks"    => "luarocks5.4",
                "unzip"       => "unzip",
                _             => package,
            },
            Self::Winget => match package {
                "cargo"       => "Rustlang.Rustup",
                "rustup"      => "Rustlang.Rustup",
                "rustc"       => "Rustlang.Rustup",
                "node"        => "OpenJS.NodeJS",
                "npm"         => "OpenJS.NodeJS",
                "pnpm"        => "pnpm.pnpm",
                "yarn"        => "yarn",
                "npx"         => "OpenJS.NodeJS",
                "dotnet"      => "dotnet",
                "xmake"       => "Xmake-io.Xmake",
                "bun"         => "Oven-sh.Bun",
                "uv"          => "astral-sh.uv",
                "python"      => "Python.Python.3.14",
                "curl"        => "curl",
                "tofu"        => "OpenTofu.Tofu",
                "grafana"     => "grafana",
                "prometheus"  => "prometheus",
                "terraform"   => "terraform",
                "kubectl"     => "Kubernetes.kubectl",
                "helm"        => "Helm.Helm",
                "argocd"      => "argocd",
                "git"         => "Git.Git",
                "gh"          => "GitHub.cli",
                "go"          => "GoLang.Go",
                "zig"         => "zig",
                "mojo"        => "mojo",
                "pixi"        => "pixi",
                "clang"       => "LLVM.LLVM",
                "gcc"         => "gcc",
                "perl"        => "perl",
                "7z"          => "7zip.7zip",
                "cmake"       => "Kitware.CMake",
                "dart"        => "Google.DartSDK",
                "composer"    => "composer",
                "php"         => "php",
                "wrk"         => "wrk",
                "llvm-config" => "LLVM.LLVM",
                "lua"         => "DEVCOM.Lua",
                "luarocks"    => "DEVCOM.Lua",
                "unzip"       => "GnuWin32.UnZip",
                _             => package,
            },
            Self::Scoop => match package {
                "cargo"       => "rustup",
                "rustup"      => "rustup",
                "rustc"       => "rustup",
                "node"        => "nodejs",
                "npm"         => "nodejs",
                "pnpm"        => "pnpm",
                "yarn"        => "yarn",
                "npx"         => "nodejs",
                "dotnet"      => "dotnet",
                "xmake"       => "xmake",
                "bun"         => "bun",
                "uv"          => "uv",
                "python"      => "python",
                "curl"        => "curl",
                "tofu"        => "main/opentofu",
                "grafana"     => "grafana",
                "prometheus"  => "prometheus",
                "terraform"   => "terraform",
                "kubectl"     => "kubectl",
                "helm"        => "helm",
                "argocd"      => "argocd",
                "git"         => "git",
                "gh"          => "gh",
                "go"          => "go",
                "zig"         => "zig",
                "mojo"        => "mojo",
                "pixi"        => "pixi",
                "clang"       => "llvm",
                "gcc"         => "gcc",
                "perl"        => "perl",
                "7z"          => "7zip",
                "cmake"       => "cmake",
                "dart"        => "dart",
                "composer"    => "composer",
                "php"         => "php",
                "wrk"         => "wrk",
                "llvm-config" => "llvm",
                "lua"         => "lua",
                "luarocks"    => "luarocks",
                "unzip"       => "unzip",
                _             => package,
            },
            Self::Choco => match package {
                "cargo"       => "rustup.install",
                "rustup"      => "rustup.install",
                "rustc"       => "rustup.install",
                "node"        => "nodejs",
                "npm"         => "nodejs",
                "pnpm"        => "pnpm",
                "yarn"        => "yarn",
                "npx"         => "nodejs",
                "dotnet"      => "dotnet",
                "xmake"       => "xmake",
                "bun"         => "bun",
                "uv"          => "uv",
                "python"      => "python",
                "curl"        => "curl",
                "tofu"        => "opentofu",
                "grafana"     => "grafana",
                "prometheus"  => "prometheus",
                "terraform"   => "terraform",
                "kubectl"     => "kubernetes-cli",
                "helm"        => "kubernetes-helm",
                "argocd"      => "argocd",
                "git"         => "git",
                "gh"          => "gh",
                "go"          => "golang",
                "zig"         => "zig",
                "mojo"        => "mojo",
                "pixi"        => "pixi",
                "clang"       => "llvm",
                "gcc"         => "gcc",
                "perl"        => "perl",
                "7z"          => "7zip",
                "cmake"       => "cmake",
                "dart"        => "dart",
                "composer"    => "composer",
                "php"         => "php",
                "wrk"         => "wrk",
                "llvm-config" => "llvm",
                "lua"         => "lua",
                "luarocks"    => "luarocks",
                "unzip"       => "unzip",
                _             => package,
            },
        }

    }

    fn install_package ( package: &str ) -> ManagerResult<()> {

        let manager = Self::detect()?;
        let package = Self::resolve_package(manager, package);

        match manager {
            Self::Apt    => Self::sudo_run("apt-get", &["install", "-y", package]),
            Self::Dnf    => Self::sudo_run("dnf", &["install", "-y", package]),
            Self::Yum    => Self::sudo_run("yum", &["install", "-y", package]),
            Self::Pacman => Self::sudo_run("pacman", &["-S", "--needed", "--noconfirm", "--noprogressbar", package],),
            Self::Zypper => Self::sudo_run("zypper", &["install", "-y", package]),
            Self::Apk    => Self::sudo_run("apk", &["add", package]),
            Self::Brew   => Self::run("brew", &["install", package]),
            Self::Scoop  => Self::run("scoop", &["install", package]),
            Self::Choco  => Self::run("choco", &["install", "-y", package]),
            Self::Winget => Self::run("winget", &["install", "-e", "--id", package, "--source", "winget", "--accept-package-agreements", "--accept-source-agreements", "--disable-interactivity"]),
        }

    }

    fn install_cpp () -> ManagerResult<()> {

        Self::install_package("clang")?;
        Self::install_package("gcc")?;
        Self::install_package("llvm-config")?;
        Self::install_package("cmake")?;
        Self::install_package("xmake")?;
        Ok(())

    }

    fn install_rust () -> ManagerResult<()> {

        Self::install_package("rustup")?;

        Self::run("rustup", &["toolchain", "install", "stable", "--profile", "minimal", "--component", "rustfmt"],)?;
        Self::run("rustup", &["toolchain", "install", "nightly", "--allow-downgrade", "--profile", "minimal", "--component", "rustfmt"])?;

        Self::run("rustup", &["default", "stable"])?;
        Ok(())

    }

    fn install_zig () -> ManagerResult<()> {

        Self::install_package("zig")?;
        Ok(())

    }

    fn install_mojo () -> ManagerResult<()> {

        Self::install_package("mojo")?;
        Self::install_package("pixi")?;
        Ok(())

    }

    fn install_go () -> ManagerResult<()> {

        Self::install_package("go")?;
        Ok(())

    }

    fn install_dotnet () -> ManagerResult<()> {

        Self::install_package("dotnet")?;
        Ok(())

    }

    fn install_node () -> ManagerResult<()> {

        Self::install_package("node")?;
        Self::install_package("pnpm")?;
        Ok(())

    }

    fn install_bun () -> ManagerResult<()> {

        Self::install_package("bun")?;
        Ok(())

    }

    fn install_php () -> ManagerResult<()> {

        Self::install_package("php")?;
        Self::install_package("composer")?;
        Ok(())

    }

    fn install_python () -> ManagerResult<()> {

        Self::install_package("python")?;
        Self::install_package("uv")?;
        Ok(())

    }

    fn install_lua () -> ManagerResult<()> {

        Self::install_package("lua")?;
        Self::install_package("luarocks")?;
        Ok(())

    }

    fn install_git () -> ManagerResult<()> {

        Self::install_package("git")?;
        Ok(())

    }

    fn install_gh () -> ManagerResult<()> {

        Self::install_package("gh")?;
        Ok(())

    }

    fn install_docker () -> ManagerResult<()> {

        match Self::detect()? {
            Self::Apt | Self::Dnf | Self::Yum | Self::Pacman | Self::Zypper | Self::Apk => {
                let result = (|| -> ManagerResult<()> {
                    Self::run("curl", &["-fsSL", "https://get.docker.com", "-o", "get-docker.sh"])?;
                    Self::sudo_run("sh", &["get-docker.sh"])?;
                    Ok(())
                })();

                let _ = std::fs::remove_file("get-docker.sh");

                result
            }
            _ => Self::install_package("docker"),
        }

    }

    fn install_kubectl () -> ManagerResult<()> {

        match Self::detect()? {
            Self::Apt | Self::Dnf | Self::Yum | Self::Pacman | Self::Zypper | Self::Apk => {
                let arch = match std::env::consts::ARCH {
                    "x86_64"    => "amd64",
                    "aarch64"   => "arm64",
                    "arm"       => "arm",
                    "x86"       => "386",
                    other => return Err(ManagerError::message(format!("unsupported kubectl arch: {other}"))),
                };

                let output = std::process::Command::new("curl")
                    .args(["-L", "-s", "https://dl.k8s.io/release/stable.txt"])
                    .output()?;

                if !output.status.success() {
                    return Err(ManagerError::message("failed to fetch kubectl stable version"));
                }

                let version = String::from_utf8(output.stdout)?.trim().to_string();
                let url = format!("https://dl.k8s.io/release/{version}/bin/linux/{arch}/kubectl");

                let result = (|| -> ManagerResult<()> {
                    Self::run("curl", &["-fL", "-o", "kubectl", &url])?;
                    Self::sudo_run("install", &["-o", "root", "-g", "root", "-m", "0755", "kubectl", "/usr/local/bin/kubectl"])?;
                    Ok(())
                })();

                let _ = std::fs::remove_file("kubectl");

                result
            }
            _ => Self::install_package("kubectl"),
        }

    }

    fn install_minikube () -> ManagerResult<()> {

        match Self::detect()? {
            Self::Apt | Self::Dnf | Self::Yum | Self::Pacman | Self::Zypper | Self::Apk => {
                let arch = match std::env::consts::ARCH {
                    "x86_64"    => "amd64",
                    "aarch64"   => "arm64",
                    "powerpc64" => "ppc64le",
                    "s390x"     => "s390x",
                    other => return Err(ManagerError::message(format!("unsupported minikube arch: {other}"))),
                };

                let file = format!("minikube-linux-{arch}");
                let url = format!("https://github.com/kubernetes/minikube/releases/latest/download/{file}");

                let result = (|| -> ManagerResult<()> {
                    Self::run("curl", &["-fL", "-o", &file, &url])?;
                    Self::sudo_run("install", &[&file, "/usr/local/bin/minikube"])?;
                    Ok(())
                })();

                let _ = std::fs::remove_file(&file);

                result
            }
            _ => Self::install_package("minikube"),
        }

    }

    fn install_helm () -> ManagerResult<()> {

        match Self::detect()? {
            Self::Apt | Self::Dnf | Self::Yum | Self::Pacman | Self::Zypper | Self::Apk => {
                let arch = match std::env::consts::ARCH {
                    "x86_64"    => "amd64",
                    "aarch64"   => "arm64",
                    "arm"       => "arm",
                    "x86"       => "386",
                    other => return Err(ManagerError::message(format!("unsupported helm arch: {other}"))),
                };

                let output = std::process::Command::new("curl")
                    .args(["-L", "-s", "-o", "/dev/null", "-w", "%{url_effective}", "https://github.com/helm/helm/releases/latest"])
                    .output()?;

                if !output.status.success() {
                    return Err(ManagerError::message("failed to fetch helm latest release"));
                }

                let latest_url = String::from_utf8(output.stdout)?.trim().to_string();

                let version = latest_url
                    .rsplit('/')
                    .next()
                    .ok_or_else(|| ManagerError::message("failed to parse helm latest version"))?
                    .to_string();

                let archive = format!("helm-{version}-linux-{arch}.tar.gz");
                let url = format!("https://get.helm.sh/{archive}");
                let dir = format!("linux-{arch}");

                let result = (|| -> ManagerResult<()> {
                    Self::run("curl", &["-fL", "-o", &archive, &url])?;
                    Self::run("tar", &["-xzf", &archive])?;
                    Self::sudo_run("install", &[&format!("{dir}/helm"), "/usr/local/bin/helm"])?;
                    Ok(())
                })();

                let _ = std::fs::remove_file(&archive);
                let _ = std::fs::remove_dir_all(&dir);

                result
            }
            _ => Self::install_package("helm"),
        }

    }

    fn install_kind () -> ManagerResult<()> {

        match Self::detect()? {
            Self::Apt | Self::Dnf | Self::Yum | Self::Pacman | Self::Zypper | Self::Apk => {
                let arch = match std::env::consts::ARCH {
                    "x86_64"    => "amd64",
                    "aarch64"   => "arm64",
                    other => return Err(ManagerError::message(format!("unsupported kind arch: {other}"))),
                };

                let output = std::process::Command::new("curl")
                    .args(["-L", "-s", "-o", "/dev/null", "-w", "%{url_effective}", "https://github.com/kubernetes-sigs/kind/releases/latest"])
                    .output()?;

                if !output.status.success() { return Err(ManagerError::message("failed to fetch kind latest release")); }

                let latest_url = String::from_utf8(output.stdout)?.trim().to_string();

                let version = latest_url.rsplit('/').next()
                    .ok_or_else(|| ManagerError::message("failed to parse kind latest version"))?
                    .to_string();

                let url = format!("https://kind.sigs.k8s.io/dl/{version}/kind-linux-{arch}");

                let result = (|| -> ManagerResult<()> {
                    Self::run("curl", &["-fL", "-o", "kind", &url])?;
                    Self::run("chmod", &["+x", "kind"])?;
                    Self::sudo_run("install", &["-m", "0755", "kind", "/usr/local/bin/kind"])?;
                    Ok(())
                })();

                let _ = std::fs::remove_file("kind");

                result
            }
            _ => Self::install_package("kind"),
        }

    }

    fn install_kustomize () -> ManagerResult<()> {

        match Self::detect()? {
            Self::Apt | Self::Dnf | Self::Yum | Self::Pacman | Self::Zypper | Self::Apk => {
                let arch = match std::env::consts::ARCH {
                    "x86_64"  => "amd64",
                    "aarch64" => "arm64",
                    other => return Err(ManagerError::message(format!("unsupported kustomize arch: {other}"))),
                };

                let output = std::process::Command::new("curl")
                    .args(["-L", "-s", "-o", "/dev/null", "-w", "%{url_effective}", "https://github.com/kubernetes-sigs/kustomize/releases/latest"])
                    .output()?;

                if !output.status.success() {
                    return Err(ManagerError::message("failed to fetch kustomize latest release"));
                }

                let latest_url = String::from_utf8(output.stdout)?.trim().to_string();

                let tag = latest_url.rsplit('/').next()
                    .ok_or_else(|| ManagerError::message("failed to parse kustomize latest version"))?
                    .to_string();

                let archive = format!("kustomize_{tag}_linux_{arch}.tar.gz");
                let url = format!("https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F{tag}/{archive}");

                let workdir = std::env::temp_dir().join(format!("gun-kustomize-{}", std::process::id()));
                let workdir_s = workdir.to_string_lossy().into_owned();

                let archive_path = workdir.join(&archive);
                let archive_path_s = archive_path.to_string_lossy().into_owned();

                std::fs::create_dir_all(&workdir)?;

                let result = (|| -> ManagerResult<()> {
                    Self::run("curl", &["-fL", "-o", &archive_path_s, &url])?;
                    Self::run("tar", &["-xzf", &archive_path_s, "-C", &workdir_s])?;

                    let direct = workdir.join("kustomize");

                    let binary_path = if direct.is_file() {
                        direct
                    } else {
                        let mut found = None;

                        for entry in std::fs::read_dir(&workdir)? {
                            let path = entry?.path();

                            if path.is_dir() {
                                let nested = path.join("kustomize");

                                if nested.is_file() {
                                    found = Some(nested);
                                    break;
                                }
                            }
                        }

                        found.ok_or_else(|| ManagerError::message("failed to locate extracted kustomize binary"))?
                    };

                    let binary_path_s = binary_path.to_string_lossy().into_owned();

                    Self::sudo_run("install", &["-m", "0755", &binary_path_s, "/usr/local/bin/kustomize"])?;
                    Ok(())
                })();

                let _ = std::fs::remove_dir_all(&workdir);

                result
            }
            _ => Self::install_package("kustomize"),
        }

    }

    fn install_argocd () -> ManagerResult<()> {

        match Self::detect()? {
            Self::Apt | Self::Dnf | Self::Yum | Self::Pacman | Self::Zypper | Self::Apk => {
                let arch = match std::env::consts::ARCH {
                    "x86_64"    => "amd64",
                    "aarch64"   => "arm64",
                    other => return Err(ManagerError::message(format!("unsupported argocd arch: {other}"))),
                };

                let output = std::process::Command::new("curl")
                    .args(["-L", "-s", "https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION"])
                    .output()?;

                if !output.status.success() {
                    return Err(ManagerError::message("failed to fetch argocd stable version"));
                }

                let version = format!("v{}", String::from_utf8(output.stdout)?.trim());
                let file = format!("argocd-linux-{arch}");
                let url = format!("https://github.com/argoproj/argo-cd/releases/download/{version}/{file}");

                let result = (|| -> ManagerResult<()> {
                    Self::run("curl", &["-fL", "-o", &file, &url])?;
                    Self::sudo_run("install", &["-m", "0555", &file, "/usr/local/bin/argocd"])?;
                    Ok(())
                })();

                let _ = std::fs::remove_file(&file);

                result
            }
            _ => Self::install_package("argocd"),
        }

    }

    fn install_terraform () -> ManagerResult<()> {

        match Self::detect()? {
            Self::Apt | Self::Dnf | Self::Yum | Self::Pacman | Self::Zypper | Self::Apk => {
                let arch = match std::env::consts::ARCH {
                    "x86_64"    => "amd64",
                    "aarch64"   => "arm64",
                    "arm"       => "arm",
                    "x86"       => "386",
                    other => return Err(ManagerError::message(format!("unsupported terraform arch: {other}"))),
                };

                let output = std::process::Command::new("curl")
                    .args(["-L", "-s", "https://releases.hashicorp.com/terraform/"])
                    .output()?;

                if !output.status.success() {
                    return Err(ManagerError::message("failed to fetch terraform releases"));
                }

                let body = String::from_utf8(output.stdout)?;

                let version = body
                    .split('"')
                    .filter_map(|part| part.strip_prefix("/terraform/"))
                    .filter_map(|part| part.split('/').next())
                    .find(|candidate| { !candidate.is_empty() && candidate.chars().all(|ch| ch.is_ascii_digit() || ch == '.') })
                    .ok_or_else(|| ManagerError::message("failed to parse terraform latest stable version"))?
                    .to_string();

                let archive = format!("terraform_{version}_linux_{arch}.zip");
                let url = format!("https://releases.hashicorp.com/terraform/{version}/{archive}");

                let workdir = std::env::temp_dir().join(format!("gun-terraform-{}", std::process::id()));
                let workdir_s = workdir.to_string_lossy().into_owned();

                let archive_path = workdir.join(&archive);
                let archive_path_s = archive_path.to_string_lossy().into_owned();

                let binary_path = workdir.join("terraform");
                let binary_path_s = binary_path.to_string_lossy().into_owned();

                std::fs::create_dir_all(&workdir)?;

                let result = (|| -> ManagerResult<()> {
                    Self::install_package("unzip")?;
                    Self::run("curl", &["-fL", "-o", &archive_path_s, &url])?;
                    Self::run("unzip", &["-o", &archive_path_s, "-d", &workdir_s])?;
                    Self::sudo_run("install", &["-m", "0755", &binary_path_s, "/usr/local/bin/terraform"])?;
                    Ok(())
                })();

                let _ = std::fs::remove_dir_all(&workdir);

                result
            }
            _ => Self::install_package("terraform"),
        }

    }

    fn install_opentofu () -> ManagerResult<()> {

        match Self::detect()? {
            Self::Apt | Self::Dnf | Self::Yum | Self::Pacman | Self::Zypper | Self::Apk => {
                let arch = match std::env::consts::ARCH {
                    "x86_64"  => "amd64",
                    "aarch64" => "arm64",
                    other     => return Err(ManagerError::message(format!("unsupported opentofu arch: {other}"))),
                };

                let output = std::process::Command::new("curl")
                    .args(["-L", "-s", "-o", "/dev/null", "-w", "%{url_effective}", "https://github.com/opentofu/opentofu/releases/latest"])
                    .output()?;

                if !output.status.success() {
                    return Err(ManagerError::message("failed to fetch opentofu latest release"));
                }

                let latest_url = String::from_utf8(output.stdout)?.trim().to_string();

                let tag = latest_url
                    .rsplit('/')
                    .next()
                    .ok_or_else(|| ManagerError::message("failed to parse opentofu latest version"))?
                    .to_string();

                let version = tag.strip_prefix('v').unwrap_or(&tag).to_string();
                let archive = format!("tofu_{version}_linux_{arch}.tar.gz");
                let url = format!("https://github.com/opentofu/opentofu/releases/download/{tag}/{archive}");

                let workdir = std::env::temp_dir().join(format!("gun-opentofu-{}", std::process::id()));
                let workdir_s = workdir.to_string_lossy().into_owned();

                let archive_path = workdir.join(&archive);
                let archive_path_s = archive_path.to_string_lossy().into_owned();

                let binary_path = workdir.join("tofu");
                let binary_path_s = binary_path.to_string_lossy().into_owned();

                std::fs::create_dir_all(&workdir)?;

                let result = (|| -> ManagerResult<()> {
                    Self::run("curl", &["-fL", "-o", &archive_path_s, &url])?;
                    Self::run("tar", &["-xzf", &archive_path_s, "-C", &workdir_s])?;
                    Self::sudo_run("install", &["-m", "0755", &binary_path_s, "/usr/local/bin/tofu"])?;
                    Ok(())
                })();

                let _ = std::fs::remove_dir_all(&workdir);

                result
            }
            _ => Self::install_package("tofu"),
        }

    }

    fn install_grafana () -> ManagerResult<()> {

        Self::install_package("grafana")?;
        Ok(())

    }

    fn install_loki () -> ManagerResult<()> {

        match Self::detect()? {
            Self::Apt | Self::Dnf | Self::Yum | Self::Pacman | Self::Zypper | Self::Apk => {
                let arch = match std::env::consts::ARCH {
                    "x86_64"    => "amd64",
                    "aarch64"   => "arm64",
                    "arm"       => "arm",
                    other => return Err(ManagerError::message(format!("unsupported loki arch: {other}"))),
                };

                let output = std::process::Command::new("curl")
                    .args(["-L", "-s", "-o", "/dev/null", "-w", "%{url_effective}", "https://github.com/grafana/loki/releases/latest"])
                    .output()?;

                if !output.status.success() {
                    return Err(ManagerError::message("failed to fetch loki latest release"));
                }

                let latest_url = String::from_utf8(output.stdout)?.trim().to_string();

                let tag = latest_url.rsplit('/').next()
                    .ok_or_else(|| ManagerError::message("failed to parse loki latest version"))?
                    .to_string();

                let archive = format!("loki-linux-{arch}.zip");
                let url = format!("https://github.com/grafana/loki/releases/download/{tag}/{archive}");

                let workdir = std::env::temp_dir().join(format!("gun-loki-{}", std::process::id()));
                let workdir_s = workdir.to_string_lossy().into_owned();

                let archive_path = workdir.join(&archive);
                let archive_path_s = archive_path.to_string_lossy().into_owned();

                let extracted_binary = workdir.join(format!("loki-linux-{arch}"));
                let extracted_binary_s = extracted_binary.to_string_lossy().into_owned();

                std::fs::create_dir_all(&workdir)?;

                let result = (|| -> ManagerResult<()> {
                    Self::install_package("unzip")?;
                    Self::run("curl", &["-fL", "-o", &archive_path_s, &url])?;
                    Self::run("unzip", &["-o", &archive_path_s, "-d", &workdir_s])?;
                    Self::sudo_run("install", &["-m", "0755", &extracted_binary_s, "/usr/local/bin/loki"])?;
                    Ok(())
                })();

                let _ = std::fs::remove_dir_all(&workdir);

                result
            }
            _ => Self::install_package("loki"),
        }

    }

    fn install_prometheus () -> ManagerResult<()> {

        match Self::detect()? {
            Self::Apt | Self::Dnf | Self::Yum | Self::Pacman | Self::Zypper | Self::Apk => {
                let arch = match std::env::consts::ARCH {
                    "x86_64"    => "amd64",
                    "aarch64"   => "arm64",
                    other => return Err(ManagerError::message(format!("unsupported prometheus arch: {other}"))),
                };

                let output = std::process::Command::new("curl")
                    .args(["-L", "-s", "-o", "/dev/null", "-w", "%{url_effective}", "https://github.com/prometheus/prometheus/releases/latest"])
                    .output()?;

                if !output.status.success() {
                    return Err(ManagerError::message("failed to fetch prometheus latest release"));
                }

                let latest_url = String::from_utf8(output.stdout)?.trim().to_string();

                let tag = latest_url.rsplit('/').next()
                    .ok_or_else(|| ManagerError::message("failed to parse prometheus latest version"))?
                    .to_string();

                let version = tag.strip_prefix('v').unwrap_or(&tag).to_string();
                let archive = format!("prometheus-{version}.linux-{arch}.tar.gz");
                let url = format!("https://github.com/prometheus/prometheus/releases/download/{tag}/{archive}");

                let workdir = std::env::temp_dir().join(format!("gun-prometheus-{}", std::process::id()));
                let workdir_s = workdir.to_string_lossy().into_owned();

                let archive_path = workdir.join(&archive);
                let archive_path_s = archive_path.to_string_lossy().into_owned();

                let binary_path = workdir
                    .join(format!("prometheus-{version}.linux-{arch}"))
                    .join("prometheus");

                let binary_path_s = binary_path.to_string_lossy().into_owned();

                std::fs::create_dir_all(&workdir)?;

                let result = (|| -> ManagerResult<()> {
                    Self::run("curl", &["-fL", "-o", &archive_path_s, &url])?;
                    Self::run("tar", &["-xzf", &archive_path_s, "-C", &workdir_s])?;
                    Self::sudo_run("install", &["-m", "0755", &binary_path_s, "/usr/local/bin/prometheus"])?;
                    Ok(())
                })();

                let _ = std::fs::remove_dir_all(&workdir);

                result
            }
            _ => Self::install_package("prometheus"),
        }

    }

    fn install_otelcol () -> ManagerResult<()> {

        match Self::detect()? {
            Self::Apt | Self::Dnf | Self::Yum | Self::Pacman | Self::Zypper | Self::Apk => {
                let arch = match std::env::consts::ARCH {
                    "x86_64"     => "amd64",
                    "aarch64"    => "arm64",
                    "x86"        => "386",
                    "powerpc64"  => "ppc64le",
                    other  => return Err(ManagerError::message(format!("unsupported otelcol arch: {other}"))),
                };

                let output = std::process::Command::new("curl")
                    .args(["-L", "-s", "-o", "/dev/null", "-w", "%{url_effective}", "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/latest"])
                    .output()?;

                if !output.status.success() {
                    return Err(ManagerError::message("failed to fetch otelcol latest release"));
                }

                let latest_url = String::from_utf8(output.stdout)?.trim().to_string();

                let tag = latest_url
                    .rsplit('/')
                    .next()
                    .ok_or_else(|| ManagerError::message("failed to parse otelcol latest version"))?
                    .to_string();

                let version = tag.strip_prefix('v').unwrap_or(&tag).to_string();
                let archive = format!("otelcol_{version}_linux_{arch}.tar.gz");
                let url = format!("https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/{tag}/{archive}");

                let workdir = std::env::temp_dir().join(format!("gun-otelcol-{}", std::process::id()));
                let workdir_s = workdir.to_string_lossy().into_owned();

                let archive_path = workdir.join(&archive);
                let archive_path_s = archive_path.to_string_lossy().into_owned();

                let binary_path = workdir.join("otelcol");
                let binary_path_s = binary_path.to_string_lossy().into_owned();

                std::fs::create_dir_all(&workdir)?;

                let result = (|| -> ManagerResult<()> {
                    Self::run("curl", &["-fL", "-o", &archive_path_s, &url])?;
                    Self::run("tar", &["-xzf", &archive_path_s, "-C", &workdir_s])?;
                    Self::sudo_run("install", &["-m", "0755", &binary_path_s, "/usr/local/bin/otelcol"])?;
                    Ok(())
                })();

                let _ = std::fs::remove_dir_all(&workdir);

                result
            }
            _ => Self::install_package("otelcol"),
        }

    }

    pub fn install ( tool: &str ) -> ManagerResult<()> {

        match tool {
            "c" | "cpp"             => Self::install_cpp(),
            "rust"                  => Self::install_rust(),
            "zig"                   => Self::install_zig(),
            "mojo"                  => Self::install_mojo(),
            "go"                    => Self::install_go(),
            "dotnet"                => Self::install_dotnet(),
            "node"                  => Self::install_node(),
            "bun"                   => Self::install_bun(),
            "php"                   => Self::install_php(),
            "python"                => Self::install_python(),
            "lua"                   => Self::install_lua(),
            "git"                   => Self::install_git(),
            "gh"                    => Self::install_gh(),
            "docker"                => Self::install_docker(),
            "kubectl"               => Self::install_kubectl(),
            "minikube"              => Self::install_minikube(),
            "helm"                  => Self::install_helm(),
            "kind"                  => Self::install_kind(),
            "kustomize"             => Self::install_kustomize(),
            "argocd"                => Self::install_argocd(),
            "terraform"             => Self::install_terraform(),
            "tofu"                  => Self::install_opentofu(),
            "grafana"               => Self::install_grafana(),
            "loki"                  => Self::install_loki(),
            "prometheus"            => Self::install_prometheus(),
            "otelcol"               => Self::install_otelcol(),
            _                       => Err(ManagerError::message("unsupported tool")),
        }

    }

    pub fn ensure ( tool: &str ) -> ManagerResult<()> {

        if which(tool).is_ok() {

            return Ok(());

        }

        Self::install(tool)?;

        if which(tool).is_err() {

            return Err(ManagerError::missing_binary(tool));

        }

        Ok(())

    }

}
