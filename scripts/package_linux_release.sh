#!/usr/bin/env bash
# Package the exported Linux binary into a distributable tarball.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${VERSION:-0.1.0}"
NAME="open-vt-${VERSION}-linux-x86_64"
SRC_BIN="${ROOT}/bin/linux"
STAGE="${ROOT}/dist/${NAME}"
OUT_TAR="${ROOT}/dist/${NAME}.tar.gz"

if [[ ! -x "${SRC_BIN}/openvt.x86_64" ]]; then
	echo "error: missing exported binary at ${SRC_BIN}/openvt.x86_64" >&2
	echo "run: godot4-ayagami --headless --path \"${ROOT}\" --export-release linux bin/linux/openvt.x86_64" >&2
	exit 1
fi

rm -rf "${STAGE}"
mkdir -p "${STAGE}/licenses"

cp -a "${SRC_BIN}/openvt.x86_64" "${STAGE}/"
# Side PCK only present when embed_pck=false
if [[ -f "${SRC_BIN}/openvt.pck" ]]; then
	cp -a "${SRC_BIN}/openvt.pck" "${STAGE}/"
fi

# GDExtension shared libs (export usually copies them; fall back to addons)
shopt -s nullglob
for so in "${SRC_BIN}"/*.so "${SRC_BIN}"/lib/*.so; do
	cp -a "$so" "${STAGE}/"
done
shopt -u nullglob

copy_release_so() {
	local src="$1"
	local dest_name="$2"
	if [[ ! -f "${STAGE}/${dest_name}" && -f "${src}" ]]; then
		cp -a "${src}" "${STAGE}/${dest_name}"
	fi
}
copy_release_so "${ROOT}/addons/ayagami/lib/libayagami_gd.release.so" "libayagami_gd.release.so"
copy_release_so "${ROOT}/addons/virtualcamera/lib/libgd_virtualcamera.release.so" "libgd_virtualcamera.release.so"
copy_release_so "${ROOT}/addons/keylogger/lib/libgd_keylogger.release.so" "libgd_keylogger.release.so"

chmod +x "${STAGE}/openvt.x86_64"

if [[ -d "${ROOT}/license" ]]; then
	cp -a "${ROOT}/license/"*.md "${STAGE}/licenses/" 2>/dev/null || true
fi
[[ -f "${ROOT}/LICENSE" ]] && cp -a "${ROOT}/LICENSE" "${STAGE}/licenses/" || true

cat > "${STAGE}/README.txt" <<EOF
OpenVT ${VERSION} — Linux x86_64

Run:
  ./openvt.x86_64

Requirements:
  - x86_64 Linux with Vulkan (or compatible) GPU drivers
  - OpenSeeFace is NOT bundled. Install/run OpenSeeFace separately and point
    OpenVT at its UDP port in Camera settings (feature tag: openseeface).

Notes:
  - Window transparency is enabled for OBS alpha capture.
  - Place Live2D / VRM models via the in-app model browser (user data dir).
  - Known issue: some idle/motion clips may still turn clipped mesh regions white.
    Rest pose and OpenSeeFace tracking are the supported smoke path for 0.1.0.

Licenses: see licenses/
EOF

# Ensure .gdextension-relative names work if export used res://addons/.../lib paths
# Godot often places libs beside the executable with the basename from the .gdextension entry.
mkdir -p "${STAGE}/addons/ayagami/lib" "${STAGE}/addons/virtualcamera/lib" "${STAGE}/addons/keylogger/lib"
[[ -f "${STAGE}/libayagami_gd.release.so" ]] && cp -a "${STAGE}/libayagami_gd.release.so" "${STAGE}/addons/ayagami/lib/"
[[ -f "${STAGE}/libgd_virtualcamera.release.so" ]] && cp -a "${STAGE}/libgd_virtualcamera.release.so" "${STAGE}/addons/virtualcamera/lib/"
[[ -f "${STAGE}/libgd_keylogger.release.so" ]] && cp -a "${STAGE}/libgd_keylogger.release.so" "${STAGE}/addons/keylogger/lib/"

# Also copy any nested export layout Godot produced under bin/linux
if [[ -d "${SRC_BIN}/addons" ]]; then
	cp -a "${SRC_BIN}/addons/." "${STAGE}/addons/"
fi

tar -C "${ROOT}/dist" -czf "${OUT_TAR}" "${NAME}"
(
	cd "${ROOT}/dist"
	sha256sum "${NAME}.tar.gz" > "${NAME}.tar.gz.sha256"
)

echo "Wrote ${OUT_TAR}"
echo "SHA256: $(cut -d' ' -f1 "${OUT_TAR}.sha256")"
ls -lh "${OUT_TAR}" "${STAGE}"
