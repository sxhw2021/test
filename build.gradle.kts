buildscript {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        maven("https://api.xposed.info/")
    }
    
    dependencies {
        classpath("com.android.tools.build:gradle:8.9.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
        classpath("com.google.devtools.ksp:com.google.devtools.ksp.gradle.plugin:2.1.0-1.0.29")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven("https://api.xposed.info/")
        maven("https://jitpack.io")
    }
}
