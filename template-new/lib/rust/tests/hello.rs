use demo::hello_world;

#[test]
fn hello_world_test() {
    assert_eq!(hello_world(), "Hello World");
}
