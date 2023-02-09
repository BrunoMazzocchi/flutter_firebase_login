import 'package:formz/formz.dart';

enum EmailValidatorError {
  invalid
}
class Email extends FormzInput<String, EmailValidatorError> {
  const Email.pure() : super.pure('');

  const Email.dirty([super.value = '']) : super.dirty();

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );

  @override
  EmailValidatorError? validator(String? value) {
    return _emailRegExp.hasMatch(value ?? '')
        ? null
        : EmailValidatorError.invalid;
  }
}