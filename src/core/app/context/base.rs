use std::{collections::{HashMap, hash_map}, sync::RwLock};

pub use crate::core::app::{AppError, AppResult};
use super::arch::{AppContext, ContextValue, ContextMap, CONTEXT};

impl AppContext {

    pub fn inner () -> &'static RwLock<ContextMap> {

        CONTEXT.get_or_init(|| RwLock::new(HashMap::new()))

    }

    pub fn value <K> ( key: K ) -> Option<ContextValue> where K: AsRef<str> {

        match Self::inner().read() {
            Ok(data) => data.get(key.as_ref()).cloned(),
            Err(_) => None,
        }

    }


    pub fn set <K, V> ( key: K, value: V ) -> AppResult<()> where K: Into<String>, V: Into<ContextValue> {

        match Self::inner().write() {
            Ok(mut data) => {
                data.insert(key.into(), value.into());
                Ok(())
            }
            Err(_) => Err(AppError::operation_failed("context", "cannot set context value")),
        }

    }

    pub fn set_once <K, V> ( key: K, value: V ) -> AppResult<()> where K: Into<String>, V: Into<ContextValue> {

        match Self::inner().write() {
            Ok(mut data) => match data.entry(key.into()) {
                hash_map::Entry::Vacant(entry) => {
                    entry.insert(value.into());
                    Ok(())
                }
                hash_map::Entry::Occupied(_) => Ok(()),
            }
            Err(_) => Err(AppError::operation_failed("context", "cannot set context value")),
        }

    }

    pub fn extend <I, K, V> ( iter: I ) -> AppResult<()> where I: IntoIterator<Item = (K, V)>, K: Into<String>, V: Into<ContextValue> {

        match Self::inner().write() {
            Ok(mut data) => {
                for (key, value) in iter {
                    data.insert(key.into(), value.into());
                }
                Ok(())
            }
            Err(_) => Err(AppError::operation_failed("context", "cannot extend context data")),
        }

    }


    pub fn get <K, T> ( key: K ) -> Option<T> where K: AsRef<str>, for<'a> T: TryFrom<&'a ContextValue> {

        match Self::inner().read() {
            Ok(data) => data.get(key.as_ref()).and_then(|value| T::try_from(value).ok()),
            Err(_) => None,
        }

    }

    pub fn get_or <K, T> ( key: K, default: T ) -> T where K: AsRef<str>, for<'a> T: TryFrom<&'a ContextValue> {

        Self::get(key).unwrap_or(default)

    }

    pub fn get_or_else <K, T, F> ( key: K, default: F ) -> T where K: AsRef<str>, for<'a> T: TryFrom<&'a ContextValue>, F: FnOnce() -> T {

        Self::get(key).unwrap_or_else(default)

    }


    pub fn has <K> ( key: K ) -> bool where K: AsRef<str> {

        match Self::inner().read() {
            Ok(data) => data.contains_key(key.as_ref()),
            Err(_) => false,
        }

    }

    pub fn need <K> ( key: K ) -> AppResult<()> where K: AsRef<str> {

        if !Self::has(key.as_ref()) { Err(AppError::missing_key(key.as_ref())) }
        else { Ok(()) }

    }

    pub fn remove <K> ( key: K ) -> AppResult<()> where K: AsRef<str> {

        match Self::inner().write() {
            Ok(mut data) => {
                data.remove(key.as_ref());
                Ok(())
            },
            Err(_) => Err(AppError::operation_failed("context", "cannot remove context key")),
        }

    }

    pub fn clear () -> AppResult<()> {

        match Self::inner().write() {
            Ok(mut data) => {
                data.clear();
                Ok(())
            }
            Err(_) => Err(AppError::operation_failed("context", "cannot clear context")),
        }

    }


    pub fn len () -> usize {

        match Self::inner().read() {
            Ok(data) => data.len(),
            Err(_) => 0,
        }

    }

    pub fn is_empty () -> bool {

        Self::len() == 0

    }

    pub fn keys () -> Vec<String> {

        match Self::inner().read() {
            Ok(data) => data.keys().cloned().collect(),
            Err(_) => Vec::new(),
        }

    }

    pub fn values () -> Vec<ContextValue> {

        match Self::inner().read() {
            Ok(data) => data.values().cloned().collect(),
            Err(_) => Vec::new(),
        }

    }

    pub fn entries () -> Vec<(String, ContextValue)> {

        match Self::inner().read() {
            Ok(data) => data.iter().map(|(key, value)| (key.clone(), value.clone())).collect(),
            Err(_) => Vec::new(),
        }

    }


    pub fn with <R, F> ( func: F ) -> AppResult<R> where F: FnOnce(&ContextMap) -> R {

        match Self::inner().read() {
            Ok(data) => Ok(func(&data)),
            Err(_) => Err(AppError::operation_failed("context", "cannot read context data")),
        }

    }

    pub fn with_mut <R, F> ( func: F ) -> AppResult<R> where F: FnOnce(&mut ContextMap) -> R {

        match Self::inner().write() {
            Ok(mut data) => Ok(func(&mut data)),
            Err(_) => Err(AppError::operation_failed("context", "cannot write context data")),
        }

    }

    pub fn retain <F> ( mut keep: F ) -> AppResult<()> where F: FnMut(&str, &ContextValue) -> bool {

        match Self::inner().write() {
            Ok(mut data) => {
                data.retain(|key, value| keep(key, value));
                Ok(())
            }
            Err(_) => Err(AppError::operation_failed("context", "cannot retain context data")),
        }

    }

}
