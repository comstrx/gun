import { describe, expect, it } from "vitest"
import { hello } from "../src/index"

describe("hello", () => {
    it("returns Hello World", () => {
        expect(hello()).toBe("Hello World");
    });
});
