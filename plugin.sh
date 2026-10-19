#!/bin/sh
here="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
sys="$(uname -s)"
case "$sys" in
MINGW* | MSYS* | CYGWIN*) rel="x86_64-pc-windows-msvc/gray-webhooks.exe" ;;
Darwin*)
    case "$(uname -m)" in
    arm64) rel="aarch64-apple-darwin/gray-webhooks" ;;
    *) rel="x86_64-apple-darwin/gray-webhooks" ;;
    esac ;;
*)
    case "$(uname -m)" in
    aarch64 | arm64) rel="aarch64-unknown-linux-musl/gray-webhooks" ;;
    *) rel="x86_64-unknown-linux-musl/gray-webhooks" ;;
    esac ;;
esac
if [ -x "$here/$rel" ]; then exec "$here/$rel" "$@"; fi
for cand in "$here/target/release/gray-webhooks.exe" "$here/target/release/gray-webhooks" "$here/target/debug/gray-webhooks.exe" "$here/target/debug/gray-webhooks"; do
    if [ -x "$cand" ]; then exec "$cand" "$@"; fi
done
echo "gray-webhooks binary not found in $here" >&2
exit 1
