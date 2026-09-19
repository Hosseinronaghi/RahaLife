import 'package:flutter/material.dart';

/// Completes after route animation and widget disposal, so caller-owned text
/// controllers remain valid for the entire popup lifetime.
Future<T?> showRetainedBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool? showDragHandle,
  bool useSafeArea = false,
}) async {
  final navigator = Navigator.of(context);
  final route = ModalBottomSheetRoute<T>(
    builder: builder,
    isScrollControlled: isScrollControlled,
    showDragHandle: showDragHandle,
    useSafeArea: useSafeArea,
    capturedThemes: InheritedTheme.capture(
      from: context,
      to: navigator.context,
    ),
    modalBarrierColor:
        Theme.of(context).bottomSheetTheme.modalBarrierColor ?? Colors.black54,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  );
  final result = await navigator.push(route);
  await route.completed;
  return result;
}

Future<T?> showRetainedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<T>(
    context: context,
    builder: builder,
    themes: InheritedTheme.capture(from: context, to: navigator.context),
  );
  final result = await navigator.push(route);
  await route.completed;
  return result;
}
