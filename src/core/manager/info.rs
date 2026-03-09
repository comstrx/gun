
use crate::core::app::{AppResult};
use super::arch::{Manager, Spec, Info, Method};

impl Info {

    pub fn get ( key: &str ) -> AppResult<Info> {

        let version = Manager::version(key).ok();
        let path = Manager::path(key).ok();
        let exists = path.is_some();

        let default = Info {
            method  : Method::Native,
            id      : key.to_string(),
            bin     : key.to_string(),
            path    : path,
            source  : Some(String::new()),
            version : version,
            exists  : exists,
            args    : Vec::new(),
            aliases : Vec::new(),
        };

        if let Ok(spec) = Spec::get(key) {

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

    pub fn show ( key: &str ) -> AppResult<()> {

        let info = Self::get(key)?;

        println!("id       : {}", info.id);
        println!("bin      : {}", info.bin);
        println!("path     : {}", info.path.as_deref().map(|path| path.to_string_lossy().into_owned()).unwrap_or_else(|| "-".into()));
        println!("version  : {}", info.version.as_deref().unwrap_or("-"));
        println!("source   : {}", info.source.as_deref().unwrap_or("-"));
        println!("exists   : {}", info.exists);

        Ok(())

    }

}
