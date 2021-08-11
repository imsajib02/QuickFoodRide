import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../generated/l10n.dart';
import '../../helpers/constants.dart';
import '../../repository/settings_repository.dart';
import '../../repository/user_repository.dart';
import '../../models/ride.dart';
import 'package:intl/intl.dart';

class RideDetailsController {

  Uint8List pickUpPointBitmap;
  Uint8List destinationPointBitmap;

  AnimationController completeController;
  AnimationController beforeStartCancelController;
  AnimationController afterStartCancelController;

  Animation<Offset> _completeOffset;
  Animation<Offset> _beforeStartCancelOffset;
  Animation<Offset> _afterStartCancelOffset;

  bool isConstructorCalled = false;


  RideDetailsController(TickerProvider tickerProvider, Ride ride) {

    if(!isConstructorCalled) {

      isConstructorCalled = true;

      completeController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 200));
      _completeOffset = Tween<Offset>(begin: Offset(0.0, -2.0), end: Offset.zero).animate(completeController);

      beforeStartCancelController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 200));
      _beforeStartCancelOffset = Tween<Offset>(begin: Offset(0.0, -2.0), end: Offset.zero).animate(beforeStartCancelController);

      afterStartCancelController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 200));
      _afterStartCancelOffset = Tween<Offset>(begin: Offset(0.0, -2.0), end: Offset.zero).animate(afterStartCancelController);

      if(ride.status == Constants.completed) {

        completeController.forward();
      }
      else if(ride.status == Constants.canceled && (ride.cancellationFee == null || ride.cancellationFee == "")) {

        beforeStartCancelController.forward();
      }
      else if(ride.status == Constants.canceled && (ride.cancellationFee != null || ride.cancellationFee != "")) {

        afterStartCancelController.forward();
      }
    }
  }


  SlideTransition rideCompleted(BuildContext context, Ride ride) {

    return SlideTransition(
      position: _completeOffset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: DraggableScrollableSheet(
          initialChildSize: 0.56,
          minChildSize: 0.345,
          maxChildSize: .56,
          builder: (context, controller) {

            try {
              var time = ride.date2.difference(ride.date1).inMinutes;

              if(time > 60) {

                ride.duration = (time / 60).floor().toString() + AppLocalization.of(context).hour + " "
                    + (((time / 60) - (time / 60).floor()) * 60).toString() + AppLocalization.of(context).minute;
              }
              else if(time == 60) {

                ride.duration = "1" + AppLocalization.of(context).hour;
              }
              else {

                ride.duration = time.toString() + AppLocalization.of(context).minute;
              }
            }
            catch(e) {}

            return Stack(
              children: <Widget>[

                Material(
                  elevation: 10,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                    ),
                    child: NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (overscroll) {
                        overscroll.disallowGlow();
                        return;
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 30, left: 20, right: 20),
                        child: ListView(
                          controller: controller,
                          children: <Widget>[

                            Text(AppLocalization.of(context).ride_complete,
                              style: Theme.of(context).textTheme.headline2,
                            ),

                            SizedBox(height: 20,),

                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                Text(AppLocalization.of(context).distance,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),

                                Text(ride == null || ride.distance == null ? "" : ride.distance + " " + AppLocalization.of(context).km,
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                ),
                              ],
                            ),

                            SizedBox(height: 10,),

                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                Text(AppLocalization.of(context).time,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),

                                Text(ride == null || ride.duration == null ? "" : ride.duration,
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                ),
                              ],
                            ),

                            SizedBox(height: 10,),

                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                Text(AppLocalization.of(context).fare,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),

                                Text(setting.value.defaultCurrency + " " + (ride == null || ride.rideFee == null ? "" : ride.rideFee),
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                ),
                              ],
                            ),

                            Visibility(
                              visible: ride.rating.isNotEmpty,
                              child: Padding(
                                padding: EdgeInsets.only(top: 25, left: 50, right: 50),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: List.generate(5, (index) {

                                    return Icon(
                                      ride.rating != null && ride.rating.isNotEmpty ? (index < int.tryParse(ride.rating) ? Icons.star : Icons.star_border) : Icons.star_border,
                                      size: 28,
                                      color: ride.rating != null && ride.rating.isNotEmpty ? (index < int.tryParse(ride.rating) ? Theme.of(context).accentColor : Colors.grey) : Colors.grey,
                                    );
                                  }),
                                ),
                              ),
                            ),

                            SizedBox(height: 30,),

                            Container(
                              height: 10,
                              width: double.infinity,
                              color: Colors.grey[100],
                            ),

                            SizedBox(height: 30,),

                            IntrinsicHeight(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[

                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: <Widget>[

                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: Colors.black54),
                                          ),
                                        ),

                                        SizedBox(height: 10,),

                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            border: Border.all(color: Colors.black38),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Expanded(
                                      flex: 8,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: <Widget>[

                                          Container(
                                            alignment: Alignment.centerLeft,
                                            padding: EdgeInsets.all(12),
                                            margin: EdgeInsets.only(left: 5, right: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                            ),
                                            child: Text(ride == null || ride.pickupAddress == null ? "" : ride.pickupAddress,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          ),

                                          SizedBox(height: 10,),

                                          Container(
                                            alignment: Alignment.centerLeft,
                                            padding: EdgeInsets.all(12),
                                            margin: EdgeInsets.only(left: 5, right: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                            ),
                                            child: Text(ride == null || ride.dropOffAddress == null ? "" : ride.dropOffAddress,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          ),
                                        ],
                                      )
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 30,),

                            Container(
                              height: 10,
                              width: double.infinity,
                              color: Colors.grey[100],
                            ),

                            SizedBox(height: 20,),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  SlideTransition rideCancelledBeforeStart(BuildContext context, Ride cancelledRide) {

    return SlideTransition(
      position: _beforeStartCancelOffset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: DraggableScrollableSheet(
          initialChildSize: 0.20,
          minChildSize: 0.20,
          maxChildSize: 0.20,
          builder: (context, controller) {

            return Stack(
              children: <Widget>[

                Material(
                  elevation: 10,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                    ),
                    child: NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (overscroll) {
                        overscroll.disallowGlow();
                        return;
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 30, left: 20, right: 20),
                        child: ListView(
                          controller: controller,
                          children: <Widget>[

                            Text(AppLocalization.of(context).ride_cancelled,
                              style: Theme.of(context).textTheme.headline2,
                            ),

                            SizedBox(height: 20,),

                            Text(cancelledRide != null && cancelledRide.status != null && cancelledRide.status == Constants.canceled ?
                            (cancelledRide.cancelledBy == currentUser.value.id ? AppLocalization.of(context).ride_was_cancelled_by_you :
                            AppLocalization.of(context).ride_was_cancelled_by_rider) : "",
                              style: Theme.of(context).textTheme.caption.copyWith(fontSize: 16),
                            ),

                            SizedBox(height: 20,),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  SlideTransition rideCancelledAfterStart(BuildContext context, Ride ride) {

    return SlideTransition(
      position: _afterStartCancelOffset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: DraggableScrollableSheet(
          initialChildSize: .53,
          minChildSize: .365,
          maxChildSize: .53,
          builder: (context, controller) {

            try {
              var time = ride.date2.difference(ride.date1).inMinutes;

              if(time > 60) {

                ride.duration = (time / 60).floor().toString() + AppLocalization.of(context).hour + " "
                    + (((time / 60) - (time / 60).floor()) * 60).toString() + AppLocalization.of(context).minute;
              }
              else if(time == 60) {

                ride.duration = "1" + AppLocalization.of(context).hour;
              }
              else {

                ride.duration = time.toString() + AppLocalization.of(context).minute;
              }
            }
            catch(e) {}

            return Stack(
              children: <Widget>[

                Material(
                  elevation: 10,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                    ),
                    child: NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (overscroll) {
                        overscroll.disallowGlow();
                        return;
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 30, left: 20, right: 20),
                        child: ListView(
                          controller: controller,
                          children: <Widget>[

                            Text(AppLocalization.of(context).ride_cancelled,
                              style: Theme.of(context).textTheme.headline2,
                            ),

                            SizedBox(height: 20,),

                            Text(ride != null && ride.status != null && ride.status == Constants.canceled ? (ride.cancelledBy == currentUser.value.id ?
                            AppLocalization.of(context).ride_was_cancelled_by_you : AppLocalization.of(context).ride_was_cancelled_by_rider) : "",
                              style: Theme.of(context).textTheme.caption.copyWith(fontSize: 16),
                            ),

                            SizedBox(height: 20,),

                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                Text(AppLocalization.of(context).distance,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),

                                Text(ride == null || ride.distance == null ? "" : ride.distance + " " + AppLocalization.of(context).km,
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                ),
                              ],
                            ),

                            SizedBox(height: 10,),

                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                Text(AppLocalization.of(context).time,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),

                                Text(ride == null || ride.duration == null ? "" : ride.duration,
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                ),
                              ],
                            ),

                            Visibility(
                              visible: ride != null && ride.status != null && ride.status == Constants.canceled && ride.cancelledBy == currentUser.value.id,
                              child: SizedBox(height: 10,),
                            ),

                            Visibility(
                              visible: ride != null && ride.status != null && ride.status == Constants.canceled && ride.cancelledBy == currentUser.value.id,
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[

                                  Text(AppLocalization.of(context).fare,
                                    style: Theme.of(context).textTheme.subtitle1,
                                  ),

                                  Text(setting.value.defaultCurrency + " " + (ride == null || ride.rideFee == null ? "" : ride.rideFee),
                                    style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),

                            Visibility(
                              visible: ride != null && ride.status != null && ride.status == Constants.canceled && ride.cancelledBy == currentUser.value.id,
                              child: SizedBox(height: 10,),
                            ),

                            Visibility(
                              visible: ride != null && ride.status != null && ride.status == Constants.canceled && ride.cancelledBy == currentUser.value.id,
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[

                                  Text(AppLocalization.of(context).cancel_fee,
                                    style: Theme.of(context).textTheme.subtitle1,
                                  ),

                                  Text(setting.value.defaultCurrency + " " + (ride == null || ride.cancellationFee == null ? "" : ride.cancellationFee),
                                    style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),

                            Visibility(
                              visible: ride.cancelledBy != currentUser.value.id && ride.rating.isNotEmpty,
                              child: Padding(
                                padding: EdgeInsets.only(top: 25, left: 50, right: 50),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: List.generate(5, (index) {

                                    return Icon(
                                      ride.rating != null && ride.rating.isNotEmpty ? (index < int.tryParse(ride.rating) ? Icons.star : Icons.star_border) : Icons.star_border,
                                      size: 28,
                                      color: ride.rating != null && ride.rating.isNotEmpty ? (index < int.tryParse(ride.rating) ? Theme.of(context).accentColor : Colors.grey) : Colors.grey,
                                    );
                                  }),
                                ),
                              ),
                            ),

                            SizedBox(height: 30,),

                            Container(
                              height: 10,
                              width: double.infinity,
                              color: Colors.grey[100],
                            ),

                            SizedBox(height: 30,),

                            IntrinsicHeight(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[

                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: <Widget>[

                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: Colors.black54),
                                          ),
                                        ),

                                        SizedBox(height: 10,),

                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            border: Border.all(color: Colors.black38),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Expanded(
                                      flex: 8,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: <Widget>[

                                          Container(
                                            alignment: Alignment.centerLeft,
                                            padding: EdgeInsets.all(12),
                                            margin: EdgeInsets.only(left: 5, right: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                            ),
                                            child: Text(ride == null || ride.pickupAddress == null ? "" : ride.pickupAddress,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          ),

                                          SizedBox(height: 10,),

                                          Container(
                                            alignment: Alignment.centerLeft,
                                            padding: EdgeInsets.all(12),
                                            margin: EdgeInsets.only(left: 5, right: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                            ),
                                            child: Text(ride == null || ride.dropOffAddress == null ? "" : ride.dropOffAddress,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          ),
                                        ],
                                      )
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 30,),

                            Container(
                              height: 10,
                              width: double.infinity,
                              color: Colors.grey[100],
                            ),

                            SizedBox(height: 20,),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}