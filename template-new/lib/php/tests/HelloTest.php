<?php

namespace User\Demo\Tests;

use PHPUnit\Framework\TestCase;
use User\Demo\Hello;

final class HelloTest extends TestCase {

    public function test_world_returns_hello_world(): void {

        self::assertSame('Hello World', Hello::world());

    }

}
