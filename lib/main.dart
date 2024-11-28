/* Author: Daeshaun Morrison, Muhlenberg College class of 2024(daeshaunkmorrison@gmail.com)
Date:
Instructor: Professor Silveyra
Extra features:
1) `nearby_response()` is instantiated and populated by a JSON file from Google Places API
2) Added at least one extra Widget: GoogleMaps (commented out)
3) Separated the program into multiple files
4) Updated the database by the user: `MyHomePage(title: 'Welcome ${FirebaseAuth.instance.currentUser?.email}')`
5)
Errors:
1) Google Map and fetched nearby places can not be displayed at same time.
2) No shared Preferences; "Incorporate sharedPreferences for at least three values"

 */
import 'dart:convert';
import 'package:bathroom_app/model/nearby_response.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'listBathrooms.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FirebaseAuth.instance.currentUser == null ? const MyHomePage(title: 'Bathroom Finder') : MyHomePage(title: 'Welcome ${FirebaseAuth.instance.currentUser?.email}') ,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late GoogleMapController mapController;
  late Position _currentPosition;
  late LatLng _center;
  bool _locationLoaded = false; // Track if the location has been loaded
  bool _detailsLoaded = false; // Track if the location has been loaded

  var apiKey = '';
  var placeId = 'ChIJqdGUQQgDGTkRMWBf2gAKAEQ';
  String radius = "9000";

  final DraggableScrollableController sheetController = DraggableScrollableController();

  late NearbyPlacesResponse nearbyPlacesResponse = NearbyPlacesResponse();
  // late NearbyPlacesResponse nearbyPlacesResponse;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Call to get current location only once
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              setState(() {});
            },
          ),
        ],
      ),
      body: _locationLoaded // Check if location is loaded
          ? Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: _center, zoom: 11.0),
            markers: {
               Marker(
                markerId: const MarkerId("Current Location"),
                position: LatLng(_currentPosition.latitude, _currentPosition.longitude),
              ),
              if (nearbyPlacesResponse.results != null)
                for (final e in nearbyPlacesResponse.results!)
                  Marker(
                    markerId: MarkerId(e.name ?? ""),
                    position: LatLng(
                      e.geometry?.location?.lat ?? 0,
                      e.geometry?.location?.lng ?? 0,
                    ),
                    infoWindow: InfoWindow(
                      title: e.name,
                    )
                  ),
            }, // markers
          ),
          DraggableScrollableSheet(
            controller: sheetController,
            builder: (BuildContext context, scrollController) {
              debugPrint("here ${nearbyPlacesResponse.results}");
              return ListBathrooms(scrollController: scrollController, nearbyPlacesResponse: nearbyPlacesResponse);
            },
          ),
          ElevatedButton(onPressed: (){

            _getNearbyPlaces();
            setState(() {

            });

          }, child: const Text("Get Nearby Places")),
        ],
      )
          : Center(
        child: CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SignInScreen()),
          );
        },
        tooltip: 'Sign up Or Login',
        child: const Icon(Icons.login),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      _center = LatLng(_currentPosition.latitude, _currentPosition.longitude);
      _locationLoaded = true; // Set location loaded to true
    });
    debugPrint(_currentPosition.latitude.toString());
    debugPrint(_currentPosition.longitude.toString());
    _getNearbyPlaces();
  }

  void _getNearbyPlaces() async {

    // var url = Uri.parse('https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_currentPosition.latitude},${_currentPosition.longitude}&radius=$radius&key=$apiKey');
    // var types = 'amusement_park|aquarium|art_gallery|atm|bakery|bank|bar|cafe|campground|casino|movie_theater|convenience_store|department_store|hospital|library|museum|park|restaurant|shopping_mall|stadium|supermarket|train_station|university';
    var types = 'restaurant';
    var url = Uri.parse('https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_currentPosition.latitude},${_currentPosition.longitude}&radius=$radius&type=$types&key=$apiKey');

    var response = await http.post(url);

    setState(() {
      nearbyPlacesResponse = NearbyPlacesResponse.fromJson(jsonDecode(response.body));
      _detailsLoaded = true;
      // debugPrint("Yup ${url}");
      // debugPrint("Yup ${nearbyPlacesResponse.results?[0].placeId}");
    });
  }
}

class SignInScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _signInWithEmailAndPassword(BuildContext context) async {
    try {
      // Sign in with email and password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Navigate to main screen on successful sign-in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage(title: 'Welcome ${FirebaseAuth.instance.currentUser?.email}')),
      );
    } catch (e) {
      // Handle sign-in errors
      print('Sign in failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Sign in failed: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => _signInWithEmailAndPassword(context),
              child: Text('Sign In'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen()),
                );
              },
              child: Text('No account? Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _signUpWithEmailAndPassword(BuildContext context) async {
    try {
      // Sign up with email and password
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Navigate to main screen on successful sign-up
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage(title: 'Welcome ${FirebaseAuth.instance.currentUser?.email}')),
      );
    } catch (e) {
      // Handle sign-up errors
      print('Sign up failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Sign up failed: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: () => _signUpWithEmailAndPassword(context),
              child: Text('Sign Up'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SignInScreen()),
                );
              },
              child: Text('Already have an account? Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}