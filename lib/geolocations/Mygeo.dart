import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─── Tarifs ────────────────────────────────────────────────────────────────────
const double BASE_CLASSIC = 100.0;
const double BASE_PREMIER = 150.0;
const double RATE_CLASSIC = 15.0;
const double RATE_PREMIER = 25.0;

// ─── Clé API Google (même clé que google_maps_flutter) ────────────────────────
const String _kApiKey = 'AIzaSyALKHw2yxrsMaMwquheHpvaqWlj6G5zWX4';

class MyGeo extends StatefulWidget {
  const MyGeo({super.key});
  @override
  State<MyGeo> createState() => _MyGeoState();
}

class _MyGeoState extends State<MyGeo> {
  // ── Carte ──────────────────────────────────────────────────────────────────
  final Completer<GoogleMapController> _ctrl = Completer();
  GoogleMapController? _gmc;
  final Dio _dio = Dio();

  CameraPosition _initialCamera = const CameraPosition(
    target: LatLng(18.0718016, -15.9557083),
    zoom: 13,
  );

  // ── Positions ──────────────────────────────────────────────────────────────
  LatLng? _currentPosition;
  LatLng? _depart;
  LatLng? _destination;

  // ── Markers & Polylines ────────────────────────────────────────────────────
  final Set<Marker>   _markers   = {};
  final Set<Polyline> _polylines = {};

  // ── Champs texte ───────────────────────────────────────────────────────────
  final TextEditingController _departCtrl = TextEditingController();
  final TextEditingController _destCtrl   = TextEditingController();
  final FocusNode _departFocus = FocusNode();
  final FocusNode _destFocus   = FocusNode();

  // ── Suggestions ────────────────────────────────────────────────────────────
  List<Map<String, String>> _departSuggestions = [];
  List<Map<String, String>> _destSuggestions   = [];
  bool _showDepartSugg = false;
  bool _showDestSugg   = false;
  Timer? _debounce;

  // ── État ───────────────────────────────────────────────────────────────────
  double? _distanceKm;
  String  _selectedClass  = 'classic';
  bool    _showPricing    = false;
  bool    _loadingLocation = true;
  bool    _loadingSearch   = false;

  // ───────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _departCtrl.dispose();
    _destCtrl.dispose();
    _departFocus.dispose();
    _destFocus.dispose();
    _debounce?.cancel();
    _dio.close();
    super.dispose();
  }

  // ── 1. GPS position actuelle ───────────────────────────────────────────────
  Future<void> _getCurrentLocation() async {
    try {
      bool ok = await Geolocator.isLocationServiceEnabled();
      if (!ok) {
        _showErr('Service GPS désactivé');
        setState(() => _loadingLocation = false);
        return;
      }

      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        _showErr('Permission GPS refusée');
        setState(() => _loadingLocation = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = LatLng(pos.latitude, pos.longitude);
      _depart = _currentPosition;

      // Reverse geocoding via Google API → adresse lisible
      final address = await _reverseGeocode(_currentPosition!);
      _departCtrl.text = address ?? 'Ma position actuelle';

      _addDepartMarker(_currentPosition!);
      _initialCamera = CameraPosition(target: _currentPosition!, zoom: 14);

      setState(() => _loadingLocation = false);
      _gmc?.animateCamera(
        CameraUpdate.newCameraPosition(_initialCamera),
      );
    } catch (e) {
      _showErr('Erreur GPS');
      setState(() => _loadingLocation = false);
    }
  }

  // ── 2. Reverse geocoding ───────────────────────────────────────────────────
  Future<String?> _reverseGeocode(LatLng pos) async {
    try {
      final res = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '${pos.latitude},${pos.longitude}',
          'key': _kApiKey,
          'language': 'fr',
        },
      );
      final results = res.data['results'] as List;
      if (results.isNotEmpty) {
        return results.first['formatted_address'] as String;
      }
    } catch (_) {}
    return null;
  }

  // ── 3. Autocomplete Places API (Mauritanie uniquement) ────────────────────
  void _onSearchChanged(String query, bool isDepart) {
    _debounce?.cancel();

    if (query.length < 2) {
      setState(() {
        if (isDepart) { _departSuggestions = []; _showDepartSugg = false; }
        else          { _destSuggestions   = []; _showDestSugg   = false; }
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        setState(() => _loadingSearch = true);

        final res = await _dio.get(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json',
          queryParameters: {
            'input'      : query,
            'key'        : _kApiKey,
            'components' : 'country:mr',   // ✅ Mauritanie uniquement
            'language'   : 'fr',
            'types'      : 'geocode',
          },
        );

        final predictions = res.data['predictions'] as List;
        final suggestions = predictions.map((p) => {
          'description': p['description'] as String,
          'place_id'   : p['place_id']    as String,
        }).toList();

        setState(() {
          _loadingSearch = false;
          if (isDepart) {
            _departSuggestions = suggestions;
            _showDepartSugg    = suggestions.isNotEmpty;
          } else {
            _destSuggestions = suggestions;
            _showDestSugg    = suggestions.isNotEmpty;
          }
        });
      } catch (_) {
        setState(() => _loadingSearch = false);
      }
    });
  }

  // ── 4. Sélection suggestion → coordonnées via place_id ────────────────────
  Future<void> _selectSuggestion(Map<String, String> suggestion, bool isDepart) async {
    try {
      FocusScope.of(context).unfocus();
      setState(() => _loadingSearch = true);

      // Place Details pour obtenir lat/lng précis
      final res = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': suggestion['place_id'],
          'key'     : _kApiKey,
          'fields'  : 'geometry,formatted_address',
          'language': 'fr',
        },
      );

      final loc = res.data['result']['geometry']['location'];
      final latlng  = LatLng(loc['lat'], loc['lng']);
      final address = res.data['result']['formatted_address'] as String;

      setState(() {
        _loadingSearch = false;
        if (isDepart) {
          _depart = latlng;
          _departCtrl.text   = address;
          _departSuggestions = [];
          _showDepartSugg    = false;
        } else {
          _destination = latlng;
          _destCtrl.text   = address;
          _destSuggestions = [];
          _showDestSugg    = false;
        }
      });

      if (isDepart) {
        _addDepartMarker(latlng);
      } else {
        _addDestinationMarker(latlng);
      }

      _gmc?.animateCamera(CameraUpdate.newLatLngZoom(latlng, 15));
      _drawPolyline();
      if (_depart != null && _destination != null) _calculateDistance();

    } catch (e) {
      setState(() => _loadingSearch = false);
      _showErr('Adresse introuvable');
    }
  }

  // ── 5. Markers draggables ──────────────────────────────────────────────────
  void _addDepartMarker(LatLng pos) {
    _markers.removeWhere((m) => m.markerId == const MarkerId('depart'));
    _markers.add(Marker(
      markerId: const MarkerId('depart'),
      position: pos,
      draggable: true,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(title: '🔵 Départ'),
      onDragEnd: (newPos) async {
        _depart = newPos;
        final address = await _reverseGeocode(newPos);
        setState(() {
          _departCtrl.text = address ?? '${newPos.latitude.toStringAsFixed(4)}, ${newPos.longitude.toStringAsFixed(4)}';
        });
        _drawPolyline();
        if (_destination != null) _calculateDistance();
      },
    ));
    setState(() {});
  }

  void _addDestinationMarker(LatLng pos) {
    _markers.removeWhere((m) => m.markerId == const MarkerId('destination'));
    _markers.add(Marker(
      markerId: const MarkerId('destination'),
      position: pos,
      draggable: true,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: '🔴 Destination'),
      onDragEnd: (newPos) async {
        _destination = newPos;
        final address = await _reverseGeocode(newPos);
        setState(() {
          _destCtrl.text = address ?? '${newPos.latitude.toStringAsFixed(4)}, ${newPos.longitude.toStringAsFixed(4)}';
        });
        _drawPolyline();
        _calculateDistance();
      },
    ));
    setState(() {});
  }

  // ── 6. Tap carte ───────────────────────────────────────────────────────────
  void _onMapTap(LatLng pos) async {
    setState(() { _showDepartSugg = false; _showDestSugg = false; });
    FocusScope.of(context).unfocus();

    final address = await _reverseGeocode(pos);
    final label = address ?? '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';

    if (_depart == null) {
      _depart = pos;
      _departCtrl.text = label;
      _addDepartMarker(pos);
    } else if (_destination == null) {
      _destination = pos;
      _destCtrl.text = label;
      _addDestinationMarker(pos);
      _drawPolyline();
      _calculateDistance();
    }
    setState(() {});
  }

  // ── 7. Polyline ────────────────────────────────────────────────────────────
  void _drawPolyline() {
    if (_depart == null || _destination == null) return;
    _polylines.clear();
    _polylines.add(Polyline(
      polylineId: const PolylineId('route'),
      points  : [_depart!, _destination!],
      color   : Colors.indigo,
      width   : 4,
      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
    ));
    setState(() {});
  }

  // ── 8. Distance & prix ─────────────────────────────────────────────────────
  void _calculateDistance() {
    if (_depart == null || _destination == null) return;
    final dist = Geolocator.distanceBetween(
      _depart!.latitude, _depart!.longitude,
      _destination!.latitude, _destination!.longitude,
    );
    setState(() { _distanceKm = dist / 1000; _showPricing = true; });
    _fitBounds();
  }

  double _getPrice(String type) {
    if (_distanceKm == null) return 0;
    final base = type == 'classic' ? BASE_CLASSIC : BASE_PREMIER;
    final rate = type == 'classic' ? RATE_CLASSIC : RATE_PREMIER;
    final total = base + (_distanceKm! * rate);
    return total < base ? base : total;
  }

  void _fitBounds() {
    if (_depart == null || _destination == null || _gmc == null) return;
    final minLat = _depart!.latitude  < _destination!.latitude  ? _depart!.latitude  : _destination!.latitude;
    final maxLat = _depart!.latitude  > _destination!.latitude  ? _depart!.latitude  : _destination!.latitude;
    final minLng = _depart!.longitude < _destination!.longitude ? _depart!.longitude : _destination!.longitude;
    final maxLng = _depart!.longitude > _destination!.longitude ? _depart!.longitude : _destination!.longitude;
    _gmc!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat - 0.005, minLng - 0.005),
        northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
      ), 100,
    ));
  }

  // ── Reset ──────────────────────────────────────────────────────────────────
  void _reset() {
    setState(() {
      _destination     = null;
      _distanceKm      = null;
      _showPricing     = false;
      _showDestSugg    = false;
      _destSuggestions = [];
      _polylines.clear();
      _destCtrl.clear();
      _markers.removeWhere((m) => m.markerId == const MarkerId('destination'));
    });
  }

  void _showErr(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade600),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade700,
        elevation: 0,
        title: const Text(
          'FASSTTOSSEL',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 20,
          ),
        ),
        actions: [
          if (_showPricing)
            IconButton(
              onPressed: _reset,
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Nouvelle course',
            ),
          IconButton(
            onPressed: () async => await FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [

          // ── Google Map ────────────────────────────────────────────────
          Positioned.fill(
            child: GoogleMap(
              mapType: MapType.normal,
              markers : _markers,
              polylines: _polylines,
              initialCameraPosition: _initialCamera,
              myLocationEnabled      : true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled    : false,
              onMapCreated: (c) {
                _ctrl.complete(c);
                _gmc = c;
                if (_currentPosition != null) {
                  c.animateCamera(CameraUpdate.newCameraPosition(
                    CameraPosition(target: _currentPosition!, zoom: 14)));
                }
              },
              onTap: _onMapTap,
            ),
          ),

          // ── Chargement GPS ────────────────────────────────────────────
          if (_loadingLocation)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 14),
                  Text('Localisation en cours...',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),

          // ── Champs Départ + Destination EN HAUT ───────────────────────
          Positioned(
            top: 12, left: 12, right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Départ ──────────────────────────────────────────────
                _buildSearchCard(
                  controller : _departCtrl,
                  focusNode  : _departFocus,
                  hint       : 'Départ',
                  icon       : Icons.radio_button_checked,
                  color      : Colors.blue.shade600,
                  isDepart   : true,
                  suggestions: _departSuggestions,
                  showSugg   : _showDepartSugg,
                ),
                // Connecteur visuel
                Padding(
                  padding: const EdgeInsets.only(left: 22),
                  child: Container(width: 2, height: 10, color: Colors.grey.shade400),
                ),
                // ── Destination ──────────────────────────────────────────
                _buildSearchCard(
                  controller : _destCtrl,
                  focusNode  : _destFocus,
                  hint       : 'Destination',
                  icon       : Icons.location_on,
                  color      : Colors.red.shade600,
                  isDepart   : false,
                  suggestions: _destSuggestions,
                  showSugg   : _showDestSugg,
                ),
              ],
            ),
          ),

          // ── Bouton centrer sur ma position ────────────────────────────
          Positioned(
            right : 12,
            bottom: _showPricing ? 380 : 100,
            child: FloatingActionButton.small(
              heroTag        : 'gps_btn',
              backgroundColor: Colors.white,
              onPressed: () {
                if (_currentPosition != null && _gmc != null) {
                  _gmc!.animateCamera(CameraUpdate.newLatLngZoom(
                    _currentPosition!, 15));
                }
              },
              child: Icon(Icons.my_location, color: Colors.indigo.shade700),
            ),
          ),

          // ── Panneau prix ──────────────────────────────────────────────
          if (_showPricing && _distanceKm != null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 44, height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                    ),

                    // Distance
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.route, color: Colors.indigo.shade700, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Distance : ${_distanceKm!.toStringAsFixed(2)} km',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.indigo.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),

                    // Cartes Classic / Premier
                    Row(children: [
                      Expanded(child: _buildClassCard(
                        'classic', Icons.two_wheeler,
                        'Classic', 'Confort standard',
                        Colors.blue.shade600,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _buildClassCard(
                        'premier', Icons.star,
                        'Premier', 'Confort premium',
                        Colors.amber.shade700,
                      )),
                    ]),
                    const SizedBox(height: 14),

                    // Bouton Commander
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: () {
                          final price = _getPrice(_selectedClass).toStringAsFixed(0);
                          final cls   = _selectedClass == 'classic' ? 'Classic' : 'Premier';
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('✅ Course $cls commandée — $price MRU'),
                            backgroundColor: Colors.green.shade600,
                            duration: const Duration(seconds: 3),
                          ));
                        },
                        icon : const Icon(Icons.check_circle, size: 22),
                        label: Text(
                          'Commander — ${_getPrice(_selectedClass).toStringAsFixed(0)} MRU',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Widget champ recherche ──────────────────────────────────────────────────
  Widget _buildSearchCard({
    required TextEditingController        controller,
    required FocusNode                    focusNode,
    required String                       hint,
    required IconData                     icon,
    required Color                        color,
    required bool                         isDepart,
    required List<Map<String, String>>    suggestions,
    required bool                         showSugg,
  }) {
    return Column(
      children: [
        // Champ
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(icon, color: color, size: 20),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode : focusNode,
                  decoration: InputDecoration(
                    hintText        : hint,
                    hintStyle       : TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    border          : InputBorder.none,
                    isDense         : true,
                    contentPadding  : const EdgeInsets.symmetric(vertical: 14),
                  ),
                  style    : const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  onChanged: (v) => _onSearchChanged(v, isDepart),
                ),
              ),
              // Bouton position actuelle (départ uniquement)
              if (isDepart)
                IconButton(
                  onPressed: () async {
                    if (_currentPosition == null) return;
                    _depart = _currentPosition;
                    final address = await _reverseGeocode(_currentPosition!);
                    setState(() {
                      _departCtrl.text   = address ?? 'Ma position actuelle';
                      _showDepartSugg    = false;
                      _departSuggestions = [];
                    });
                    _addDepartMarker(_currentPosition!);
                    _gmc?.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 15));
                    if (_destination != null) _calculateDistance();
                  },
                  icon   : Icon(Icons.my_location, color: Colors.indigo.shade400, size: 18),
                  tooltip: 'Ma position',
                ),
              // Spinner
              if (_loadingSearch)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.indigo.shade300)),
                )
              // Bouton effacer
              else if (controller.text.isNotEmpty)
                IconButton(
                  onPressed: () {
                    controller.clear();
                    setState(() {
                      if (isDepart) { _departSuggestions = []; _showDepartSugg = false; }
                      else          { _destSuggestions   = []; _showDestSugg   = false; }
                    });
                  },
                  icon: Icon(Icons.close, color: Colors.grey.shade400, size: 18),
                ),
            ],
          ),
        ),

        // Liste suggestions
        if (showSugg && suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: suggestions.asMap().entries.map((entry) {
                  final i   = entry.key;
                  final sug = entry.value;
                  return InkWell(
                    onTap: () => _selectSuggestion(sug, isDepart),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        border: i != suggestions.length - 1
                          ? Border(bottom: BorderSide(color: Colors.grey.shade100))
                          : null,
                      ),
                      child: Row(children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: (isDepart ? Colors.blue : Colors.red).shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: isDepart ? Colors.blue.shade400 : Colors.red.shade400,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            sug['description'] ?? '',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  // ── Widget carte de classe ──────────────────────────────────────────────────
  Widget _buildClassCard(String type, IconData icon, String label,
      String desc, Color color) {
    final bool sel = _selectedClass == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedClass = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: sel ? color : Colors.grey.shade200,
            width: sel ? 2 : 1,
          ),
        ),
        child: Column(children: [
          Icon(icon, color: sel ? color : Colors.grey.shade400, size: 28),
          const SizedBox(height: 6),
          Text(label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: sel ? color : Colors.grey.shade700,
              fontSize: 14)),
          Text(desc,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text(
            '${_getPrice(type).toStringAsFixed(0)} MRU',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: sel ? color : Colors.grey.shade700,
              fontSize: 18)),
          Text(
            '${type == 'classic' ? RATE_CLASSIC.toInt() : RATE_PREMIER.toInt()} MRU/km',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ]),
      ),
    );
  }
}
