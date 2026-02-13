import { describe, expect, it } from "vitest"
import { hello_world } from "../src/index"

describe("demo", () => {
    it("returns Hello World", () => {
        expect(hello_world()).toBe("Hello World");
    });
});
