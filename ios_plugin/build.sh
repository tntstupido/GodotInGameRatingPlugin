#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${ROOT_DIR}/src"
OUTPUT_DIR="${ROOT_DIR}/../addons/in_game_review/ios"

: "${GODOT_HEADERS_DIR:?Set GODOT_HEADERS_DIR to the Godot source root (e.g. /path/to/godot-4.5.1-stable)}"

IOS_SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
SIM_SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"
BUILD_DIR="${ROOT_DIR}/build"
XCFRAMEWORK_NAME="InGameReviewPlugin"

COMMON_INCLUDES=(
    -I"${GODOT_HEADERS_DIR}"
    -I"${GODOT_HEADERS_DIR}/platform/ios"
)

COMMON_FLAGS=(
    -std=c++17
    -fobjc-arc
    -O2
    -Wall
    -Wextra
    -Wno-unused-parameter
)

SRC_FILES=(
    "${SRC_DIR}/ingamereview_plugin.mm"
    "${SRC_DIR}/ingamereview_plugin_bootstrap.mm"
)

build_slice() {
    local sdk_path="$1"
    local arch="$2"
    local variant="$3"
    local obj_dir="${BUILD_DIR}/${variant}/${arch}"
    local lib_path="${obj_dir}/lib${XCFRAMEWORK_NAME}.a"

    mkdir -p "${obj_dir}"

    for src in "${SRC_FILES[@]}"; do
        local obj_file="${obj_dir}/$(basename "${src}" .mm).o"
        echo "  Compiling $(basename "${src}") (${variant}/${arch})..."
        clang++ "${COMMON_FLAGS[@]}" \
            "${COMMON_INCLUDES[@]}" \
            -isysroot "${sdk_path}" \
            -arch "${arch}" \
            -miphoneos-version-min=15.0 \
            -c "${src}" \
            -o "${obj_file}"
    done

    echo "  Creating static library ${lib_path}..."
    mkdir -p "$(dirname "${lib_path}")"
    ar rcs "${lib_path}" "${obj_dir}"/*.o
}

create_xcframework_plist() {
    local xcfw_dir="$1"
    cat > "${xcfw_dir}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>AvailableLibraries</key>
	<array>
		<dict>
			<key>LibraryIdentifier</key>
			<string>ios-arm64</string>
			<key>LibraryPath</key>
			<string>lib${XCFRAMEWORK_NAME}.a</string>
			<key>SupportedArchitectures</key>
			<array>
				<string>arm64</string>
			</array>
			<key>SupportedPlatform</key>
			<string>ios</string>
		</dict>
		<dict>
			<key>LibraryIdentifier</key>
			<string>ios-arm64-simulator</string>
			<key>LibraryPath</key>
			<string>lib${XCFRAMEWORK_NAME}.a</string>
			<key>SupportedArchitectures</key>
			<array>
				<string>arm64</string>
			</array>
			<key>SupportedPlatform</key>
			<string>ios</string>
			<key>SupportedPlatformVariant</key>
			<string>simulator</string>
		</dict>
	</array>
	<key>CFBundlePackageType</key>
	<string>XFWK</string>
	<key>XCFrameworkFormatVersion</key>
	<string>1.0</string>
</dict>
</plist>
EOF
}

echo "=== Building InGameReviewPlugin ==="
echo "Godot headers: ${GODOT_HEADERS_DIR}"

rm -rf "${BUILD_DIR}"

echo "Building device slice..."
build_slice "${IOS_SDK}" "arm64" "release"

echo "Building simulator slice..."
build_slice "${SIM_SDK}" "arm64" "simulator"

echo "Creating xcframework..."
XCFW_DIR="${OUTPUT_DIR}/${XCFRAMEWORK_NAME}.xcframework"
rm -rf "${XCFW_DIR}"
mkdir -p "${XCFW_DIR}/ios-arm64"
mkdir -p "${XCFW_DIR}/ios-arm64-simulator"

cp "${BUILD_DIR}/release/arm64/lib${XCFRAMEWORK_NAME}.a" "${XCFW_DIR}/ios-arm64/"
cp "${BUILD_DIR}/simulator/arm64/lib${XCFRAMEWORK_NAME}.a" "${XCFW_DIR}/ios-arm64-simulator/"

create_xcframework_plist "${XCFW_DIR}"

echo "=== Done ==="
echo "Output: ${XCFW_DIR}"
ls -R "${XCFW_DIR}"
