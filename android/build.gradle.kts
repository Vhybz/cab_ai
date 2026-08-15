import com.android.build.gradle.BaseExtension

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

rootProject.extra.set("compileSdkVersion", 35)
rootProject.extra.set("buildToolsVersion", "35.0.0")
rootProject.extra.set("minSdkVersion", 26)
rootProject.extra.set("targetSdkVersion", 35)

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    afterEvaluate {
        val p = this
        if (p.extensions.findByName("android") != null) {
            val android = p.extensions.getByName("android") as BaseExtension
            android.compileSdkVersion(35)
            android.buildToolsVersion("35.0.0")
            
            android.defaultConfig {
                targetSdk = 35
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
