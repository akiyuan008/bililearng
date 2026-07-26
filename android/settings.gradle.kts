// [PiliPlus Learning] Gradle 国内换源
// 仅修改项目内 settings.gradle.kts,不修改全局 ~/.gradle。
// pluginManagement 与 dependencyResolutionManagement 的 repositories
// 均优先使用阿里云镜像,google()/mavenCentral() 保留在末尾作兜底,
// 既防止国内编译超时,又避免镜像缺失个别包。
//
// 注意:根 build.gradle.kts 的 allprojects{repositories{}} 已声明项目级仓库,
// 因此这里必须用 PREFER_SETTINGS(镜像优先、项目仓库兜底),
// 不能用 FAIL_ON_PROJECT_REPOS,否则 Gradle 会因"项目声明了仓库"直接报错失败。
pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // 阿里云镜像换源
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        // 兜底(放最后,优先级最低)
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        // 阿里云镜像换源
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        // 兜底(放最后,优先级最低)
        google()
        mavenCentral()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.4.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
}

include(":app")
