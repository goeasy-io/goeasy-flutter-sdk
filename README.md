# goeasy

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/developing-packages/),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter development, view the
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

目录结构：
goeasy_sdk/
├── android/
│   └── src/main/
│       └── java/your/package/
│           └── GoEasySdkPlugin.java
├── ios/
│   └── Classes/
│       └── GoEasySdkPlugin.m
├── lib/
│   └── goeasy_sdk.dart
├── test/
│   └── goeasy_sdk_test.dart
├── example/
│   ├── lib/
│   │   └── main.dart
│   ├── android/
│   ├── ios/
│   ├── pubspec.yaml
├── pubspec.yaml
├── CHANGELOG.md
└── README.md

在 android/ 和 ios/ 目录中实现平台特定的功能代码
在 lib/goeasy_sdk.dart 文件中定义 Dart 接口，并通过 MethodChannel 调用平台代码。
在 test/ 目录中编写单元测试
在 example/ 目录中编写示例应用


添加安卓原生依赖android/build.gradle
1.保存并关闭build.gradle文件。
2.在项目的根目录下运行flutter packages get命令。

添加iOS依赖 ios/xx.podspec文件中
1.在 *.podspec 文件中添加依赖
2.在 example/ios下pod install