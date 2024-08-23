#!/bin/bash

TYPE=$1

# 当前版本号
CURRENT_VERSION=$(grep 'version:' pubspec.yaml | awk '{print $2}')

BASE_VERSION=$(echo $CURRENT_VERSION | sed -E 's/([0-9]+\.[0-9]+\.[0-9]+).*/\1/')

NEW_VERSION=""

# 如果当前版本号带有 beta 标签
if echo $CURRENT_VERSION | grep -q 'beta'; then
    BETA_VERSION=$(echo $CURRENT_VERSION | sed -E 's/.*-([0-9]+)\.beta/\1/')

    if [ "$TYPE" == "release" ]; then
        NEW_VERSION=$(echo $BASE_VERSION | awk -F. '{print $1"."$2"."$3+1}')
    elif [ "$TYPE" == "snapshot" ]; then
        NEW_VERSION="$BASE_VERSION-$((BETA_VERSION+1)).beta"
    fi
else
    if [ "$TYPE" == "release" ]; then
        NEW_VERSION=$(echo $BASE_VERSION | awk -F. '{print $1"."$2"."$3+1}')
    elif [ "$TYPE" == "snapshot" ]; then
        NEW_VERSION="$BASE_VERSION-1.beta"
    fi
fi

# 更新 pubspec.yaml 中的版本号
sed -i "s/version: .*/version: $NEW_VERSION/" pubspec.yaml

echo "type:$TYPE BASE_VERSION: $BASE_VERSION NEW_VERSION: $NEW_VERSION"


# 更新 changelog
CHANGELOG_FILE="CHANGELOG.md"
CURRENT_DATE=$(date +"%Y-%m-%d")

echo "## $NEW_VERSION - $CURRENT_DATE" > temp_changelog.md
echo "" >> temp_changelog.md
echo "### Added" >> temp_changelog.md
echo "" >> temp_changelog.md
echo "- " >> temp_changelog.md  # 默认内容为空，可以在这里添加实际的更新内容

# 将新内容添加到 changelog 文件的顶部
cat temp_changelog.md $CHANGELOG_FILE > updated_changelog.md
mv updated_changelog.md $CHANGELOG_FILE
rm temp_changelog.md

# 提交更改并打tag
git config user.name "goeasy.io*"
git config user.email "support@goeasy.io"
git add .
git commit -m "ci: bump version to $NEW_VERSION and update changelog"
git push origin HEAD
# git tag -a "v$NEW_VERSION" -m "Release version $NEW_VERSION"
# git push origin "v$NEW_VERSION"

echo "Version updated to $NEW_VERSION and changelog updated."
