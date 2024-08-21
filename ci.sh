#!/bin/bash
set -o errexit
env=$1

update_version() {
  version=$1
  echo "Updating version to $version"
  sed -i '' -e "s/^version: .*/version: $version/" pubspec.yaml
}

current_version=$(grep '^version: ' pubspec.yaml | sed 's/version: //')

if [ "$env" = "release" ]; then
  echo "Start deploy release"

  # 构建并发布到 pub.dev
  flutter pub publish --server=https://pub.dartlang.org

  IFS='.' read -r -a version_parts <<< "$current_version"
  patch_version=$((version_parts[2] + 1))
  next_version="${version_parts[0]}.${version_parts[1]}.$patch_version"

  update_version "$next_version"

  git add pubspec.yaml
  git commit -m "$current_version is Released"
  
elif [ "$env" = "snapshot" ]; then
  echo "Start deploy snapshot"

  # 构建并进行 dry-run 发布测试
  flutter pub publish --dry-run

else
  echo "Action not defined."
fi
