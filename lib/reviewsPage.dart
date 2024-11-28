import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:getwidget/getwidget.dart';

class Reviews extends StatelessWidget {
  final String placeId;

  Reviews({required this.placeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Future Builder Example'),
      ),
      body: Center(
        child: FutureBuilder<Map<String, dynamic>>(
          future: fetchReviews(placeId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              // Extract reviews data from the snapshot
              final reviews = snapshot.data ?? {};

              if (reviews.isEmpty) {
                return Text("No reviews yet");
              } else {
                return ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    // Extract review data
                    var reviewData = reviews.values.toList()[index];
                    return Card(
                      child: GFListTile(
                        title: Text("From Review ID: ${reviews.keys.toList()[index]}"),
                        subTitle: Text("Review Data: $reviewData"),
                      ),
                    );
                  },
                );
              }
            }
          },
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> fetchReviews(String placeId) async {
    Map<String, dynamic> reviewsMap = {};
    CollectionReference collection = FirebaseFirestore.instance.collection('reviews');

    try {
      // Get the collection reference and query documents where placeId matches
      QuerySnapshot querySnapshot = await collection.where('placeID', isEqualTo: placeId).get();

      // Iterate through the documents and store them in the map
      for (var doc in querySnapshot.docs) {
        reviewsMap[doc.id] = doc.data();
      }
      return reviewsMap;
    } catch (e) {
      // Handle any errors
      print("Error fetching reviews: $e");
      return {};
    }
  }
}
