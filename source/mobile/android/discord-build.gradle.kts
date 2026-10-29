// Lime root Gradle template with Discord Social SDK dependencies.
import org.gradle.api.tasks.compile.JavaCompile

buildscript {
    repositories { mavenCentral(); google() }
    dependencies {
        classpath("com.android.tools.build:gradle:::ANDROID_GRADLE_PLUGIN::")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
    }
}

allprojects {
    repositories { mavenCentral(); google() }
    ::if ANDROID_GRADLE_BUILD_DIRECTORY::layout.buildDirectory.set(File("::ANDROID_GRADLE_BUILD_DIRECTORY::/::APP_FILE::/${project.name}"))::end::
}

subprojects {
    tasks.withType<JavaCompile>().configureEach { options.compilerArgs.add("-Xlint:-options") }

    plugins.withId("com.android.application") {
		if (name == "app") {
			dependencies {
				add("implementation", files("libs/discord_partner_sdk.aar"))
				add("implementation", "androidx.browser:browser:1.8.0")
			}
		}
        extensions.configure<com.android.build.gradle.BaseExtension>("android") {
			defaultConfig {
				ndk {
					abiFilters.clear()
					abiFilters.add("arm64-v8a")
				}
			}
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }

    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.BaseExtension>("android") {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
}

tasks.register<Delete>("clean") { delete(rootProject.layout.buildDirectory) }

tasks.wrapper {
    gradleVersion = "::ANDROID_GRADLE_VERSION::"
    distributionType = Wrapper.DistributionType.BIN
}

configure(subprojects.filter { !it.file("build.gradle.kts").exists() && !it.file("build.gradle").exists() && it.file("build.xml").exists() }) {
    buildscript {
        repositories { mavenCentral(); google() }
        dependencies { classpath("com.android.tools.build:gradle:::ANDROID_GRADLE_PLUGIN::") }
    }
    apply(plugin = "com.android.library")
    configure<com.android.build.gradle.LibraryExtension> {
        compileSdk = project.property("ANDROID_BUILD_SDK_VERSION").toString().toInt()
        buildToolsVersion = project.property("ANDROID_BUILD_TOOLS_VERSION").toString()
        ::if (ANDROID_GRADLE_PLUGIN>="4.0")::ndkPath = "::ANDROID_NDK_ROOT_ESCAPED::"::end::
        ::if (ANDROID_GRADLE_PLUGIN>="4.0")::ndkVersion = "::ANDROID_NDK_VERSION::"::end::
        sourceSets {
            getByName("main") {
                manifest.srcFile("AndroidManifest.xml")
                java.srcDirs("src")
                res.srcDirs("res")
            }
        }
    }
    dependencies {
        add("implementation", project(":deps:extension-api"))
        add("implementation", project(":deps:androidtools"))
    }
}
