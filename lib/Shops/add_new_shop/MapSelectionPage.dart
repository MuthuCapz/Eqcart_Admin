import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../../utils/colors.dart';

class MapSelectionPage extends StatefulWidget {
  @override
  _MapSelectionPageState createState() => _MapSelectionPageState();
}

class _MapSelectionPageState extends State<MapSelectionPage> {
  LatLng _selectedLocation = LatLng(37.7749, -122.4194);
  GoogleMapController? mapController;
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Set<Marker> _markers = {};
  Timer? _debounce;
  String _selectedAddress = ''; // To store the selected address

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar("Location services are disabled");
      _setDefaultLocation();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar("Location permission denied");
        _setDefaultLocation();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar("Location permission permanently denied");
      _setDefaultLocation();
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _selectedLocation = LatLng(position.latitude, position.longitude);
      _isLoading = false;
    });
    await _getAddressFromLatLng(position.latitude, position.longitude);
    _updateMarker(_selectedLocation);
    _moveCamera(_selectedLocation);
  }

  void _setDefaultLocation() {
    setState(() {
      _selectedLocation = LatLng(40.7128, -74.0060);
      _isLoading = false;
    });
    _updateMarker(_selectedLocation);
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _updateMarker(_selectedLocation);
    _moveCamera(_selectedLocation);
  }

  void _moveCamera(LatLng position) {
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(position, 15), //  Moves to searched location
      );
    }
  }

  final apiKey = "AIzaSyCsch2Dos82VGx3jvHDseoOpVj0gbktOqQ";

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 600), () {
      _searchLocation(query);
    });
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$apiKey");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'];

          setState(() {
            _searchResults = predictions;
            _isSearching = true;
          });
        } else {
          print("Google API Error: ${data['status']}");
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("No results found!")));
        }
      } else {
        print("HTTP Error: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to fetch data from Google API")));
      }
    } catch (e) {
      print("Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Network error! Check API key & internet.")));
    }
  }

  Future<void> _selectLocation(String placeId) async {
    final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final result = data['result'];
          final lat = result['geometry']['location']['lat'];
          final lng = result['geometry']['location']['lng'];
          final newLocation = LatLng(lat, lng);

          setState(() {
            _selectedLocation = newLocation;
            _selectedAddress =
                result['formatted_address'] ?? "Address not available";
            _searchResults.clear();
            _isSearching = false;
            _searchController.text = _selectedAddress;
          });

          _updateMarker(newLocation);
          _moveCamera(newLocation);
        } else {
          print("Google API Error: ${data['status']}");
        }
      } else {
        print("HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  void _confirmSelection() {
    // If no address has been selected by search, use the current location address
    Navigator.pop(
        context,
        _selectedAddress.isNotEmpty
            ? _selectedAddress
            : "Address not available");
  }

  void _updateMarker(LatLng position) {
    setState(() {
      _markers = {
        Marker(
          markerId: MarkerId("selected"),
          position: position,
        ),
      };
    });
  }

// Method to fetch address from lat, long
  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final result = data['results'][0];
          setState(() {
            _selectedAddress =
                result['formatted_address'] ?? "Unknown location";
          });
        } else {
          print("Google API Error: ${data['status']}");
          setState(() {
            _selectedAddress = "Unable to fetch address";
          });
        }
      } else {
        print("HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception: $e");
      setState(() {
        _selectedAddress = "Network error!";
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text("Select Location", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.secondaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: 15,
                  ),
                  markers: _markers,
                  onTap: (LatLng tappedPoint) {
                    setState(() {
                      _selectedLocation = tappedPoint;
                    });
                    _updateMarker(tappedPoint);
                    _moveCamera(tappedPoint);
                    _getAddressFromLatLng(
                        tappedPoint.latitude, tappedPoint.longitude);
                  },
                ),

          // Search Box
          Positioned(
            top: 15,
            left: 15,
            right: 15,
            child: Column(
              children: [
                Material(
                  elevation: 5,
                  borderRadius: BorderRadius.circular(10),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search location",
                      prefixIcon:
                          Icon(Icons.search, color: AppColors.secondaryColor),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.cancel,
                                  color: AppColors.secondaryColor),
                              onPressed: () {
                                _searchController
                                    .clear(); // Clear the text field
                                setState(() {
                                  _searchResults
                                      .clear(); // Clear search results
                                  _isSearching = false; // Stop searching
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),

                // Search Results List
                if (_isSearching && _searchResults.isNotEmpty)
                  Container(
                    color: Colors.white,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: Icon(Icons.location_on,
                              color: AppColors.secondaryColor),
                          title: Text(result['description']),
                          onTap: () => _selectLocation(result['place_id']),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryColor,
            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text("Confirm",
              style: TextStyle(color: Colors.white, fontSize: 16)),
          onPressed: _confirmSelection,
        ),
      ),
    );
  }
}
