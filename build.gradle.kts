plugins {
    kotlin("jvm") version "1.9.22"
    id("io.ktor.plugin") version "2.3.10"
    kotlin("plugin.serialization") version "1.9.22"
}

group = "com.altuslink"
version = "1.0.0"

application {
    mainClass.set("com.altuslink.ApplicationKt")
}

repositories {
    mavenCentral()
}

val ktorVersion = "2.3.10"
val plc4xVersion = "0.13.0"
val coroutinesVersion = "1.8.0"
val logbackVersion = "1.4.14"

dependencies {
    // Ktor server
    implementation("io.ktor:ktor-server-core-jvm:$ktorVersion")
    implementation("io.ktor:ktor-server-netty-jvm:$ktorVersion")
    implementation("io.ktor:ktor-server-websockets-jvm:$ktorVersion")
    implementation("io.ktor:ktor-server-content-negotiation-jvm:$ktorVersion")
    implementation("io.ktor:ktor-serialization-kotlinx-json-jvm:$ktorVersion")
    implementation("io.ktor:ktor-server-call-logging-jvm:$ktorVersion")
    implementation("io.ktor:ktor-server-config-yaml:$ktorVersion")
    implementation("io.ktor:ktor-server-cors-jvm:$ktorVersion")

    // PLC4X — OPC UA
    implementation("org.apache.plc4x:plc4j-api:$plc4xVersion")
    implementation("org.apache.plc4x:plc4j-driver-opcua:$plc4xVersion")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:$coroutinesVersion")

    // Logging
    implementation("ch.qos.logback:logback-classic:$logbackVersion")

    // Eclipse Milo — OPC UA simulator server
    implementation("org.eclipse.milo:sdk-server:0.6.12")
    implementation("org.eclipse.milo:sdk-client:0.6.12")

    // Test
    testImplementation("io.ktor:ktor-server-test-host-jvm:$ktorVersion")
    testImplementation("org.jetbrains.kotlin:kotlin-test")
}

tasks.test {
    useJUnitPlatform()
}

kotlin {
    jvmToolchain(17)
}
