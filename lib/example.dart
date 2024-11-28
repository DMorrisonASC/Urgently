import 'package:flutter/material.dart';

void main() {
  runApp(GoogleMapsApp());
}

class Location {
  final String name;
  final double latitude;
  final double longitude;
  final String description;

  Location({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.description,
  });
}

class GoogleMapsApp extends StatelessWidget {
  final List<Location> locations = [
    Location(
      name: 'Statue of Liberty',
      latitude: 40.6892,
      longitude: -74.0445,
      description: 'A symbol of freedom and democracy.',
    ),
    Location(
      name: 'Eiffel Tower',
      latitude: 48.8584,
      longitude: 2.2945,
      description: 'Iconic landmark of Paris, France.',
    ),
    Location(
      name: 'Sydney Opera House',
      latitude: -33.8568,
      longitude: 151.2153,
      description: 'Famous performing arts center in Sydney, Australia.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Maps Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GoogleMapScreen(locations: locations),
    );
  }
}

class GoogleMapScreen extends StatelessWidget {
  final List<Location> locations;

  GoogleMapScreen({required this.locations});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Maps'),
      ),
      body: Center(
        child: Text(
          'Map Placeholder', // Placeholder for the map
          style: TextStyle(fontSize: 20.0),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: locations
            .map((location) => BottomNavigationBarItem(
          icon: Icon(Icons.place),
          label: location.name,
        ))
            .toList(),
        onTap: (index) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LocationDetailScreen(location: locations[index]),
            ),
          );
        },
      ),
    );
  }
}

class LocationDetailScreen extends StatelessWidget {
  final Location location;

  LocationDetailScreen({required this.location});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(location.name),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description:',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            Text(
              location.description,
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }
}
