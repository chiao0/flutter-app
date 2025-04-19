// android/build.gradle.kts
buildscript {
    repositories {
        google()  // 確保已添加
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.7.0")          // 與你的 settings.gradle 版本一致
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.0.0") // 與你的 settings.gradle 版本一致
        classpath("com.google.gms:google-services:4.4.1")           // 新增此行，使用最新版本
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
