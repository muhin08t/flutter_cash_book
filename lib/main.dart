import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cash_book/provider/cash_record_provider.dart';
import 'package:flutter_cash_book/screen/home_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CashRecordProvider()..loadCashRecords("all"), // auto load on start
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cash Book',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.lightBlue, // sets AppBar background
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle(   // 👈 controls status bar
              statusBarColor: Colors.blue,        // background color
              statusBarIconBrightness: Brightness.light // icons: light or dark
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

