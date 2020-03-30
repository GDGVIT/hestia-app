import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project_hestia/Profile/reportPage.dart';
import 'package:project_hestia/model/chatMessage.dart';
import 'package:project_hestia/model/global.dart';
import 'package:project_hestia/model/util.dart';
import 'package:project_hestia/services/date_formatter.dart';
import 'package:project_hestia/services/shared_prefs_custom.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatScreenPage extends StatefulWidget {
  ChatScreenPage({Key key, this.senderID, this.receiverID}) : super(key: key);
  final int senderID, receiverID;

  @override
  ChatScreenPageState createState() => ChatScreenPageState();
}

class ChatScreenPageState extends State<ChatScreenPage> {
  ChatScreenPageState({this.senderID, this.receiverID});
  final int senderID, receiverID;
  @override
  void initState() {
    super.initState();
    //showChats();
    
    var URL= 'ws://hestia-chat.herokuapp.com/api/v1/ws?chat='+widget.receiverID.toString();
    print("URL is "+URL);
    channel = WebSocketChannel.connect(Uri.parse(URL));
  }

  Map<String, int> data_create_chat = {
    'receiver': 27,
    'sender': 21 
  };

Messages m;
Future<Messages> showChats() async{
  //print("I am in show chats");
  //final receiverID = await SharedPrefsCustom().getUserID();
  data_create_chat["receiver"] = widget.receiverID;
  data_create_chat["sender"] = widget.senderID;
  //print("Body of getting messages is "+data_create_chat.toString());
  try {
    final token = await SharedPrefsCustom().getToken();
    final response = await http.post(
      URL_GET_MESSAGES,
      headers: {
        HttpHeaders.authorizationHeader: token,
      },
      body: json.encode(data_create_chat)
    );
    //print("Response in getting messages is "+response.body.toString());
    final result = json.decode(response.body);
    //print("Messgaes are "+result.toString());
    if (response.statusCode == 200) {
      setState(() {
        m = Messages.fromJson(result);
      });
    } else {
        Fluttertoast.showToast(msg: result['message']);
    }
  } catch (e) {
    print(e.toString());
  }
  return m;
}

  @override
  void dispose() {
    super.dispose();
    channel.sink.close();
  }

  String text = '';
  GlobalKey<FormState> _key = new GlobalKey();
  bool _validate = false;

  bool left = true;

  WebSocketChannel channel;
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        // backgroundColor: colorWhite,
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: true,
          iconTheme: IconThemeData(
            color: Colors.black
          ),
          backgroundColor: Theme.of(context).canvasColor,
        ),
        body: Container(
            width: MediaQuery
                .of(context)
                .size
                .width,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(top: 10.0, left: 20.0, right:20.0, bottom: 18.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Person Name',
                              style: TextStyle(color: colorBlack, fontSize: 20.0, fontWeight: FontWeight.bold),
                            ),
                            Text('Item Name')
                          ],
                        ),
                        GestureDetector(
                          onTap: (){
                            Navigator.push(
                            context,
                            new MaterialPageRoute(
                                builder:
                                    (BuildContext context) =>
                                        ReportScreen(id: widget.receiverID,)));
                          },
                          child: Container(
                            //margin: EdgeInsets.only(right: 10.0),
                            child : SvgPicture.asset('assets/images/report.svg')
                          )
                        ), 
                      ],
                    ),
                  ),
                  new Expanded(
                    child: StreamBuilder(
                    stream: channel.stream,
                    builder: (context, snapshot) {
                      print(
                        "Data in snapshot is "+snapshot.toString()
                      );
                      return snapshot.hasData ? 
                        Text(
                          snapshot.data.toString(),
                          style: Theme.of(context).textTheme.display1
                        )
                        :
                        CircularProgressIndicator();
                    },
                  ),
                  ),
                  new Expanded(
                  child : FutureBuilder(
                    future: showChats(),
                    builder: (ctx, snapshot) {
                      if (snapshot.hasData) {
                        Messages messages = snapshot.data;
                        if (messages.msgs.length <= 0) {
                          return Text('No messages found');
                        } else {
                          return ListView.builder(
                            itemCount: messages.msgs.length,
                            itemBuilder: (BuildContext ctxt, int index) {
                              return Container(
                                margin: (messages.msgs[index].sender.toString() != widget.senderID.toString())? 
                                  EdgeInsets.only(left: 15.0, right: 100.0, top: 10.0, bottom: 10.0)
                                  :
                                  EdgeInsets.only(left: 100.0, right: 15.0, top: 10.0, bottom: 10.0),
                                padding: EdgeInsets.only(top: 15.0, bottom: 15.0, left: 15.0, right: 15.0),
                                decoration: BoxDecoration(
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                          blurRadius: 3.0,
                                          color: Colors.grey[600],
                                          offset: Offset(0.5, 0.5))
                                    ],
                                    shape: BoxShape.rectangle,
                                    color: (messages.msgs[index].sender.toString() != widget.senderID.toString()) ? colorWhite : mainColor,
                                    borderRadius:
                                    BorderRadius.all(Radius.circular(5))),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(top: 0.0, bottom: 10.0),
                                      child : Text(messages.msgs[index].title, style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold, color: (messages.msgs[index].sender.toString() != widget.senderID.toString()) ? colorBlack : colorWhite,),),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 0.0, bottom: 10.0),
                                      child : Text('Item', style: TextStyle(color: (messages.msgs[index].sender.toString() != widget.senderID.toString()) ? colorBlack : colorWhite, fontSize: 13.0,)),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 0.0, bottom: 10.0),
                                      child : Text(dateFormatter(messages.msgs[index].createdAt), style: TextStyle(color: (messages.msgs[index].sender.toString() != widget.senderID.toString()) ? colorGrey : colorWhite, fontSize: 13.0,))
                                    )
                                  ],
                                )
                              );
                            }
                        );
                        }
                      } else {
                        return Container(
                          alignment: Alignment(0, 0),
                          width: 40.0,
                          height: 40.0,
                          child : CircularProgressIndicator()
                        );
                      }
                    },
                  )
                  
                  
                 /* ListView.builder(
                  itemCount: 2,
                  itemBuilder: (BuildContext ctxt, int index) {
                    return Container(
                      margin: index==1? 
                        EdgeInsets.only(left: 15.0, right: 100.0, top: 10.0, bottom: 10.0)
                        :
                        EdgeInsets.only(left: 100.0, right: 15.0, top: 10.0, bottom: 10.0),
                      padding: EdgeInsets.only(top: 15.0, bottom: 15.0, left: 15.0, right: 15.0),
                      decoration: BoxDecoration(
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                                blurRadius: 3.0,
                                color: Colors.grey[600],
                                offset: Offset(0.5, 0.5))
                          ],
                          shape: BoxShape.rectangle,
                          color: index==1 ? colorWhite : mainColor,
                          borderRadius:
                          BorderRadius.all(Radius.circular(5))),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.only(top: 0.0, bottom: 10.0),
                            child : Text('Name', style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold, color: index==1 ? colorBlack : colorWhite,),),
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 0.0, bottom: 10.0),
                            child : Text('Item', style: TextStyle(color: index==1 ? colorBlack : colorWhite, fontSize: 13.0,)),
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 0.0, bottom: 10.0),
                            child : Text('Date and Time',  style: TextStyle(color: index==1 ? colorGrey : colorWhite, fontSize: 13.0,))
                          )
                        ],
                      )
                    );
                  }
              )*/
            ),
            Container(
              color: colorWhite,
              margin: EdgeInsets.all(10.0),
              child : Form(
                  key: _key,
                  autovalidate: _validate,
                  child : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child : TextFormField(
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.only(left: 5.0),
                          fillColor: colorWhite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            gapPadding: 5,
                          ),
                          hintText: 'Enter message',
                        ),
                        validator: (val) => (val.length == 0)
                              ? 'Please enter some text'
                              : null,
                          onSaved: (String val) {
                            setState(() {
                              text = val;
                            });
                          }
                      ),),
                      GestureDetector(
                        onTap: (){
                          sendMessage();
                        },
                        child: Text('Send', style: TextStyle(color: mainColor, fontWeight: FontWeight.bold),)
                      )
                    ],
                  )) 
            )
          ]
        )
      )
    );
  }

var data_send_message = {
    'receiver': 27,
    'from' : 1,
    'text': "fv" 
};

sendMessage() async{

  if (_key.currentState.validate()) {
    _key.currentState.save();
  
    data_send_message["receiver"] = widget.receiverID;
    data_send_message["from"] = widget.senderID;
    data_send_message["text"] = text;
    
    channel.sink.add(controller.text);
    try {
      final token = await SharedPrefsCustom().getToken();
      final response = await http.post(
        URL_CREATE_MESSAGE,
        headers: {
          HttpHeaders.authorizationHeader: token,
        },
        body: json.encode(data_send_message)
      );
      print("response is "+response.body.toString());
      final result = json.decode(response.body);
      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: "Message sent");
        showChats();
      } else {
          Fluttertoast.showToast(msg: result['message']);
      }
    } catch (e) {
      print(e.toString());
    }
  } else {
      setState(() {
        _validate = true;
      });
    }
}
}