part of 'app_bloc.dart';

abstract class AppEvent {
  const AppEvent();
}

// Notifies that the current user requested to be logged out
class AppLogoutRequested extends AppEvent {
  const AppLogoutRequested();
}

// Notifies that the user has changed.
class _AppUserChanged extends  AppEvent {
  const _AppUserChanged(this.user);
  final User user;
}