import 'package:flutter/material.dart';
import 'package:gogrocify/src/models/password.dart';

import '../../generated/l10n.dart';
import '../models/user.dart';

class PasswordChangeDialog extends StatefulWidget {
  final void Function(Password) onSubmit;

  PasswordChangeDialog({Key key, this.onSubmit}) : super(key: key);

  @override
  _PasswordChangeDialogState createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<PasswordChangeDialog> {
  GlobalKey<FormState> _profileSettingsFormKey = new GlobalKey<FormState>();

  TextEditingController _oldPassword = TextEditingController();
  TextEditingController _newPassword = TextEditingController();
  TextEditingController _confirmPassword = TextEditingController();


  @override
  void initState() {
    _oldPassword.text = "";
    _newPassword.text = "";
    _confirmPassword.text = "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    _oldPassword.text = "";
    _newPassword.text = "";
    _confirmPassword.text = "";

    return FlatButton(
      onPressed: () {
        showDialog(
            context: context,
            builder: (context) {
              return SimpleDialog(
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                titlePadding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                title: Row(
                  children: <Widget>[
                    Icon(Icons.lock),
                    SizedBox(width: 10),
                    Text(
                      AppLocalization.of(context).password,
                      style: Theme.of(context).textTheme.bodyText1,
                    )
                  ],
                ),
                children: <Widget>[
                  Form(
                    key: _profileSettingsFormKey,
                    child: Column(
                      children: <Widget>[
                        new TextFormField(
                          controller: _oldPassword,
                          style: TextStyle(color: Theme.of(context).hintColor),
                          keyboardType: TextInputType.text,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: '••••••••••••',
                            labelText: AppLocalization.of(context).old_password,
                            hintStyle: Theme.of(context).textTheme.bodyText2.merge(
                              TextStyle(color: Theme.of(context).focusColor),
                            ),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).hintColor.withOpacity(0.2))),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).hintColor)),
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            labelStyle: Theme.of(context).textTheme.bodyText2.merge(
                              TextStyle(color: Theme.of(context).hintColor),
                            ),
                            contentPadding: EdgeInsets.all(5),
                          ),
                          validator: (input) => input.length < 6 ? AppLocalization.of(context).must_be_6_letters : null,
                        ),
                        new TextFormField(
                          style: TextStyle(color: Theme.of(context).hintColor),
                          keyboardType: TextInputType.text,
                          obscureText: true,
                          controller: _newPassword,
                          decoration: InputDecoration(
                            hintText: '••••••••••••',
                            labelText: AppLocalization.of(context).new_password,
                            hintStyle: Theme.of(context).textTheme.bodyText2.merge(
                              TextStyle(color: Theme.of(context).focusColor),
                            ),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).hintColor.withOpacity(0.2))),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).hintColor)),
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            labelStyle: Theme.of(context).textTheme.bodyText2.merge(
                              TextStyle(color: Theme.of(context).hintColor),
                            ),
                          ),
                          validator: (input) => input.length < 6 ? AppLocalization.of(context).must_be_6_letters : null,
                        ),
                        new TextFormField(
                          controller: _confirmPassword,
                          style: TextStyle(color: Theme.of(context).hintColor),
                          keyboardType: TextInputType.text,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: '••••••••••••',
                            labelText: AppLocalization.of(context).confirm_password,
                            hintStyle: Theme.of(context).textTheme.bodyText2.merge(
                              TextStyle(color: Theme.of(context).focusColor),
                            ),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).hintColor.withOpacity(0.2))),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).hintColor)),
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            labelStyle: Theme.of(context).textTheme.bodyText2.merge(
                              TextStyle(color: Theme.of(context).hintColor),
                            ),
                          ),
                          validator: (input) => input.length < 6 ? AppLocalization.of(context).must_be_6_letters :
                          (input != _newPassword.text ? AppLocalization.of(context).confirm_password_do_not_match : null),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      MaterialButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(AppLocalization.of(context).cancel),
                      ),
                      MaterialButton(
                        onPressed: _submit,
                        child: Text(
                          AppLocalization.of(context).change,
                          style: TextStyle(color: Theme.of(context).accentColor),
                        ),
                      ),
                    ],
                    mainAxisAlignment: MainAxisAlignment.end,
                  ),
                  SizedBox(height: 10),
                ],
              );
            });
      },
      child: Text(
        AppLocalization.of(context).change,
        style: Theme.of(context).textTheme.bodyText2,
      ),
    );
  }

  void _submit() {
    if (_profileSettingsFormKey.currentState.validate()) {
      _profileSettingsFormKey.currentState.save();

      widget.onSubmit(Password(oldPassword: _oldPassword.text, newPassword: _newPassword.text, confirmPassword: _confirmPassword.text));

      _oldPassword.text = "";
      _newPassword.text = "";
      _confirmPassword.text = "";

      Navigator.pop(context);
    }
  }
}
