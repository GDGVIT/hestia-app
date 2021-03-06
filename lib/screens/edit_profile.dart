import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:project_hestia/model/global.dart';
import 'package:project_hestia/model/util.dart';
import 'package:project_hestia/screens/login.dart';
import 'package:project_hestia/services/shared_prefs_custom.dart';
import 'package:project_hestia/widgets/my_back_button.dart';

Future<Map<String, String>> _getUserDetails() async {
  final sp = SharedPrefsCustom();
  final name = await sp.getUserName();
  final email = await sp.getUserEmail();
  final phone = await sp.getPhone();
  final userDetails = {
    'name': '',
    'email': '',
    'phone': '',
  };
  userDetails['name'] = name ?? '';
  userDetails['email'] = email ?? '';
  userDetails['phone'] = phone ?? '';
  return userDetails;
}

class EditProfileScreen extends StatefulWidget {
  static const routename = "/edit-profile";
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // TextEditingController emailController = TextEditingController();
  // TextEditingController nameController = TextEditingController();
  // TextEditingController phoneController = TextEditingController();
  bool isLoading = false;

  _showSnackBar(int code, String msg) {
    SnackBar snackbar;
    if (code == 200) {
      snackbar = SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(msg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        backgroundColor: Colors.teal,
      );
    } else if (code == 300) {
      snackbar = SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(msg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        backgroundColor: Colors.amber[900],
      );
    } else {
      snackbar = SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(msg),
        backgroundColor: colorRed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      );
    }
    _scaffoldKey.currentState.showSnackBar(snackbar);
  }

  Map<String, String> newuserDetails = {
    'name': '',
    'email': '',
    'phone': '',
  };

  submitData() async {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    if (!_formKey.currentState.validate()) {
      return;
    }
    _formKey.currentState.save();
    print(newuserDetails);
    final body = jsonEncode(newuserDetails);
    print(body);
    setState(() {
      isLoading = true;
    });
    var sp = SharedPrefsCustom();
    final token = await sp.getToken();
    try {
      final response = await http.post(
        URL_UPDATE_USER,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          'token': token,
        },
        body: body,
      );
      //print(token);
      Map<String, dynamic> responseBody = jsonDecode(response.body);
      print("Response of edit is" + responseBody.toString());
      if (response.statusCode == 200) {
        if (responseBody.containsKey("Status")) {
          _showSnackBar(200, responseBody["Status"]);
        } else if (responseBody.containsKey("Alert")) {
          _showSnackBar(
              300, responseBody["Alert"] + '. Log in with your new email id.');
          sp.setLoggedInStatus(false);
          Future.delayed(
              Duration(seconds: 3),
              () => Navigator.of(context).pushNamedAndRemoveUntil(
                  LoginScreen.routename, (route) => false));
        }
        sp.setUserName(newuserDetails['name']);
        sp.setUserEmail(newuserDetails['email']);
        sp.setPhone(newuserDetails["phone"]);
      } else if (response.statusCode == 409) {
        _showSnackBar(409, "Email already in use");
      }
    } catch (e) {
      print(e.toString());
    }
    setState(() {
      isLoading = false;
    });
  }

  _changePassword() async {
    final sp = SharedPrefsCustom();
    final email = await sp.getUserEmail();
    Map<String, String> bodyText = {
      'email': email,
    };
    final body = jsonEncode(bodyText);
    try {
      final response = await http.post(
        URL_RESET_PASSWORD,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: body,
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody.containsKey("Status")) {
          _showSnackBar(200, responseBody["Status"]);
        }
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).canvasColor,
        elevation: 0,
        iconTheme: Theme.of(context)
            .iconTheme
            .copyWith(color: Theme.of(context).canvasColor),
      ),
      body: FutureBuilder(
        future: _getUserDetails(),
        builder: (ctx, snapshot) {
          if (snapshot.hasData) {
            final Map<String, String> userDetails = snapshot.data;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        MyBackButton(),
                        SizedBox(
                          width: 25,
                        ),
                        Text(
                          'Edit Profile',
                          style: screenHeadingStyle,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            initialValue: userDetails['name'],
                            maxLength: 100,
                            // controller: nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                                gapPadding: 10,
                              ),
                            ),
                            // onChanged: (value) => userInfo["name"] = value,
                            onSaved: (value) =>
                                newuserDetails["name"] = value.trim(),
                            validator: (value) {
                              if (value == "") {
                                return "This field is required";
                              }
                            },
                          ),
                          SizedBox(
                            height: 30,
                          ),
                          TextFormField(
                            maxLength: 100,
                            initialValue: userDetails['email'],
                            // controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            textCapitalization: TextCapitalization.none,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                                gapPadding: 10,
                              ),
                            ),
                            // onChanged: (value) => userInfo["name"] = value,
                            onSaved: (value) =>
                                newuserDetails["email"] = value.trim(),
                            validator: (value) {
                              if (value == "") {
                                return "This field is required";
                              }
                              if (!RegExp(
                                      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                  .hasMatch(value)) {
                                return 'Please enter correct email';
                              }
                            },
                          ),
                          SizedBox(
                            height: 30,
                          ),
                          TextFormField(
                            maxLength: 100,
                            initialValue: userDetails['phone'],
                            // controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                                gapPadding: 10,
                              ),
                            ),
                            // onChanged: (value) => userInfo["name"] = value,
                            onSaved: (value) =>
                                newuserDetails["phone"] = value.trim(),
                            validator: (value) {
                              if (value.contains(" ")) {
                                return "Can\'t have spaces";
                              }
                              if (value == "") {
                                return "This field is required";
                              }
                              if (value.length != 10) {
                                return "Enter a valid phone number";
                              }
                            },
                          ),
                          SizedBox(
                            height: 30,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        (isLoading)
                            ? CircularProgressIndicator()
                            : RaisedButton(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5)),
                                color: mainColor,
                                textColor: colorWhite,
                                onPressed: submitData,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text('Submit'),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    SvgPicture.asset("assets/images/check.svg"),
                                  ],
                                ),
                              ),
                        SizedBox(
                          width: 15,
                        ),
                        RaisedButton(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                          color: colorWhite,
                          textColor: colorBlack,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text('Cancel'),
                              SizedBox(
                                width: 5,
                              ),
                              Icon(
                                Icons.close,
                                size: 19,
                              )
                            ],
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    Divider(),
                    FlatButton(
                      child: Text('Change Password'),
                      textColor: mainColor,
                      onPressed: _changePassword,
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Edit Profile',
                    style: screenHeadingStyle,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
