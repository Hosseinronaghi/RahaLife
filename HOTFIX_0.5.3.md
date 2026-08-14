# Raha Life v0.5.3+12 hotfix

## Failure addressed
`file_picker 12` no longer exposes `PlatformFile.size`. The v0.5.2 project attachment flow still used that removed getter, causing `flutter analyze --fatal-infos` and Windows compilation to fail.

## Fix
The project attachment flow now obtains file size with:

```dart
final fileSize = await file.length();
```

and stores that `int` in `ProjectAttachment.size`.

No feature or schema changes are included in this hotfix.
