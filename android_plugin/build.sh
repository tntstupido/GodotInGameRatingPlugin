#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${ROOT_DIR}/../addons/in_game_review/android"

echo "=== Building InGameReview Android Plugin ==="

cd "${ROOT_DIR}"

if [ ! -f "gradlew" ]; then
    echo "Generating Gradle wrapper..."
    ./gradlew wrapper --gradle-version 8.9 || gradle wrapper --gradle-version 8.9
fi

echo "Running assembleRelease..."
./gradlew assembleRelease

AAR_SRC=$(find "${ROOT_DIR}/build/outputs/aar" -name "*.aar" | head -1)
if [ -z "${AAR_SRC}" ]; then
    echo "ERROR: No AAR found in build/outputs/aar/"
    exit 1
fi
mkdir -p "${OUTPUT_DIR}"
cp "${AAR_SRC}" "${OUTPUT_DIR}/in_game_review-release.aar"

echo "=== Done ==="
echo "Output: ${OUTPUT_DIR}/in_game_review-release.aar"
