use std::{path::PathBuf, process::Command, sync::OnceLock};
use semver::Version;
use regex::Regex;

use crate::core::app::{AppResult, AppError};
use super::arch::{Tool, Spec, Info, Method};
use super::map::TOOLS;

impl Method {

    pub const fn as_str ( &self ) -> &'static str {

        match self {
            Self::Native => "native",
            Self::Shell  => "shell",
            Self::Bash   => "bash",
            Self::Nix    => "nix",
            Self::Mise   => "mise",
        }

    }

}

impl Spec {

    pub const fn new ( bin: &'static str ) -> Self {

        Self {
            method  : Method::Native,
            id      : bin,
            bin     : bin,
            path    : "",
            source  : "",
            version : "",
            args    : &[],
            aliases : &[]
        }

    }

    pub const fn set_method ( mut self, value: Method ) -> Self {

        self.method = value;
        self

    }

    pub const fn set_id ( mut self, value: &'static str ) -> Self {

        self.id = value;
        self

    }

    pub const fn set_bin ( mut self, value: &'static str ) -> Self {

        self.bin = value;
        self

    }

    pub const fn set_path ( mut self, value: &'static str ) -> Self {

        self.path = value;
        self

    }

    pub const fn set_source ( mut self, value: &'static str ) -> Self {

        self.source = value;
        self

    }

    pub const fn set_version ( mut self, value: &'static str ) -> Self {

        self.version = value;
        self

    }

    pub const fn set_args ( mut self, value: &'static [&'static str] ) -> Self {

        self.args = value;
        self

    }

    pub const fn set_aliases ( mut self, value: &'static [&'static str] ) -> Self {

        self.aliases = value;
        self

    }

}

impl Tool {

    pub const fn new ( bin : &'static str ) -> Self {

        Self {
            apt    : Spec::new(bin),
            apk    : Spec::new(bin),
            dnf    : Spec::new(bin),
            yum    : Spec::new(bin),
            pacman : Spec::new(bin),
            zypper : Spec::new(bin),
            brew   : Spec::new(bin),
            winget : Spec::new(bin),
            scoop  : Spec::new(bin),
            choco  : Spec::new(bin),
        }
    }

    pub const fn set_apt ( mut self, value: Spec ) -> Self {

        self.apt = value;
        self

    }

    pub const fn set_apk ( mut self, value: Spec ) -> Self {

        self.apk = value;
        self

    }

    pub const fn set_dnf ( mut self, value: Spec ) -> Self {

        self.dnf = value;
        self

    }

    pub const fn set_yum ( mut self, value: Spec ) -> Self {

        self.yum = value;
        self

    }

    pub const fn set_pacman ( mut self, value: Spec ) -> Self {

        self.pacman = value;
        self

    }

    pub const fn set_zypper ( mut self, value: Spec ) -> Self {

        self.zypper = value;
        self

    }

    pub const fn set_brew ( mut self, value: Spec ) -> Self {

        self.brew = value;
        self

    }

    pub const fn set_winget ( mut self, value: Spec ) -> Self {

        self.winget = value;
        self

    }

    pub const fn set_scoop ( mut self, value: Spec ) -> Self {

        self.scoop = value;
        self

    }

    pub const fn set_choco ( mut self, value: Spec ) -> Self {

        self.choco = value;
        self

    }


    pub fn find ( key: &str ) -> AppResult<Self> {

        let key = key.trim();

        let has = |spec: &Spec| {
            spec.bin.eq_ignore_ascii_case(key)
                || spec.id.eq_ignore_ascii_case(key)
                || spec.path.eq_ignore_ascii_case(key)
                || spec.source.eq_ignore_ascii_case(key)
                || spec.aliases.iter().any(|alias| alias.eq_ignore_ascii_case(key))
        };

        TOOLS
            .iter()
            .find(|(name, tool)| {
                name.eq_ignore_ascii_case(key)
                    || has(&tool.apt)
                    || has(&tool.apk)
                    || has(&tool.dnf)
                    || has(&tool.yum)
                    || has(&tool.pacman)
                    || has(&tool.zypper)
                    || has(&tool.brew)
                    || has(&tool.winget)
                    || has(&tool.scoop)
                    || has(&tool.choco)
            })
            .map(|(_, tool)| *tool)
            .ok_or_else(|| AppError::command_not_found(key))

    }

    pub fn has ( key: &str ) -> bool {

        Self::find(key).is_ok()

    }

    pub fn get ( bin: &str, manager: &str ) -> AppResult<Spec> {

        let tool = Self::find(bin)?;

        Ok(match manager {
            "apt"    => tool.apt,
            "apk"    => tool.apk,
            "dnf"    => tool.dnf,
            "yum"    => tool.yum,
            "pacman" => tool.pacman,
            "zypper" => tool.zypper,
            "brew"   => tool.brew,
            "winget" => tool.winget,
            "scoop"  => tool.scoop,
            "choco"  => tool.choco,
            _        => return Err(AppError::unsupported_manager(manager)),
        })

    }


    pub fn info ( bin: &str, manager: &str, path: Option<PathBuf>, version: Option<String> ) -> AppResult<Info> {

        let exists = path.is_some();

        let default = Info {
            method  : Method::Native,
            id      : bin.to_string(),
            bin     : bin.to_string(),
            path    : path,
            source  : Some(String::new()),
            version : version,
            exists  : exists,
            args    : Vec::new(),
            aliases : Vec::new(),
        };

        if let Ok(spec) = Self::get(bin, manager) {

            return Ok(Info {
                method  : spec.method,
                id      : spec.id.to_string(),
                bin     : spec.bin.to_string(),
                source  : Some(spec.source.to_string()),
                path    : default.path.or_else(|| Some(spec.path.into())),
                version : default.version.or_else(|| Some(spec.version.to_string())),
                exists  : default.exists,
                args    : spec.args.iter().map(|value| (*value).to_string()).collect(),
                aliases : spec.aliases.iter().map(|value| (*value).to_string()).collect(),
            });

        }

        Ok(default)

    }

    pub fn show ( bin: &str, manager: &str, path: Option<PathBuf>, version: Option<String> ) -> AppResult<()> {

        let info = Self::info(bin, manager, path, version)?;

        println!("id       : {}", info.id);
        println!("bin      : {}", info.bin);
        println!("path     : {}", info.path.as_deref().map(|path| path.to_string_lossy().into_owned()).unwrap_or_else(|| "-".into()));
        println!("version  : {}", info.version.as_deref().unwrap_or("-"));
        println!("source   : {}", info.source.as_deref().unwrap_or("-"));
        println!("method   : {}", info.method.as_str());
        println!("exists   : {}", info.exists);

        Ok(())

    }

    pub fn version ( bin: &str ) -> AppResult<String> {

        static RE: OnceLock<Regex> = OnceLock::new();
        let mut first_error = None;

        let re = RE.get_or_init(|| {
            Regex::new(r"(?i)(?:^|[^0-9])(?:[a-z]+)?(\d+)\.(\d+)(?:\.(\d+))?([0-9a-z.+-]*)")
                .expect("invalid version regex")
        });

        for args in [&["--version"][..], &["-v"][..], &["-V"][..], &["version"][..]] {
            
            let output = match Command::new(bin).args(args).output() {
                Ok(output) => output,
                Err(err) => {
                    if first_error.is_none() { first_error = Some(err); }
                    continue;
                }
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
                    if Version::parse(&version).is_ok() { return Ok(version); }

                }

            }

        }

        if let Some(err) = first_error { return Err(err.into()); }
        Err(AppError::message(format!("failed to detect version for {bin}")))

    }

}
