plugins {
    id("com.android.library") version "8.5.2"
    kotlin("android") version "2.1.0"
}

android {
    namespace = "com.mladenstojanovic.ingamereview"
    compileSdk = 35

    defaultConfig {
        minSdk = 21
        targetSdk = 35
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("com.google.android.play:review-ktx:2.0.2")
    implementation("org.godotengine:godot:4.5.1.stable")
}
