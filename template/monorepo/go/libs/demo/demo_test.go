package demo

import "testing"

func TestHello(t *testing.T) {
	if Hello() != "Hello World" {
		t.Fail()
	}
}
func BenchmarkHello(b *testing.B) {
	for b.Loop() {
		_ = Hello()
	}
}
