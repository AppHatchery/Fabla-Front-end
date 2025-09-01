import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart'; // Assuming this is the correct path

void main() {
  group('PreferenceService Tests', () {
    late PreferenceService preferenceService;
    // Mock data for SharedPreferences
    Map<String, Object> mockValues = {};

    setUp(() {
      // Initialize SharedPreferences with mock values before each test
      SharedPreferences.setMockInitialValues(mockValues);
      preferenceService = PreferenceService();
      // It's important that _initializePreferences is called,
      // which happens internally in each method of PreferenceService.
      // For a standalone _initializePreferences call in setUp,
      // we might need to make it public or ensure it's called before tests if that were the design.
      // However, the current PreferenceService design initializes it on each call.
    });

    tearDown(() {
      // Clear mock values after each test to ensure test isolation
      mockValues.clear();
    });

    // Test cases will be added here

    test('setStringPreference and getStringPreference should work correctly',
        () async {
      const testKey = 'testStringKey';
      const testValue = 'testStringValue';

      // Set a string value
      await preferenceService.setStringPreference(
          key: testKey, value: testValue);

      // Get the string value
      final retrievedValue =
          await preferenceService.getStringPreference(key: testKey);
      expect(retrievedValue, testValue);

      // Test getting a non-existent key
      final nonExistentValue =
          await preferenceService.getStringPreference(key: 'nonExistentKey');
      expect(nonExistentValue, null);
    });

    test('setBoolPreference and getBoolPreference should work correctly',
        () async {
      const testKey = 'testBoolKey';
      const testValue = true;

      // Set a bool value
      await preferenceService.setBoolPreference(key: testKey, value: testValue);

      // Get the bool value
      final retrievedValue =
          await preferenceService.getBoolPreference(key: testKey);
      expect(retrievedValue, testValue);

      // Test getting a non-existent key
      final nonExistentValue =
          await preferenceService.getBoolPreference(key: 'nonExistentKey');
      expect(nonExistentValue, null);
    });

    test('setIntPreference and getIntPreference should work correctly',
        () async {
      const testKey = 'testIntKey';
      const testValue = 123;

      // Set an int value
      await preferenceService.setIntPreference(key: testKey, value: testValue);

      // Get the int value
      final retrievedValue =
          await preferenceService.getIntPreference(key: testKey);
      expect(retrievedValue, testValue);

      // Test getting a non-existent key
      final nonExistentValue =
          await preferenceService.getIntPreference(key: 'nonExistentKey');
      expect(nonExistentValue, null);
    });

    test('setDoublePreference and getDoublePreference should work correctly',
        () async {
      const testKey = 'testDoubleKey';
      const testValue = 123.45;

      // Set a double value
      await preferenceService.setDoublePreference(
          key: testKey, value: testValue);

      // Get the double value
      final retrievedValue =
          await preferenceService.getDoublePreference(key: testKey);
      expect(retrievedValue, testValue);

      // Test getting a non-existent key
      final nonExistentValue =
          await preferenceService.getDoublePreference(key: 'nonExistentKey');
      expect(nonExistentValue, null);
    });

    test(
        'setStringListPreference and getStringListPreference should work correctly',
        () async {
      const testKey = 'testStringListKey';
      final testValue = ['a', 'b', 'c'];

      // Set a string list value
      await preferenceService.setStringListPreference(
          key: testKey, value: testValue);

      // Get the string list value
      final retrievedValue =
          await preferenceService.getStringListPreference(key: testKey);
      expect(retrievedValue, testValue);

      // Test getting a non-existent key
      final nonExistentValue = await preferenceService.getStringListPreference(
          key: 'nonExistentKey');
      expect(nonExistentValue, null);
    });

    test('removePreference should remove a preference', () async {
      const testKey = 'testRemoveKey';
      const testValue = 'testRemoveValue';

      // Set a value
      await preferenceService.setStringPreference(
          key: testKey, value: testValue);
      var retrievedValue =
          await preferenceService.getStringPreference(key: testKey);
      expect(retrievedValue, testValue);

      // Remove the value
      await preferenceService.removePreference(key: testKey);
      retrievedValue =
          await preferenceService.getStringPreference(key: testKey);
      expect(retrievedValue, null);
    });

    test('clearPreferences should clear all preferences', () async {
      const key1 = 'key1';
      const value1 = 'value1';
      const key2 = 'key2';
      const value2 = 100;

      // Set multiple values
      await preferenceService.setStringPreference(key: key1, value: value1);
      await preferenceService.setIntPreference(key: key2, value: value2);

      // Verify they are set
      expect(await preferenceService.getStringPreference(key: key1), value1);
      expect(await preferenceService.getIntPreference(key: key2), value2);

      // Clear all preferences
      await preferenceService.clearPreferences();

      // Verify they are cleared
      expect(await preferenceService.getStringPreference(key: key1), null);
      expect(await preferenceService.getIntPreference(key: key2), null);
    });

    test('should handle empty string list correctly', () async {
      const testKey = 'testEmptyListKey';
      final testValue = <String>[];

      // Set an empty string list
      await preferenceService.setStringListPreference(
          key: testKey, value: testValue);

      // Get the empty string list
      final retrievedValue =
          await preferenceService.getStringListPreference(key: testKey);
      expect(retrievedValue, testValue);
      expect(retrievedValue?.isEmpty, true);
    });

    test('should handle empty or invalid keys', () async {
      const emptyKey = '';
      const testValue = 'testValue';

      // Test with empty key
      await preferenceService.setStringPreference(
          key: emptyKey, value: testValue);
      final retrievedValue =
          await preferenceService.getStringPreference(key: emptyKey);
      expect(retrievedValue, testValue);

      // Test with whitespace key
      const whitespaceKey = '   ';
      await preferenceService.setStringPreference(
          key: whitespaceKey, value: testValue);
      final retrievedValue2 =
          await preferenceService.getStringPreference(key: whitespaceKey);
      expect(retrievedValue2, testValue);
    });

    test('should maintain state across multiple operations', () async {
      const key1 = 'key1';
      const key2 = 'key2';
      const value1 = 'value1';
      const value2 = 42;

      // Set first value
      await preferenceService.setStringPreference(key: key1, value: value1);
      expect(await preferenceService.getStringPreference(key: key1), value1);

      // Set second value
      await preferenceService.setIntPreference(key: key2, value: value2);
      expect(await preferenceService.getIntPreference(key: key2), value2);

      // Update first value
      const newValue1 = 'newValue1';
      await preferenceService.setStringPreference(key: key1, value: newValue1);
      expect(await preferenceService.getStringPreference(key: key1), newValue1);

      // Verify second value is still intact
      expect(await preferenceService.getIntPreference(key: key2), value2);

      // Remove first value
      await preferenceService.removePreference(key: key1);
      expect(await preferenceService.getStringPreference(key: key1), null);

      // Verify second value is still intact
      expect(await preferenceService.getIntPreference(key: key2), value2);
    });
  });
}
