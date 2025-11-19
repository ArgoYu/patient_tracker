// lib/shared/utils/toast.dart
import 'package:flutter/material.dart';

/// Shows a simple [SnackBar] with the provided [message].
void showToast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
