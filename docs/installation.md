* Installation Guide

** System Requirements

To build and run MOD, you will need:

- Flutter SDK
- Dart SDK
- Visual Studio Code or another Flutter-compatible IDE
- A supported device or browser for running the Flutter application
- Git, if cloning the project from a repository

The project uses the dependencies listed in `pubspec.yaml`, including `shared_preferences`.

** Getting the Project

1. Clone or download the MOD project.
2. Open the project folder in Visual Studio Code.
3. Make sure the opened folder is the Flutter project root with the folder containing `pubspec.yaml`.

** Install Dependencies

Open a terminal in the project root and run:

```bash
flutter pub get
```

** Run the Application

To run the application in Chrome:

```bash
flutter run -d chrome
```

You can also run the project on another supported Flutter device by selecting that device and using:

```bash
flutter run
```

** Building the Application

For a web build, run:

```bash
flutter build web
```

The generated web build will be placed in the project's `build/web` directory.

** Troubleshooting

If dependencies are missing or the project does not build correctly, run:

```bash
flutter clean
flutter pub get
```

Then try running the application again.
