
plugins {
    application
    id("com.diffplug.spotless") version "8.2.1"
}

repositories {
    mavenCentral()
}

dependencies {
    implementation(libs.guava)
}

testing {
    suites {
        val test by getting(JvmTestSuite::class) {
            useJUnitJupiter("5.12.1")
        }
    }
}

spotless {
    ratchetFrom("origin/main")

    java {
        target("src/**/*.java")
        targetExclude("**/build/**", "**/out/**")

        googleJavaFormat("1.34.1")
        removeUnusedImports()
        trimTrailingWhitespace()
        endWithNewline()
    }
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(25)
    }
}

application {
    mainClass = "com.demo.App"
}
