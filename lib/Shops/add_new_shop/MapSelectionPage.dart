import 'package:flutter/material.dart';
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

  void _confirmSelection() {
    Navigator.pop(context,
        "${_selectedLocation.latitude}, ${_selectedLocation.longitude}");
  }

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
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query");

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

          if (predictions.isNotEmpty) {
            _selectLocation(predictions[0]['place_id']);
          }
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
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId");

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
            _searchResults.clear();
            _isSearching = false;
            _searchController.text = result['formatted_address'] ?? "";
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
