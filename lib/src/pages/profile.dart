import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../helpers/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../elements/profile_imgae_pick.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

import '../../generated/l10n.dart';
import '../controllers/profile_controller.dart';
import '../elements/DrawerWidget.dart';
import '../elements/EmptyOrdersWidget.dart';
import '../elements/OrderItemWidget.dart';
import '../elements/PermissionDeniedWidget.dart';
import '../elements/ShoppingCartButtonWidget.dart';
import '../repository/user_repository.dart';

class ProfileWidget extends StatefulWidget {
  final GlobalKey<ScaffoldState> parentScaffoldKey;

  ProfileWidget({Key key, this.parentScaffoldKey}) : super(key: key);
  @override
  _ProfileWidgetState createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends StateMVC<ProfileWidget> {
  ProfileController _con;

  SharedPreferences _prefs;
  int val;

  _ProfileWidgetState() : super(ProfileController()) {
    _con = controller;
  }

  TextEditingController _nameController = TextEditingController();
  TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    _initSp();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _con.scaffoldKey,
      drawer: DrawerWidget(),
      appBar: AppBar(
        leading: new IconButton(
          icon: new Icon(Icons.sort, color: Theme.of(context).primaryColor),
          onPressed: () => _con.scaffoldKey?.currentState?.openDrawer(),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).accentColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppLocalization.of(context).profile,
          style: Theme.of(context).textTheme.headline6.merge(TextStyle(letterSpacing: 1.3, color: Theme.of(context).primaryColor)),
        ),
        actions: <Widget>[

          Visibility(
            visible: val == Constants.GROCERY,
            child: ShoppingCartButtonWidget(iconColor: Theme.of(context).primaryColor, labelColor: Theme.of(context).hintColor),
          ),
        ],
      ),
      body: currentUser.value.apiToken == null
          ? PermissionDeniedWidget()
          : SingleChildScrollView(
//              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
              child: Column(
                children: <Widget>[

                  Container(
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
                                backgroundImage: CachedNetworkImageProvider(currentUser.value.image?.url),
                              ),

                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.transparent,
                                child: GestureDetector(
                                  onTap: () {
                                    _selectImage(context);
                                  },
                                  child: Align(
                                  alignment: Alignment.topRight,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 15,
                                    child: Icon(Icons.camera_alt, size: 17.0, color: Color(0xFF404040),
                                    ),
                                  ),
                                ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(currentUser.value.name, textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headline5.merge(TextStyle(color: Theme.of(context).primaryColor)),
                        ),
                      ],
                    ),
                  ),

                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    leading: Icon(
                      Icons.person,
                      color: Theme.of(context).hintColor,
                    ),
                    title: Text(
                      AppLocalization.of(context).about,
                      style: Theme.of(context).textTheme.headline4,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      currentUser.value?.bio ?? "",
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                  ),

                  Visibility(
                    visible: val == Constants.GROCERY,
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: Icon(
                        Icons.my_location,
                        color: Theme.of(context).hintColor,
                      ),
                      title: Text(
                        AppLocalization.of(context).address,
                        style: Theme.of(context).textTheme.headline4,
                      ),
                      trailing: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).pushNamed('/PickAddress');
                        },
                        child: Text(AppLocalization.of(context).edit, style: Theme.of(context).textTheme.bodyText2.copyWith(decoration: TextDecoration.underline),),
                      ),
                    ),
                  ),

                  Visibility(
                    visible: val == Constants.GROCERY,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        currentUser.value?.address ?? "",
                        style: Theme.of(context).textTheme.bodyText2,
                      ),
                    ),
                  ),

                  Visibility(
                    visible: val == Constants.GROCERY,
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: Icon(
                        Icons.shopping_basket,
                        color: Theme.of(context).hintColor,
                      ),
                      title: Text(
                        AppLocalization.of(context).recent_orders,
                        style: Theme.of(context).textTheme.headline4,
                      ),
                    ),
                  ),

                  val == Constants.RIDE ? Container() : _con.recentOrders.isEmpty
                      ? EmptyOrdersWidget()
                      : ListView.separated(
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          primary: false,
                          itemCount: _con.recentOrders.length,
                          itemBuilder: (context, index) {
                            var _order = _con.recentOrders.elementAt(index);
                            return OrderItemWidget(expanded: index == 0 ? true : false, order: _order);
                          },
                          separatorBuilder: (context, index) {
                            return SizedBox(height: 20);
                          },
                        ),
                ],
              ),
            ),
    );
  }

  void _editBio() {

    _nameController.text = currentUser.value?.name ?? "";
    _bioController.text = currentUser.value?.bio ?? "";

    showDialog(
        context: context,
        builder: (BuildContext context) {

          return Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[

                  Text(AppLocalization.of(context).profile, style: Theme.of(context).textTheme.headline4.copyWith(color: Theme.of(context).accentColor),),

                  SizedBox(height: 20,),

                  Form(
                    key: _con.formKey,
                    child: TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.text,
                      validator: (input) => input.length < 3 ? AppLocalization.of(context).not_a_valid_full_name : null,
                      style: Theme.of(context).textTheme.subtitle1,
                      decoration: InputDecoration(
                        hintText: AppLocalization.of(context).full_name,
                        hintStyle: TextStyle(color: Theme.of(context).focusColor.withOpacity(0.7)),
                        contentPadding: EdgeInsets.all(10),
                        border: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).focusColor.withOpacity(0.2))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).focusColor.withOpacity(0.5))),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).focusColor.withOpacity(0.2))),
                      ),
                    ),
                  ),

                  SizedBox(height: 10,),

                  TextField(
                    controller: _bioController,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    style: Theme.of(context).textTheme.bodyText2,
                    decoration: InputDecoration(
                      hintText: AppLocalization.of(context).your_biography,
                      hintStyle: TextStyle(color: Theme.of(context).focusColor.withOpacity(0.7)),
                      contentPadding: EdgeInsets.all(10),
                      border: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).focusColor.withOpacity(0.2))),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).focusColor.withOpacity(0.5))),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).focusColor.withOpacity(0.2))),
                    ),
                  ),

                  SizedBox(height: 25,),

                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[

                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: EdgeInsets.all(10),
                            alignment: Alignment.center,
                            color: Colors.red,
                            child: Text(AppLocalization.of(context).cancel, style: Theme.of(context).textTheme.subtitle1.copyWith(color: Colors.white),),
                          ),
                        ),
                      ),

                      SizedBox(width: 10,),

                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            _con.updateProfile(_nameController.text, _bioController.text);
                          },
                          child: Container(
                            padding: EdgeInsets.all(10),
                            alignment: Alignment.center,
                            color: Theme.of(context).accentColor,
                            child: Text(AppLocalization.of(context).save, style: Theme.of(context).textTheme.subtitle1.copyWith(color: Colors.white),),
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          );
        }
    );
  }

  void _selectImage(BuildContext context) {

    showDialog(
        context: context,
        builder: (BuildContext context) {

          return ProfileImagePickerWidget(con: _con,);
        }
    );
  }

  Future<void> _initSp() async {

    _prefs = await SharedPreferences.getInstance();

    try {

      int res = await _prefs.getInt('service');

      setState(() {
        val = res;
      });
    }
    catch(e) {}
  }
}
