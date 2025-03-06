plugins {
    application
}

repositories {
    mavenCentral()
}

dependencies {
    implementation(libs.hadoop)
    implementation(libs.iceberg.core)
    implementation(libs.iceberg.data)
    implementation(libs.iceberg.parquet)
    implementation(libs.parquet.column)
    implementation(libs.slf4j.api)

    runtimeOnly(libs.slf4j.simple)
}

application {
    mainClass.set("dgroomes.write_and_read.Main")
}
