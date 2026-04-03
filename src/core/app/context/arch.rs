use std::{collections::HashMap, sync::{OnceLock, RwLock}};

pub type ContextMap = HashMap<String, ContextValue>;

pub static CONTEXT: OnceLock<RwLock<ContextMap>> = OnceLock::new();

#[derive(Debug, Clone, Default, PartialEq)]
pub struct AppContext;

#[derive(Debug, Clone, PartialEq)]
pub enum ContextValue {
    Null,
    Int(i64),
    UInt(u64),
    Float(f64),
    Bool(bool),
    Text(String),
    Bytes(Vec<u8>),
    List(Vec<ContextValue>),
    Map(HashMap<String, ContextValue>),
}
