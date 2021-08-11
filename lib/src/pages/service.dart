import 'package:flutter/material.dart';
import 'package:gogrocify/src/helpers/constants.dart';
import 'package:gogrocify/src/helpers/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../generated/l10n.dart';

class ServicePage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: () {
        Helper.of(context).onWillPop();
        return Future(() => false);
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[

              Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[

                  Expanded(
                    flex: 1,
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(left: 30),
                      color: Theme.of(context).accentColor,
                      child: Text(AppLocalization.of(context).desired_service,
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.headline1.copyWith(fontWeight: FontWeight.w400),
                      ),
                    ),
                  ),

                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              Padding(
                padding: EdgeInsets.all(20),
                child: Material(
                  elevation: 5,
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[

                        SizedBox(height: 20,),

                        GestureDetector(
                          onTap: () async {
                            await _save(Constants.GROCERY);
                            Navigator.of(context).pushReplacementNamed('/Pages', arguments: 2);
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).accentColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(AppLocalization.of(context).order_food,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.subtitle1.copyWith(color: Colors.white),
                            ),
                          ),
                        ),

                        SizedBox(height: 40,),

                        GestureDetector(
                          onTap: () async {
                            await _save(Constants.RIDE);
                            Navigator.of(context).pushReplacementNamed('/RideHome');
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).accentColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(AppLocalization.of(context).ride,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.subtitle1.copyWith(color: Colors.white),
                            ),
                          ),
                        ),

                        SizedBox(height: 20,),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(int service) async {

    SharedPreferences _prefs = await SharedPreferences.getInstance();
    await _prefs.setInt('service', service);
  }
}