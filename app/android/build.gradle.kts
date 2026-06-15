allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    if (name == "app") {
        layout.buildDirectory.set(rootProject.layout.projectDirectory.dir("../build/app"))
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.projectDirectory.dir("../build"))
    delete(rootProject.layout.buildDirectory)
}
