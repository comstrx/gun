use std::sync::OnceLock;
use semver::Version;
use regex::Regex;

use crate::core::app::{AppResult, AppError};
use super::arch::{Manager, Tool, Spec, Info, Method};
use super::tree::TOOLS;

impl Tool {

    pub const fn new ( key : &'static str ) -> Self {

        Self {
            apt    : Spec::new(key),
            apk    : Spec::new(key),
            dnf    : Spec::new(key),
            yum    : Spec::new(key),
            pacman : Spec::new(key),
            zypper : Spec::new(key),
            brew   : Spec::new(key),
            winget : Spec::new(key),
            scoop  : Spec::new(key),
            choco  : Spec::new(key),
        }
    }

    pub const fn set ( mut self, manager: Manager, spec: Spec ) -> Self {

        match manager {
            Manager::Apt    => self.apt = spec,
            Manager::Apk    => self.apk = spec,
            Manager::Dnf    => self.dnf = spec,
            Manager::Yum    => self.yum = spec,
            Manager::Pacman => self.pacman = spec,
            Manager::Zypper => self.zypper = spec,
            Manager::Brew   => self.brew = spec,
            Manager::Winget => self.winget = spec,
            Manager::Scoop  => self.scoop = spec,
            Manager::Choco  => self.choco = spec,
        }

        self

    }


    pub fn get ( key: &str ) -> AppResult<Self> {

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

    pub fn spec ( key: &str ) -> AppResult<Spec> {

        let tool = Self::get(key)?;

        Ok(match Manager::detect()? {
            Manager::Apt    => tool.apt,
            Manager::Apk    => tool.apk,
            Manager::Dnf    => tool.dnf,
            Manager::Yum    => tool.yum,
            Manager::Pacman => tool.pacman,
            Manager::Zypper => tool.zypper,
            Manager::Brew   => tool.brew,
            Manager::Winget => tool.winget,
            Manager::Scoop  => tool.scoop,
            Manager::Choco  => tool.choco,
        })

    }


    pub fn info ( bin: &str ) -> AppResult<Info> {

        let mut data = Info {
            method  : Method::Native,
            id      : bin.to_string(),
            bin     : bin.to_string(),
            path    : Manager::path(bin).ok(),
            version : Self::version(bin).ok().filter(|value| !value.is_empty()),
            source  : None,
            exists  : false,
            args    : Vec::new(),
            aliases : Vec::new(),
        };
        if let Ok(spec) = Self::spec(bin) {

            data = Info {
                method  : spec.method,
                id      : if spec.id.is_empty() { bin.to_string() } else { spec.id.to_string() },
                bin     : if spec.bin.is_empty() { bin.to_string() } else { spec.bin.to_string() },
                path    : data.path.clone().or_else(|| (!spec.path.is_empty()).then(|| std::path::PathBuf::from(spec.path))),
                version : data.version.clone().or_else(|| (!spec.version.is_empty()).then(|| spec.version.to_string())),
                source  : (!spec.source.is_empty()).then(|| spec.source.to_string()),
                exists  : false,
                args    : spec.args.iter().map(|value| (*value).to_string()).collect(),
                aliases : spec.aliases.iter().map(|value| (*value).to_string()).collect(),
            };

        }

        Ok(Info { exists: data.path.is_some(), ..data })

    }

    pub fn show ( bin: &str ) -> AppResult<()> {

        let info = Self::info(bin)?;

        println!("id       : {}", info.id);
        println!("bin      : {}", info.bin);
        println!("path     : {}", info.path.as_deref().map(|path| path.to_string_lossy().into_owned()).unwrap_or_else(|| "unknown".into()));
        println!("version  : {}", info.version.as_deref().unwrap_or("unknown"));
        println!("source   : {}", info.source.as_deref().unwrap_or("unknown"));
        println!("exists   : {}", info.exists);

        Ok(())

    }

    pub fn version ( bin: &str ) -> AppResult<String> {

        let bin = if Manager::has(bin) { bin.to_string() } else { Manager::path(bin)?.to_string_lossy().into_owned() };
        let key = bin.as_str();

        static RE: OnceLock<Regex> = OnceLock::new();
        let mut first_error = None;

        let re = RE.get_or_init(|| {
            Regex::new(r"(?i)(?:^|[^0-9])(?:[a-z]+)?(\d+)\.(\d+)(?:\.(\d+))?([0-9a-z.+-]*)")
                .expect("invalid version regex")
        });

        for args in [&["--version"][..], &["-v"][..], &["-V"][..], &["version"][..]] {

            let output = match Manager::run_capture(key, args) {
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
        Err(AppError::message(format!("failed to detect version for {key}")))

    }

}
