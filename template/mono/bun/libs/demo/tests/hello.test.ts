import { describe, expect, it } from "bun:test";
import { hello_world } from "../src/index"

describe("demo", () => {
    it("returns Hello World", () => {
        expect(hello_world()).toBe("Hello World");
    });
});
