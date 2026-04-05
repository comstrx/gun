
use super::arch::{Manager, Tool, Spec, Info, Method, Context, AppError, AppResult};
use super::index::TOOLS;

impl Manager {

    pub fn get ( bin: &str ) -> AppResult<Tool> {

        let has = |spec: &Spec| {

            let bin = bin.trim();
            let name = Context::get_or(bin, Context::Name, spec.name.to_string());
            let path = Context::get_or(bin, Context::Path, spec.path.to_string());
            let source = Context::get_or(bin, Context::Source, spec.source.to_string());

            spec.bin.eq_ignore_ascii_case(bin)
                || name.eq_ignore_ascii_case(bin)
                || path.eq_ignore_ascii_case(bin)
                || source.eq_ignore_ascii_case(bin)
                || spec.aliases.iter().any(|alias| alias.eq_ignore_ascii_case(bin))

        };
        TOOLS.iter().find(|(name, tool)| {
            name.eq_ignore_ascii_case(bin)
                || has(&tool.apt)
                || has(&tool.apk)
                || has(&tool.dnf)
                || has(&tool.yum)
                || has(&tool.nix)
                || has(&tool.pacman)
                || has(&tool.zypper)
                || has(&tool.brew)
                || has(&tool.winget)
                || has(&tool.scoop)
                || has(&tool.choco)
        }).map(|(_, tool)| *tool).ok_or_else(|| AppError::unsupported_tool(bin))

    }

    pub fn spec ( bin: &str ) -> AppResult<Spec> {

        let tool = Self::get(bin)?;

        Ok(match Self::detect()? {
            Self::Apt    => tool.apt,
            Self::Apk    => tool.apk,
            Self::Dnf    => tool.dnf,
            Self::Yum    => tool.yum,
            Self::Nix    => tool.nix,
            Self::Pacman => tool.pacman,
            Self::Zypper => tool.zypper,
            Self::Brew   => tool.brew,
            Self::Winget => tool.winget,
            Self::Scoop  => tool.scoop,
            Self::Choco  => tool.choco,
        })

    }

    pub fn info ( bin: &str ) -> Info {

        let mut data = Info {
            method  : Method::Native,
            bin     : bin.to_string(),
            name    : None,
            source  : None,
            path    : Self::path(bin),
            version : Self::version(bin),
            args    : Vec::new(),
            aliases : Vec::new(),
            exists  : false,
        };
        if let Ok(spec) = Self::spec(bin) {

            let name = Context::get_or(bin, Context::Name, spec.name.to_string());
            let path = Context::get_or(bin, Context::Path, spec.path.to_string());
            let source = Context::get_or(bin, Context::Source, spec.source.to_string());
            let version = Context::get_or(bin, Context::Version, spec.version.to_string());

            data = Info {
                method  : spec.method,
                bin     : spec.bin.to_string(),
                name    : Some(name),
                source  : Some(source),
                path    : data.path.clone().or_else(|| (!path.is_empty()).then(|| path.into())),
                version : data.version.clone().or_else(|| (!version.is_empty()).then(|| version)),
                args    : spec.args.iter().map(|value| (*value).to_string()).collect(),
                aliases : spec.aliases.iter().map(|value| (*value).to_string()).collect(),
                exists  : false,
            };

        }

        Info { exists: data.path.is_some(), ..data }

    }

    pub fn show ( bin: &str ) {

        let info = Self::info(bin);

        println!("bin      : {}", info.bin);
        println!("name     : {}", info.name.as_deref().unwrap_or(bin));
        println!("version  : {}", info.version.as_deref().unwrap_or("unknown"));
        println!("source   : {}", info.source.as_deref().unwrap_or("unknown"));
        println!("path     : {}", info.path.as_deref().map(|path| path.to_string_lossy().into_owned()).unwrap_or_else(|| "unknown".into()));
        println!("exists   : {}", info.exists);

    }

    pub fn installing ( bin: &str, latest: bool ) -> AppResult<()> {

        match Self::spec(bin) {
            Ok(spec) => {
                let name = Context::get_or(bin, Context::Name, spec.name.to_string());
                let source = Context::get_or(bin, Context::Source, spec.source.to_string());
                let version = Context::get_or(bin, Context::Version, spec.version.to_string());

                let args = spec.args;
                let id = if name.is_empty() { bin.trim() } else { &name };
                let source = if source.is_empty() { id } else { &source };
                let target = if latest { "" } else { &version };

                match spec.method {
                    Method::Native => Self::native_install(source, target),
                    Method::Nix    => Self::nix_install(source, target),
                    Method::Snap   => Self::snap_install(source, target),
                    Method::Mise   => Self::mise_install(source, target),
                    Method::Bash   => Self::script_install(id, source, &version, args, true),
                    Method::Shell  => Self::script_install(id, source, &version, args, false),
                }
            },
            Err(_) => {
                let version = Context::get(bin, Context::Version);
                let target = if latest { String::new() } else { version };

                Self::native_install(bin.trim(), &target)
            },
        }

    }

    pub fn removing ( bin: &str ) -> AppResult<()> {

        let id = match Self::spec(bin) {
            Ok(spec) => {
                let name   = Context::get_or(bin, Context::Name, spec.name.to_string());
                let source = Context::get_or(bin, Context::Source, spec.source.to_string());

                let id = if name.is_empty() { spec.bin } else { &name };
                let target = if source.is_empty() { id } else { &source };

                target.to_string()
            }
            Err(_) => bin.trim().to_string(),
        };

        if Self::has("nix")  { let _ = Self::nix_remove(&id); }
        if Self::has("snap") { let _ = Self::snap_remove(&id); }
        if Self::has("mise") { let _ = Self::mise_remove(&id); }

        let _ = Self::native_remove(&id);
        Ok(())

    }


    pub fn has ( bin: &str ) -> bool {

        Self::path(bin).is_some()

    }

    pub fn need ( bin: &str ) -> AppResult<()> {

        if Self::has(bin) { return Ok(()); }
        Err(AppError::missing_tool(bin))

    }

    pub fn install ( bin: &str ) -> AppResult<()> {

        Self::installing(bin, false)

    }

    pub fn remove ( bin: &str ) -> AppResult<()> {

        Self::removing(bin)

    }

    pub fn upgrade ( bin: &str ) -> AppResult<()> {

        Self::removing(bin)?;
        Self::installing(bin, true)

    }

    pub fn ensure ( bin: &str ) -> AppResult<()> {

        if !Self::has(bin) { Self::install(bin)?; }
        if Self::version(bin).is_some() { return Ok(()); }

        let spec = Self::spec(bin)?;

        if !spec.bin.is_empty() && Self::version(spec.bin).is_some() { return Ok(()) }
        if !spec.path.is_empty() && Self::version(spec.path).is_some() { return Ok(()); }

        Err(AppError::missing_tool(bin))

    }

    pub fn reinstall ( bin: &str ) -> AppResult<()> {

        Self::remove(bin)?;
        Self::install(bin)

    }


    pub fn has_all ( bins: &[&str] ) -> bool {

        bins.iter().all(|bin| Self::has(bin))

    }

    pub fn has_any ( bins: &[&str] ) -> bool {

        bins.iter().any(|bin| Self::has(bin))

    }

    pub fn need_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::need(bin)?; }
        Ok(())

    }

    pub fn install_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::install(bin)?; }
        Ok(())

    }

    pub fn remove_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::remove(bin)?; }
        Ok(())

    }

    pub fn upgrade_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::upgrade(bin)?; }
        Ok(())

    }

    pub fn ensure_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::ensure(bin)?; }
        Ok(())

    }

    pub fn reinstall_all ( bins: &[&str] ) -> AppResult<()> {

        for &bin in bins { Self::reinstall(bin)?; }
        Ok(())

    }

}
