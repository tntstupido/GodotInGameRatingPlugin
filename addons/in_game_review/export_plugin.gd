@tool
extends EditorPlugin

var export_plugin: InGameReviewExportPlugin

func _enter_tree() -> void:
    export_plugin = InGameReviewExportPlugin.new()
    add_export_plugin(export_plugin)

func _exit_tree() -> void:
    remove_export_plugin(export_plugin)
    export_plugin = null


class InGameReviewExportPlugin extends EditorExportPlugin:
    func _get_name() -> String:
        return "InGameReview"

    func _supports_platform(platform: EditorExportPlatform) -> bool:
        return _is_ios_platform(platform) or _is_android_platform(platform)

    func _is_ios_platform(platform: EditorExportPlatform) -> bool:
        return platform.get_class().contains("iOS")

    func _is_android_platform(platform: EditorExportPlatform) -> bool:
        return "Android" in platform.get_class()

    func _get_export_options(platform: EditorExportPlatform) -> Array[Dictionary]:
        if _is_ios_platform(platform):
            return [
                {
                    "option": {"name": "in_game_review/apple_app_id", "type": TYPE_STRING},
                    "default_value": ""
                }
            ]
        return []

    func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
        if _is_android_platform(platform):
            return PackedStringArray(["in_game_review/android/in_game_review-release.aar"])
        return PackedStringArray()

    func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
        if _is_android_platform(platform):
            return PackedStringArray(["com.google.android.play:review-ktx:2.0.2"])
        return PackedStringArray()

    func _get_android_dependencies_maven_repos(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
        if _is_android_platform(platform):
            return PackedStringArray(["https://maven.google.com"])
        return PackedStringArray()
