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
        return _is_ios_platform(platform)

    func _is_ios_platform(platform: EditorExportPlatform) -> bool:
        return platform.get_class().contains("iOS")

    func _get_export_options(platform: EditorExportPlatform) -> Array[Dictionary]:
        return [
            {
                "option": {"name": "in_game_review/apple_app_id", "type": TYPE_STRING},
                "default_value": ""
            }
        ]
