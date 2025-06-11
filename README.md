# Audio Diaries Flutter

Audio Diaries Flutter is a mobile application that allows users to record audio diaries and store them locally and in a cloud database. 
The application is built using Flutter and Dart, and uses Firebase for cloud storage.

## Table of Contents
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Project Structure](#project-structure)
    - [Architecture](#architecture)
      - [Core](#core)
        - [Error](#error)
        - [Network](#network)
        - [Use Cases](#use-cases)
      - [Data Layer](#data-layer)
        - [Data Models](#data-models)
      - [Domain Layer](#domain-layer)
        - [Entities](#entities)
        - [Repositories](#repositories)
      - [Presentation Layer](#presentation-layer)
        - [Cubit/Bloc](#cubitbloc)
        - [Pages](#pages)
        - [Widgets](#widgets)
      - [Services](#services)

# Getting Started

## Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Visual Studio Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio) or [Xcode](https://developer.apple.com/xcode/)
- [Android Emulator](https://developer.android.com/studio/run/emulator) or [iOS Simulator](https://developer.apple.com/documentation/xcode/running_your_app_in_the_simulator_or_on_a_device)
- [Git](https://git-scm.com/downloads)

## Installation
1. Clone the repository
```
git clone
```
2. Install dependencies
```
flutter pub get
```
(only for iOS)
```
pod install
```
3. Install the database
```
dart run build_runner build
```
4. Run the application
```
flutter run
```
5. Setup amplify project
```
famplify pull --appId d1f2k81mx528zu --envName fablapush
```
6. Checkout dev enviroment
```
amplify env checkout fablapush
```
7. Pull amplify project
```
amplify pull
```

## Project Structure
The project is structured as follows:
```
lib
├───core
│   ├───error
│   ├───network
│   ├───usecases
│   ├───utils
├───screens
│   ├───home
│       ├───data
│       ├───domain
│           ├───entities
│           ├───repositories
│       ├───presentation
│           ├───cubit/bloc
│           ├───pages
│           ├───widgets
│   ├───diary
│   ├───settings
├───services
├───theme
    ├───components
```

### Architecture
The application uses the Clean Architecture pattern, with the following layers:

#### Core
This layer contains the most fundamental elements of the application. It includes common utilities, interfaces, and abstractions that are not specific to any particular feature.

##### Error
Handling and categorizing errors or exceptions.

##### Network
Defining networking-related abstractions.

##### Use Cases
Interfaces for use cases that the domain layer can implement.

#### Data Layer
This is the layer responsible for handling data sources, external services, and data models specific to a screen.

##### Data Models
This layer contains the data models for a screen.

#### Domain Layer
This layer contains the core business logic and entities of the application.

##### Entities
Objects that represent business entities and hold essential data and behavior.

##### Repositories
Interfaces that define the contract for interacting with data sources in the data layer.

#### Presentation Layer
This is the user interface layer responsible for rendering the UI and handling user interactions.

##### Cubit/Bloc
The Cubit/Bloc layer is responsible for handling state management and business logic for a screen.

##### Pages
The Pages layer is responsible for rendering the UI for a screen.

##### Widgets
The Widgets layer is responsible for rendering the UI components for a screen.


#### Services
This layer contains the services that the application uses—for example, the notification service.

## Tests
To run local tests on your machine, you can run the following:

### Widget Test
To run UI tests, run the command. The test cases for the UI are found in the test/screens folder in the root folder
```
flutter test test/screens
```
### Unit Test
To run the Unit tests, run the command. The test cases for the Unit tests are found in the Test folder in the root folder
```
flutter test test/
```

### Integration Test
The test cases for Integration Test are found in the integration_test folder in the root folder.

Add the integration_test library to the dev_dependencies; this is a native library by Flutter itself
```
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
``` 
To run the integration tests on Android, follow the steps below
1. Install the app on your emulator or physical device
```
flutter run
```
2. Stop the app after installing on your emulator or physical device by closing it or by pressing this command in the terminal running the Flutter app.
```
crtl + c
```
Then typing `y` to terminate.

3. Create the grant_permission.sh script in your root folder, which has the following code
```
#!/bin/bash

# Exit on any error
set -e

# Replace with your actual package name (check app/build.gradle)
PACKAGE_NAME="actual-package-name"

# Grant required permissions via ADB
adb shell pm grant "$PACKAGE_NAME" android.permission.RECORD_AUDIO
adb shell pm grant "$PACKAGE_NAME" android.permission.CAMERA
adb shell pm grant "$PACKAGE_NAME" android.permission.POST_NOTIFICATIONS
adb shell pm grant "$PACKAGE_NAME" android.permission.ACCESS_FINE_LOCATION

echo "Permissions granted for $PACKAGE_NAME"

```
4. Make grant_permission executable before running it by running this command
```
chmod +x grant_permission.sh
```
5. Run the bash script grant_permission.sh in the terminal to pre-grant permission to the app
```
./grant_permission.sh
```
6. Run the integration test command
```
flutter test integration_test/app_test.dart
```
