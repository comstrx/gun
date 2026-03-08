
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Manager {
    Brew,
    Apt,
    Dnf,
    Yum,
    Pacman,
    Zypper,
    Apk,
    Winget,
    Scoop,
    Choco,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Info {
    pub id       : Option<String>,
    pub bin      : Option<String>,
    pub path     : Option<std::path::PathBuf>,
    pub version  : Option<String>,
    pub url      : Option<String>,
    pub source   : Option<String>,
    pub exists   : bool,
}
