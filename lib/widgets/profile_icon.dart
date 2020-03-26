import 'package:flutter/material.dart';
import 'package:project_hestia/Profile/profilePage.dart';
import 'package:project_hestia/model/util.dart';
import 'package:project_hestia/screens/login.dart';


enum Options {
  Profile,
  Logout,
}


class ProfileIcon extends StatelessWidget {
  const ProfileIcon({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'profile',
      child: Material(
        child: PopupMenuButton(
          offset: Offset(0, 50),
          onSelected: (Options option) {
            if (option == Options.Profile) {
              //print("profile clicked");

              Navigator.push(
                  context,
                  new MaterialPageRoute(
                      builder: (BuildContext context) =>
                          ProfilePage()));
            } else if (option == Options.Logout) {
              print("logout clicked");
              Navigator.of(context)
                  .pushReplacementNamed(LoginScreen.routename);
            }
          },
          itemBuilder: (ctx) {
            return [
              PopupMenuItem(
                child: Text('Profile'),
                value: Options.Profile,
              ),
              PopupMenuItem(
                child: Text('Logout'),
                value: Options.Logout,
              ),
            ];
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 27.0),
            child: CircleAvatar(
              backgroundColor: mainColor,
              child: Icon(
                Icons.account_circle,
                size: 40,
                color: colorWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
