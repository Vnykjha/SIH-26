allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        val targetCompat = project.extensions.findByType<com.android.build.gradle.BaseExtension>()
            ?.compileOptions?.targetCompatibility?.toString() ?: "17"
        compilerOptions {
            jvmTarget.set(
                when (targetCompat) {
                    "1.8", "8" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
                    "11" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
                    "17" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                    else -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                }
            )
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

