import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../generated/l10n.dart';
import '../elements/BlockButtonWidget.dart';
import '../controllers/settings_controller.dart';
import '../helpers/helper.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import '../helpers/app_config.dart' as config;

class PhoneNumberChange extends StatefulWidget {

  final SettingsController con;

  const PhoneNumberChange({Key key, this.con}) : super(key: key);

  @override
  _PhoneNumberChangeState createState() => _PhoneNumberChangeState();
}

class _PhoneNumberChangeState extends StateMVC<PhoneNumberChange> {

  TextEditingController _codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    final _ac = config.App(context);

    return WillPopScope(
      onWillPop: () {
        return Future(() => true);
      },
      child: Scaffold(
        //key: _con.scaffoldKey,
        body: Builder(
          builder: (BuildContext context) {

            return Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: _ac.appWidth(100),
                    child: Column(
                      children: <Widget>[
                        Text(
                          'Verify Your Account',
                          style: Theme.of(context).textTheme.headline5,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'We are sending OTP to validate your mobile number. Hang on!',
                          style: Theme.of(context).textTheme.bodyText2,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 50),
                  Form(
                    key: widget.con.loginFormKey,
                    child: TextFormField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      validator: (input) => input.isEmpty ? AppLocalization.of(context).enterSentCode : input.length < 6 ? AppLocalization.of(context).codeShort : null,
                      style: Theme.of(context).textTheme.headline5,
                      textAlign: TextAlign.center,
                      decoration: new InputDecoration(
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).focusColor.withOpacity(0.2)),
                        ),
                        focusedBorder: new UnderlineInputBorder(
                          borderSide: new BorderSide(
                            color: Theme.of(context).focusColor.withOpacity(0.5),
                          ),
                        ),
                        hintText: '000-000',
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'SMS has been sent to +88-' + widget.con.phone,
                    style: Theme.of(context).textTheme.caption,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 80),
                  new BlockButtonWidget(
                    onPressed: () {
                      widget.con.verifyPhone(_codeController.text, context);
                    },
                    color: Theme.of(context).accentColor,
                    text: Text(AppLocalization.of(context).verify.toUpperCase(),
                        style: Theme.of(context).textTheme.headline6.merge(TextStyle(color: Theme.of(context).primaryColor))),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}