package demo

import "testing"

func TestHello(t *testing.T) {
	if Hello("Core Master") != "hello, Core Master" {
		t.Fail()
	}
}
func BenchmarkHello(b *testing.B) {
	for b.Loop() {
		_ = Hello("Core Master")
	}
}
