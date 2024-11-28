import 'package:bathroom_app/reviewsPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'model/nearby_response.dart';

class ListBathrooms extends StatefulWidget {
  final ScrollController scrollController;
  final NearbyPlacesResponse nearbyPlacesResponse;

  const ListBathrooms({required this.scrollController, required this.nearbyPlacesResponse });
  @override
  _ListBathroomsState createState() => _ListBathroomsState();
}

class _ListBathroomsState extends State<ListBathrooms> {
  final DraggableScrollableController sheetController = DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    print(widget.nearbyPlacesResponse);
    if (widget.nearbyPlacesResponse.results != null) {
      debugPrint("Here!");
    }
    else{
      debugPrint("Null!");
    }
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: widget.nearbyPlacesResponse.results != null ?
      CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).hintColor,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                height: 4,
                width: 40,
                margin: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SliverAppBar(
            title: Text('My App'),
            primary: false,
            pinned: true,
            centerTitle: false,
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                var results = widget.nearbyPlacesResponse.results!;
                return FutureBuilder<Widget>(
                  future: nearbyPlacesWidget(results[index]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return snapshot.data ?? Container(); // Return the widget or an empty container
                    }
                  },
                );
              },
              childCount: widget.nearbyPlacesResponse.results?.length ?? 0, // Return 0 if results is null
            ),
          ),
        ],

      ) : Center(
        child: CircularProgressIndicator(),
      ),

    );
  }

  Future<Widget> nearbyPlacesWidget(Results results) async {
    // Fetch reviews and wait for completion
    Map<String, dynamic> reviews = await fetchReviews(results.placeId.toString());

    double rating = 0;
    int numRating = 0;
    // Access the reviews in a for loop
    reviews.forEach((reviewId, reviewData) {
      print("Review ID: $reviewId");
      // print("Review data: $reviewData");
      try {
          rating += int.parse(reviewData["rating"].toString());
          numRating += 1;
      }
      on Exception catch (e) {
        print(e);
      };
    });

    rating = rating / numRating;

    print(results.placeId!);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Reviews(placeId: results.placeId.toString()),
          ),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.deepPurple),
            borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text("Name: " + results.name!),
            Text("ID: " + results.placeId!),
            Text("Location: " +
                results.geometry!.location!.lat.toString() +
                " , " +
                results.geometry!.location!.lng.toString()),
            Text(results.openingHours != null ? "Open" : "Closed"),
            Text(results.types!.length > 1 ? 'Types ${results.types!}' : 'Types ${results.types!}'),
            Text(numRating != 0 ? rating.toString() : "No reviews yet"),
            Icon(Icons.question_mark_outlined),
          ],
        ),
      ),
    );
  }
}

// Future<Map<String, dynamic>> fetchReviews() async {
//   // Create an empty map to store the reviews
//   Map<String, dynamic> reviewsMap = {};
//   CollectionReference collection = FirebaseFirestore.instance.collection('reviews');
//
//   try {
//     // Get the collection reference
//     QuerySnapshot querySnapshot =
//     await collection.get();
//
//     // Iterate through the documents and store them in the map
//     for (var doc in querySnapshot.docs) {
//       // Assuming each document has a unique ID which is used as the key in the map
//       reviewsMap[doc.id] = doc.data();
//     }
//
//     return reviewsMap;
//   } catch (e) {
//     // Handle any errors
//     print("Error fetching reviews: $e");
//     return {};
//   }
// }

Future<Map<String, dynamic>> fetchReviews(String placeId) async {
  Map<String, dynamic> reviewsMap = {};
  CollectionReference collection = FirebaseFirestore.instance.collection('reviews');

  try {
    // Get the collection reference and query documents where placeId matches
    QuerySnapshot querySnapshot = await collection.where('placeID', isEqualTo: placeId)
        .get();

    // Iterate through the documents and store them in the list
    for (var doc in querySnapshot.docs) {
      reviewsMap[doc.id] = doc.data();
    }
    print(reviewsMap);
    return reviewsMap;
  } catch (e) {
    // Handle any errors
    print("Error fetching reviews: $e");
    return {};
  }
}


class FireCollection {
  static Future<void> createCollectionWithDocument(name) async {
    await FirebaseFirestore.instance.collection('reviews').add({
      'name': name,
      'used': false,
    });
  }

  void updateCollection(docID, data) {
    final collection = FirebaseFirestore.instance.collection('pokemon');
    if (data['used'] == true) {
      collection.doc(docID).update({'used': false});
    } else {
      collection.doc(docID).update({'used': true});
    }
  }

  void deleteDoc(docID) {
    final collection = FirebaseFirestore.instance.collection('pokemon');
    collection.doc(docID).delete();
  }
}
