use std::process::Command;
use std::sync::OnceLock;
use semver::Version;
use std::time::{Instant, Duration};
use regex::Regex;
use which::which;

use crate::core::error::{AppResult, AppError};
use super::base::Manager;

impl Manager {

    pub fn has ( binary: &str ) -> bool {

        which(binary).is_ok()

    }

    pub fn need ( binary: &str ) -> AppResult<()> {

        if which(binary).is_err() { return Err(AppError::missing_binary(binary)); }
        Ok(())

    }

    pub fn measure <T> ( callback: impl FnOnce() -> AppResult<T> ) -> AppResult<Duration> {

        let start = Instant::now();

        callback()?;

        Ok(start.elapsed())

    }

    pub fn version ( binary: &str ) -> AppResult<String> {

        Self::need(binary)?;

        static RE: OnceLock<Regex> = OnceLock::new();
        let mut first_error = None;

        let re = RE.get_or_init(|| {
            Regex::new(r"(?i)(?:^|[^0-9])(?:[a-z]+)?(\d+)\.(\d+)(?:\.(\d+))?([0-9a-z.+-]*)")
                .expect("invalid version regex")
        });

        for args in [&["--version"][..], &["-v"][..], &["-V"][..], &["version"][..]] {

            let output = match Command::new(binary).args(args).output() {
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
        Err(AppError::message(format!("failed to detect semver for {binary}")))

    }

}
