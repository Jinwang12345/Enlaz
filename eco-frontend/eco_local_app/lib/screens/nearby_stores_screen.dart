import 'dart:ui';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/shop.dart';
import '../services/shop_service.dart';

class NearbyStoresScreen extends StatefulWidget {
  const NearbyStoresScreen({super.key});

  @override
  State<NearbyStoresScreen> createState() => _NearbyStoresScreenState();
}

class _NearbyStoresScreenState extends State<NearbyStoresScreen> {
  final MapController _mapController = MapController();
  final PageController _pageController = PageController(viewportFraction: 0.85);
  final ShopService _shopService = ShopService();

  List<Shop> _shops = [];
  List<Shop> _filteredShops = [];
  final TextEditingController _searchController = TextEditingController();
  LatLng _currentLocation = const LatLng(41.3851, 2.1734); // Barcelona default
  LatLng? _lastSearchLocation;
  LatLng? _pendingSearchLocation;
  LatLng? _pegmanPosition; // Visually tracks where the Pegman has been placed on the map
  double _searchRadius = 100.0; // Dynamic search radius selected by the user
  bool _showSearchHereButton = false;
  bool _isLoading = true;
  int _currentIndex = 0;

  final Color _primaryColor = const Color(0xFFEC5B13);

  // Getter to calculate the Top 10 closest shops to the current search location
  List<Shop> get _top10Shops {
    final referenceLoc = _lastSearchLocation ?? _currentLocation;
    final List<Shop> sortedList = List<Shop>.from(_filteredShops);
    sortedList.sort((a, b) {
      final distA = Geolocator.distanceBetween(
        referenceLoc.latitude,
        referenceLoc.longitude,
        a.latitude,
        a.longitude,
      );
      final distB = Geolocator.distanceBetween(
        referenceLoc.latitude,
        referenceLoc.longitude,
        b.latitude,
        b.longitude,
      );
      return distA.compareTo(distB);
    });
    return sortedList.take(10).toList();
  }

  @override
  void initState() {
    super.initState();
    _initLocationAndShops();
  }

  Future<void> _initLocationAndShops() async {
    try {
      Position position = await _determinePosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    } finally {
      _loadShops(center: _currentLocation);
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Location permissions are denied');
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _loadShops({required LatLng center}) async {
    setState(() {
      _isLoading = true;
      _showSearchHereButton = false;
      _lastSearchLocation = center;
    });

    // We pass a limit of 40 (or 50) as requested by the user, using the dynamic search radius
    final shops = await _shopService.getNearbyShops(
      center.latitude,
      center.longitude,
      radius: _searchRadius,
      limit: 40,
    );
    print('Loaded ${shops.length} shops from backend');
    
    setState(() {
      _shops = shops;
      _filteredShops = shops;
      _isLoading = false;
      _currentIndex = 0;
    });
    
    // Keep the map centered exactly on the requested coordinate to avoid unexpected jumping
    double currentZoom = 15.0;
    try {
      currentZoom = _mapController.camera.zoom;
    } catch (_) {
      // Fallback if map is not fully mounted yet
    }
    _mapController.move(center, currentZoom);

    // Dynamic reset for PageView controller
    if (_filteredShops.isNotEmpty && _pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  void _onMapMoved(LatLng center) {
    // No-op: Removed "Buscar aquí" button trigger on map drag/zoom.
  }

  void _onMapTapped(LatLng point) {
    // No-op: Removed "Buscar aquí" popup on general map click/tap.
  }

  void _onMarkerTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    double currentZoom = 15.0;
    try {
      currentZoom = _mapController.camera.zoom;
    } catch (_) {}
    _mapController.move(
      LatLng(_filteredShops[index].latitude, _filteredShops[index].longitude),
      currentZoom,
    );
  }

  void _onSearchChanged(String query) {
    print('Searching for: $query');
    setState(() {
      if (query.isEmpty) {
        _filteredShops = _shops;
      } else {
        _filteredShops = _shops
            .where((shop) =>
                shop.name.toLowerCase().contains(query.toLowerCase()) ||
                shop.activity.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      print('Matches found: ${_filteredShops.length}');
    });
  }

  void _showShopDetails(Shop shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildShopDetailSheet(shop),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: _buildRightDrawer(),
      body: Stack(
        children: [
          // 1. Mapa
          DragTarget<bool>(
            onWillAccept: (data) => data == true,
            onAcceptWithDetails: (details) {
              final RenderBox renderBox = context.findRenderObject() as RenderBox;
              final localOffset = renderBox.globalToLocal(details.offset);
              final latLng = _mapController.camera.pointToLatLng(
                Point(localOffset.dx, localOffset.dy),
              );
              setState(() {
                _pegmanPosition = latLng;
              });
              _loadShops(center: latLng);
            },
            builder: (context, candidateData, rejectedData) {
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation,
                  initialZoom: 14.0,
                  onTap: (tapPosition, point) {
                    FocusScope.of(context).unfocus();
                    _onMapTapped(point);
                  },
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture && position.center != null) {
                      _onMapMoved(position.center!);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.tfg.eco_local_app',
                  ),
                  if (_pegmanPosition != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _pegmanPosition!,
                          radius: _searchRadius,
                          useRadiusInMeter: true,
                          color: Colors.amber.withOpacity(0.12),
                          borderColor: Colors.amber.withOpacity(0.4),
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      ..._filteredShops.asMap().entries.map((entry) {
                        int idx = entry.key;
                        Shop shop = entry.value;
                        return Marker(
                          point: LatLng(shop.latitude, shop.longitude),
                          width: 45,
                          height: 45,
                          child: GestureDetector(
                            onTap: () {
                              _onMarkerTapped(idx);
                              _showShopDetails(shop);
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 45,
                                  color: shop.isCommercialAxis ? _primaryColor : Colors.blueGrey,
                                ),
                                Positioned(
                                  top: 5,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      if (_pegmanPosition != null)
                        Marker(
                          point: _pegmanPosition!,
                          width: 50,
                          height: 50,
                          child: Draggable<bool>(
                            data: true,
                            feedback: Material(
                              color: Colors.transparent,
                              child: Icon(
                                Icons.accessibility_new_rounded,
                                color: Colors.amber[800],
                                size: 48,
                              ),
                            ),
                            childWhenDragging: const Opacity(
                              opacity: 0.3,
                              child: Icon(
                                Icons.accessibility_new_rounded,
                                color: Colors.amber,
                                size: 28,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.amber, width: 2),
                                  ),
                                ),
                                Icon(
                                  Icons.accessibility_new_rounded,
                                  color: Colors.amber[800],
                                  size: 36,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),

          // 2. Header: Buscador Glassmorphism
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.black54),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: const InputDecoration(
                              hintText: 'Buscar comercios...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        // Pegman Draggable (Monigote Humanoide) next to My Location
                        Draggable<bool>(
                          data: true,
                          feedback: Material(
                            color: Colors.transparent,
                            child: Icon(
                              Icons.accessibility_new_rounded,
                              color: Colors.amber[800],
                              size: 48,
                            ),
                          ),
                          childWhenDragging: const Opacity(
                            opacity: 0.4,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                  Icons.accessibility_new_rounded,
                                  color: Colors.amber,
                                  size: 28,
                                ),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Tooltip(
                              message: "Arrastra este monigote al mapa para buscar en esa zona",
                              child: Icon(
                                Icons.accessibility_new_rounded,
                                color: Colors.amber,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.my_location, color: _primaryColor),
                          onPressed: _initLocationAndShops,
                        ),
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.format_list_bulleted_rounded, color: Colors.black87),
                            onPressed: () => Scaffold.of(context).openEndDrawer(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Panel de Control de Radio Dinámico (Glassmorphism Pill)
          Positioned(
            top: 90,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  width: 210,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Radio de Búsqueda',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_searchRadius.toStringAsFixed(0)}m',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          activeTrackColor: _primaryColor,
                          inactiveTrackColor: Colors.grey[300],
                          thumbColor: _primaryColor,
                          overlayColor: _primaryColor.withOpacity(0.2),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        ),
                        child: Slider(
                          value: _searchRadius,
                          min: 50,
                          max: 1500,
                          divisions: 29, // 50m steps (50 to 1500)
                          onChanged: (value) {
                            setState(() {
                              _searchRadius = value;
                            });
                          },
                          onChangeEnd: (value) {
                            if (_pegmanPosition != null) {
                              _loadShops(center: _pegmanPosition!);
                            } else if (_lastSearchLocation != null) {
                              _loadShops(center: _lastSearchLocation!);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_filteredShops.isNotEmpty)
            Positioned(
              bottom: 200,
              left: 24,
              child: Text(
                'Sugerencias cerca de ti',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black.withOpacity(0.8),
                  shadows: [
                    Shadow(color: Colors.white, blurRadius: 4, offset: Offset(0, 2))
                  ]
                ),
              ),
            ),
          if (_filteredShops.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              height: 180,
              child: ScrollConfiguration(
                behavior: WebMouseScrollBehavior(),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _filteredShops.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final shop = _filteredShops[index];
                    return GestureDetector(
                      onTap: () => _showShopDetails(shop),
                      child: _buildShopCard(shop)
                    );
                  },
                ),
              ),
            ),
            
          if (_isLoading)
            Positioned.fill(
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    color: Colors.black.withOpacity(0.25),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Buscando comercios eco...',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (!_isLoading && _filteredShops.isEmpty && _searchController.text.isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'No se encontraron comercios',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildShopDetailSheet(Shop shop) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          // Drag handle
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.storefront, color: _primaryColor, size: 35),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            shop.activity,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.location_on_outlined, shop.address ?? 'Sin dirección'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.category_outlined, shop.category),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.map_outlined, shop.neighborhood),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.directions),
                        label: const Text('Cómo llegar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.share_outlined),
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShopCard(Shop shop) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icono / Imagen Placeholder
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.storefront, color: _primaryColor, size: 40),
            ),
            const SizedBox(width: 16),
            // Detalles
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    shop.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    shop.activity,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_city, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        shop.neighborhood,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (shop.isCommercialAxis)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Eix Comercial',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightDrawer() {
    final referenceLoc = _lastSearchLocation ?? _currentLocation;
    final topShops = _top10Shops;

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Top 10 Cercanos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: topShops.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay comercios',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: topShops.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final shop = topShops[index];
                        final distance = Geolocator.distanceBetween(
                          referenceLoc.latitude,
                          referenceLoc.longitude,
                          shop.latitude,
                          shop.longitude,
                        );
                        final distanceStr = distance < 1000
                            ? '${distance.toStringAsFixed(0)} m'
                            : '${(distance / 1000).toStringAsFixed(1)} km';

                        return InkWell(
                          onTap: () {
                            Navigator.pop(context); // Close drawer
                            final originalIndex = _filteredShops.indexOf(shop);
                            if (originalIndex != -1) {
                              setState(() {
                                _currentIndex = originalIndex;
                              });
                              // Center map immediately keeping current zoom
                              double currentZoom = 15.0;
                              try {
                                currentZoom = _mapController.camera.zoom;
                              } catch (_) {}
                              _mapController.move(LatLng(shop.latitude, shop.longitude), currentZoom);
                              // Animate PageView carousel
                              if (_pageController.hasClients) {
                                _pageController.animateToPage(
                                  originalIndex,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                              _showShopDetails(shop);
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.storefront, color: _primaryColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        shop.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        shop.activity,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Text(
                                    distanceStr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom ScrollBehavior to enable mouse-drag scrolling on Flutter Web
class WebMouseScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
