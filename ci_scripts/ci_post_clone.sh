#!/bin/sh
# Xcode Cloud runs this right after cloning. This repo intentionally gitignores
# the generated Xcode project and the secrets file, so recreate both here.
set -e

# 1) Generate StickerMatch.xcodeproj from project.yml (XcodeGen is the source of truth).
brew install xcodegen
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate

# 2) Recreate Config/Secrets.xcconfig from Xcode Cloud environment variables.
#    In the Xcode Cloud workflow, add these as *secret* environment variables:
#      SUPABASE_HOST      host only, no scheme (e.g. hyfrnjtbcnlrwkwwjpbx.supabase.co)
#      SUPABASE_ANON_KEY  the anon public key
cat > StickerMatch/Config/Secrets.xcconfig <<EOF
SUPABASE_HOST = ${SUPABASE_HOST}
SUPABASE_ANON_KEY = ${SUPABASE_ANON_KEY}
EOF

echo "ci_post_clone: generated project + wrote Secrets.xcconfig"
