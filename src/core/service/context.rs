
use super::arch::{Context, AppContext, ContextValue, AppResult};

impl Context {

    pub fn as_str ( self ) -> &'static str {

        match self {
            Self::Name    => "name",
            Self::Path    => "path",
            Self::Source  => "source",
            Self::Version => "version",
        }

    }

    pub fn key <N> ( service: N, key: Self ) -> String where N: AsRef<str> {

        format!("service.{}.{}", service.as_ref().trim(), key.as_str().trim())

    }

    pub fn set <N, V> ( service: N, key: Self, value: V ) -> AppResult<()> where N: AsRef<str>, V: Into<ContextValue> {

        AppContext::set(Self::key(service, key), value)

    }

    pub fn get <N, T> ( service: N, key: Self ) -> T where N: AsRef<str>, for<'a> T: TryFrom<&'a ContextValue> + Default {

        AppContext::get(Self::key(service, key)).unwrap_or_default()

    }

    pub fn get_or <N, T> ( service: N, key: Self, default: T ) -> T where N: AsRef<str>, for<'a> T: TryFrom<&'a ContextValue> {

        AppContext::get_or(Self::key(service, key), default)

    }

}
