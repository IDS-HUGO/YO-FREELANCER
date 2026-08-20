allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // El plugin flutter_stripe (vía el submódulo `stripe_android`) usa
    // clases de `stripe-android-issuing-push-provisioning` (push
    // provisioning a Google Wallet) directamente en su código Kotlin,
    // aunque la dependencia esté declarada `compileOnly` — por eso NO se
    // puede excluir sin romper la compilación del plugin (lo intentamos y
    // falló con "Unresolved reference"). El problema real es solo que la
    // tarea automática de "lint vital" (que corre en cada build de release,
    // incluso con lint deshabilitado) intenta resolver esa dependencia para
    // analizarla, y falla porque es un SDK privado de Google no publicado
    // en ningún repositorio público. Como no compila con esa clase en el
    // classpath de lint (no de compilación), simplemente apagamos la tarea
    // de lint vital en todos los subproyectos — no afecta la compilación
    // real de la app ni del plugin.
    tasks.configureEach {
        if (name.contains("lintVital", ignoreCase = true)) {
            enabled = false
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}