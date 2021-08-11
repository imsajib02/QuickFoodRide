import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gogrocify/src/controllers/profile_controller.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user.dart';

class ProfileAvatarWidget extends StatelessWidget {
  final User user;
  final ProfileController con;

  ProfileAvatarWidget({
    Key key,
    this.user,
    this.con,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Theme.of(context).accentColor,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[

                CircleAvatar(
                  radius: 65,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(300)),
                    child: CachedNetworkImage(
                      fit: BoxFit.cover,
                      imageUrl: user.image?.url,
                      placeholder: (context, url) => Image.asset(
                        'assets/img/loading.gif',
                        fit: BoxFit.cover,
                        height: 135,
                        width: 135,
                      ),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
                ),

                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.transparent,
                  child: GestureDetector(
                    onTap: () {
                    },
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Icon(Icons.edit, color: Theme.of(context).primaryColorDark,),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headline5.merge(TextStyle(color: Theme.of(context).primaryColor)),
          ),
//          Text(
//            user.address,
//            style: Theme.of(context).textTheme.caption.merge(TextStyle(color: Theme.of(context).primaryColor)),
//          ),
        ],
      ),
    );
  }
}
