import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationHelper {
  // Navigate to a specific route
  static void goTo(BuildContext context, String route) {
    context.go(route);
  }
  
  // Navigate and replace current route
  static void goToReplace(BuildContext context, String route) {
    context.go(route);
  }
  
  // Navigate to a route and push (can go back)
  static void pushTo(BuildContext context, String route) {
    context.push(route);
  }
  
  // Go back
  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    }
  }
  
  // Go back with result
  static void goBackWithResult(BuildContext context, dynamic result) {
    if (context.canPop()) {
      context.pop(result);
    }
  }
  
  // Clear all routes and go to new route
  static void goToAndClearStack(BuildContext context, String route) {
    context.go(route);
  }
  
  // Check if can go back
  static bool canGoBack(BuildContext context) {
    return context.canPop();
  }
}
