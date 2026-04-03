use std::collections::HashMap;

use super::arch::ContextValue;

impl From <()> for ContextValue {

    fn from ( _: () ) -> Self {

        Self::Null

    }

}

impl From <i8> for ContextValue {

    fn from ( value: i8 ) -> Self {

        Self::Int(value as i64)

    }

}

impl From <u8> for ContextValue {

    fn from ( value: u8 ) -> Self {

        Self::UInt(value as u64)

    }

}

impl From <i16> for ContextValue {

    fn from ( value: i16 ) -> Self {

        Self::Int(value as i64)

    }

}

impl From <u16> for ContextValue {

    fn from ( value: u16 ) -> Self {

        Self::UInt(value as u64)

    }

}

impl From <i32> for ContextValue {

    fn from ( value: i32 ) -> Self {

        Self::Int(value as i64)

    }

}

impl From <u32> for ContextValue {

    fn from ( value: u32 ) -> Self {

        Self::UInt(value as u64)

    }

}

impl From <i64> for ContextValue {

    fn from ( value: i64 ) -> Self {

        Self::Int(value)

    }

}

impl From <u64> for ContextValue {

    fn from ( value: u64 ) -> Self {

        Self::UInt(value)

    }

}

impl From <f32> for ContextValue {

    fn from ( value: f32 ) -> Self {

        Self::Float(value as f64)

    }

}

impl From <f64> for ContextValue {

    fn from ( value: f64 ) -> Self {

        Self::Float(value)

    }

}

impl From <bool> for ContextValue {

    fn from ( value: bool ) -> Self {

        Self::Bool(value)

    }

}

impl From <String> for ContextValue {

    fn from ( value: String ) -> Self {

        Self::Text(value)

    }

}

impl From <Vec<u8>> for ContextValue {

    fn from ( value: Vec<u8> ) -> Self {

        Self::Bytes(value)

    }

}

impl From <Vec<ContextValue>> for ContextValue {

    fn from ( value: Vec<ContextValue> ) -> Self {

        Self::List(value)

    }

}

impl From <HashMap<String, ContextValue>> for ContextValue {

    fn from ( value: HashMap<String, ContextValue> ) -> Self {

        Self::Map(value)

    }

}

impl From <&str> for ContextValue {

    fn from ( value: &str ) -> Self {

        Self::Text(value.to_string())

    }

}

impl From <&[u8]> for ContextValue {

    fn from ( value: &[u8] ) -> Self {

        Self::Bytes(value.to_vec())

    }

}

impl TryFrom <i128> for ContextValue {

    type Error = ();

    fn try_from ( value: i128 ) -> Result<Self, Self::Error> {

        match i64::try_from(value) {
            Ok(value) => Ok(Self::Int(value)),
            Err(_) => Err(()),
        }

    }

}

impl TryFrom <u128> for ContextValue {

    type Error = ();

    fn try_from ( value: u128 ) -> Result<Self, Self::Error> {

        match u64::try_from(value) {
            Ok(value) => Ok(Self::UInt(value)),
            Err(_) => Err(()),
        }

    }

}

impl TryFrom <isize> for ContextValue {

    type Error = ();

    fn try_from ( value: isize ) -> Result<Self, Self::Error> {

        match i64::try_from(value) {
            Ok(value) => Ok(Self::Int(value)),
            Err(_) => Err(()),
        }

    }

}

impl TryFrom <usize> for ContextValue {

    type Error = ();

    fn try_from ( value: usize ) -> Result<Self, Self::Error> {

        match u64::try_from(value) {
            Ok(value) => Ok(Self::UInt(value)),
            Err(_) => Err(()),
        }

    }

}

impl <T> From <Option<T>> for ContextValue where T: Into<ContextValue> {

    fn from ( value: Option<T> ) -> Self {

        match value {
            Some(value) => value.into(),
            None => Self::Null,
        }

    }

}


impl TryFrom <ContextValue> for () {

    type Error = ();

    fn try_from ( value: ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Null => Ok(()),
            _ => Err(()),
        }

    }

}

impl TryFrom <ContextValue> for i8 {

    type Error = ();

    fn try_from ( value: ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Int(value) => i8::try_from(value).map_err(|_| ()),
            _ => Err(()),
        }

    }

}

impl TryFrom <ContextValue> for u8 {

    type Error = ();

    fn try_from ( value: ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::UInt(value) => u8::try_from(value).map_err(|_| ()),
            ContextValue::Int(value)  => u8::try_from(value).map_err(|_| ()),
            _ => Err(()),
        }

    }

}

impl TryFrom <ContextValue> for i16 {

    type Error = ();

    fn try_from ( value: ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Int(value) => i16::try_from(value).map_err(|_| ()),
            _ => Err(()),
        }

    }

}

impl TryFrom <ContextValue> for u16 {

    type Error = ();

    fn try_from ( value: ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::UInt(value) => u16::try_from(value).map_err(|_| ()),
            ContextValue::Int(value)  => u16::try_from(value).map_err(|_| ()),
            _ => Err(()),
        }

    }

}

impl TryFrom <ContextValue> for i32 {

    type Error = ();

    fn try_from ( value: ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Int(value) => i32::try_from(value).map_err(|_| ()),
            _ => Err(()),
        }

    }

}

impl TryFrom <ContextValue> for u32 {

    type Error = ();

    fn try_from ( value: ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::UInt(value) => u32::try_from(value).map_err(|_| ()),
            ContextValue::Int(value)  => u32::try_from(value).map_err(|_| ()),
            _ => Err(()),
        }

    }

}

impl TryFrom <ContextValue> for i64 {

    type Error = ();

    fn try_from ( value: ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Int(value) => Ok(value),
            _ => Err(()),
        }

    }

}

impl TryFrom <ContextValue> for u64 {

    type Error = ();

    fn try_from ( value: ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::UInt(value) => Ok(value),
            ContextValue::Int(value)  => u64::try_from(value).map_err(|_| ()),
            _ => Err(()),
        }

    }

}

impl TryFrom <ContextValue> for i128 {

    type Error = ();

    fn try_from ( value: ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Int(value) => Ok(value as i128),
            _ => Err(()),
        }

    }

}

impl TryFrom <ContextValue> for u128 {

    type Error = ();

    fn try_from ( value: ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::UInt(value) => u128::try_from(value).map_err(|_| ()),
            ContextValue::Int(value)  => u128::try_from(value).map_err(|_| ()),
            _ => Err(()),
        }

    }

}

impl TryFrom <ContextValue> for isize {

    type Error = ();

    fn try_from ( value: ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Int(value) => isize::try_from(value).map_err(|_| ()),
            _ => Err(()),
        }

    }

}

impl TryFrom <ContextValue> for usize {

    type Error = ();

    fn try_from ( value: ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::UInt(value) => usize::try_from(value).map_err(|_| ()),
            ContextValue::Int(value)  => usize::try_from(value).map_err(|_| ()),
            _ => Err(()),
        }

    }

}

impl TryFrom <ContextValue> for f32 {

    type Error = ();

    fn try_from ( value: ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Float(value) => Ok(value as f32),
            ContextValue::Int(value)   => Ok(value as f32),
            ContextValue::UInt(value)  => Ok(value as f32),
            _ => Err(()),
        }

    }

}

impl TryFrom <ContextValue> for f64 {

    type Error = ();

    fn try_from ( value: ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Float(value) => Ok(value),
            ContextValue::Int(value)   => Ok(value as f64),
            ContextValue::UInt(value)  => Ok(value as f64),
            _ => Err(()),
        }

    }

}

impl TryFrom <ContextValue> for bool {

    type Error = ();

    fn try_from ( value: ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Bool(value) => Ok(value),
            _ => Err(()),
        }

    }

}

impl TryFrom <ContextValue> for String {

    type Error = ();

    fn try_from ( value: ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Text(value) => Ok(value),
            _ => Err(()),
        }

    }

}

impl TryFrom <ContextValue> for Vec<u8> {

    type Error = ();

    fn try_from ( value: ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Bytes(value) => Ok(value),
            _ => Err(()),
        }

    }

}

impl TryFrom <ContextValue> for Vec<ContextValue> {

    type Error = ();

    fn try_from ( value: ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::List(value) => Ok(value),
            _ => Err(()),
        }

    }

}

impl TryFrom <ContextValue> for HashMap<String, ContextValue> {

    type Error = ();

    fn try_from ( value: ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Map(value) => Ok(value),
            _ => Err(()),
        }

    }

}


impl TryFrom <&ContextValue> for () {

    type Error = ();

    fn try_from ( value: &ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Null => Ok(()),
            _ => Err(()),
        }

    }

}

impl TryFrom <&ContextValue> for i8 {

    type Error = ();

    fn try_from ( value: &ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Int(value) => i8::try_from(*value).map_err(|_| ()),
            _ => Err(()),
        }

    }

}

impl TryFrom <&ContextValue> for u8 {

    type Error = ();

    fn try_from ( value: &ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::UInt(value) => u8::try_from(*value).map_err(|_| ()),
            ContextValue::Int(value)  => u8::try_from(*value).map_err(|_| ()),
            _ => Err(()),
        }

    }

}

impl TryFrom <&ContextValue> for i16 {

    type Error = ();

    fn try_from ( value: &ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Int(value) => i16::try_from(*value).map_err(|_| ()),
            _ => Err(()),
        }

    }

}

impl TryFrom <&ContextValue> for u16 {

    type Error = ();

    fn try_from ( value: &ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::UInt(value) => u16::try_from(*value).map_err(|_| ()),
            ContextValue::Int(value)  => u16::try_from(*value).map_err(|_| ()),
            _ => Err(()),
        }

    }

}

impl TryFrom <&ContextValue> for i32 {

    type Error = ();

    fn try_from ( value: &ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Int(value) => i32::try_from(*value).map_err(|_| ()),
            _ => Err(()),
        }

    }

}

impl TryFrom <&ContextValue> for u32 {

    type Error = ();

    fn try_from ( value: &ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::UInt(value) => u32::try_from(*value).map_err(|_| ()),
            ContextValue::Int(value)  => u32::try_from(*value).map_err(|_| ()),
            _ => Err(()),
        }

    }

}

impl TryFrom <&ContextValue> for i64 {

    type Error = ();

    fn try_from ( value: &ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Int(value) => Ok(*value),
            _ => Err(()),
        }

    }

}

impl TryFrom <&ContextValue> for u64 {

    type Error = ();

    fn try_from ( value: &ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::UInt(value) => Ok(*value),
            ContextValue::Int(value)  => u64::try_from(*value).map_err(|_| ()),
            _ => Err(()),
        }

    }

}

impl TryFrom <&ContextValue> for i128 {

    type Error = ();

    fn try_from ( value: &ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Int(value) => Ok(*value as i128),
            _ => Err(()),
        }

    }

}

impl TryFrom <&ContextValue> for u128 {

    type Error = ();

    fn try_from ( value: &ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::UInt(value) => u128::try_from(*value).map_err(|_| ()),
            ContextValue::Int(value)  => u128::try_from(*value).map_err(|_| ()),
            _ => Err(()),
        }

    }

}

impl TryFrom <&ContextValue> for isize {

    type Error = ();

    fn try_from ( value: &ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Int(value) => isize::try_from(*value).map_err(|_| ()),
            _ => Err(()),
        }

    }

}

impl TryFrom <&ContextValue> for usize {

    type Error = ();

    fn try_from ( value: &ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::UInt(value) => usize::try_from(*value).map_err(|_| ()),
            ContextValue::Int(value)  => usize::try_from(*value).map_err(|_| ()),
            _ => Err(()),
        }

    }

}

impl TryFrom <&ContextValue> for f32 {

    type Error = ();

    fn try_from ( value: &ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Float(value) => Ok(*value as f32),
            ContextValue::Int(value)   => Ok(*value as f32),
            ContextValue::UInt(value)  => Ok(*value as f32),
            _ => Err(()),
        }

    }

}

impl TryFrom <&ContextValue> for f64 {

    type Error = ();

    fn try_from ( value: &ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Float(value) => Ok(*value),
            ContextValue::Int(value)   => Ok(*value as f64),
            ContextValue::UInt(value)  => Ok(*value as f64),
            _ => Err(()),
        }

    }

}

impl TryFrom <&ContextValue> for bool {

    type Error = ();

    fn try_from ( value: &ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Bool(value) => Ok(*value),
            _ => Err(()),
        }

    }

}

impl TryFrom <&ContextValue> for String {

    type Error = ();

    fn try_from ( value: &ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Text(value) => Ok(value.clone()),
            _ => Err(()),
        }

    }

}

impl TryFrom <&ContextValue> for Vec<u8> {

    type Error = ();

    fn try_from ( value: &ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Bytes(value) => Ok(value.clone()),
            _ => Err(()),
        }

    }

}

impl TryFrom <&ContextValue> for Vec<ContextValue> {

    type Error = ();

    fn try_from ( value: &ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::List(value) => Ok(value.clone()),
            _ => Err(()),
        }

    }

}

impl TryFrom <&ContextValue> for HashMap<String, ContextValue> {

    type Error = ();

    fn try_from ( value: &ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Map(value) => Ok(value.clone()),
            _ => Err(()),
        }

    }

}

impl<'a> TryFrom <&'a ContextValue> for &'a str {

    type Error = ();

    fn try_from ( value: &'a ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Text(value) => Ok(value.as_str()),
            _ => Err(()),
        }

    }

}

impl<'a> TryFrom <&'a ContextValue> for &'a [u8] {

    type Error = ();

    fn try_from ( value: &'a ContextValue ) -> Result<Self, Self::Error> {

        match value {
            ContextValue::Bytes(value) => Ok(value.as_slice()),
            _ => Err(()),
        }

    }

}
