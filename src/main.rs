pub mod core;
pub mod test;

fn main () -> core::AppExitCode {

    match test::main() {
        Ok(()) => core::AppExitCode::SUCCESS,
        Err(error) => error.report(),
    }

}
