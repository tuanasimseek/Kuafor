import 'dart:async';
import 'package:flutter/material.dart';
import '../services/salon_service.dart';
import '../services/places_service.dart';
import '../widgets/app_widgets.dart';

class SalonInfoEditScreen extends StatefulWidget {
  final int salonId;
  final String currentName;
  final String currentAddress;
  final double? currentLat;
  final double? currentLng;

  const SalonInfoEditScreen({
    super.key,
    required this.salonId,
    required this.currentName,
    required this.currentAddress,
    this.currentLat,
    this.currentLng,
  });

  @override
  State<SalonInfoEditScreen> createState() => _SalonInfoEditScreenState();
}

class _SalonInfoEditScreenState extends State<SalonInfoEditScreen> {
  final SalonService _salonService = SalonService();
  final PlacesService _placesService = PlacesService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;     // Nominatim sonucu — kilitli
  late final TextEditingController _addressDetailCtrl; // No/Kat — serbest
  final FocusNode _addressFocus = FocusNode();

  double? _lat;
  double? _lng;
  bool _locationConfirmed = false;
  bool _addressLocked = false; // Nominatim'den seçildi mi?

  List<PlacePrediction> _suggestions = [];
  bool _loadingSuggestions = false;
  Timer? _debounce;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentName);
    _addressCtrl = TextEditingController(text: widget.currentAddress);
    _addressDetailCtrl = TextEditingController();
    _lat = widget.currentLat;
    _lng = widget.currentLng;
    if (_lat != null && _lng != null) {
      _locationConfirmed = true;
      _addressLocked = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _addressDetailCtrl.dispose();
    _addressFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onAddressChanged(String value) {
    // Kilit açılır, koordinatlar sıfırlanır
    if (_locationConfirmed || _addressLocked) {
      setState(() {
        _locationConfirmed = false;
        _addressLocked = false;
        _lat = null;
        _lng = null;
      });
    }
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _loadingSuggestions = true);
      final results = await _placesService.getSuggestions(trimmed);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _loadingSuggestions = false;
      });
    });
  }

  Future<void> _selectSuggestion(PlacePrediction prediction) async {
    _debounce?.cancel();
    _addressCtrl.text = prediction.description;
    setState(() {
      _suggestions = [];
      _locationConfirmed = false;
      _addressLocked = false;
      _lat = null;
      _lng = null;
      _loadingSuggestions = false;
    });
    _addressFocus.unfocus();

    if (prediction.latitude != null && prediction.longitude != null) {
      setState(() {
        _lat = prediction.latitude;
        _lng = prediction.longitude;
        _locationConfirmed = true;
        _addressLocked = true;
      });
    } else {
      setState(() => _loadingSuggestions = true);
      final detail = await _placesService.getDetail(prediction.placeId);
      if (!mounted) return;
      if (detail != null) {
        setState(() {
          _lat = detail.latitude;
          _lng = detail.longitude;
          _locationConfirmed = true;
          _addressLocked = true;
          _addressCtrl.text = detail.formattedAddress;
        });
      }
      setState(() => _loadingSuggestions = false);
    }
    // Adres seçilince detay alanına odaklan
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) FocusScope.of(context).nextFocus();
    });
  }

  void _clearAddress() {
    setState(() {
      _addressCtrl.clear();
      _addressDetailCtrl.clear();
      _addressLocked = false;
      _locationConfirmed = false;
      _lat = null;
      _lng = null;
      _suggestions = [];
    });
    _addressFocus.requestFocus();
  }

  String get _fullAddress {
    final base = _addressCtrl.text.trim();
    final detail = _addressDetailCtrl.text.trim();
    if (detail.isEmpty) return base;
    return '$base, $detail';
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final address = _fullAddress;
    if (name.isEmpty) { setState(() => _error = 'Salon adı boş olamaz.'); return; }
    if (address.isEmpty) { setState(() => _error = 'Adres boş olamaz.'); return; }
    setState(() { _saving = true; _error = null; });
    final result = await _salonService.updateSalon(
      salonId: widget.salonId,
      name: name,
      address: address,
      latitude: _lat,
      longitude: _lng,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salon bilgileri güncellendi.')),
      );
      Navigator.pop(context, {
        'name': name,
        'address': address,
        'latitude': _lat,
        'longitude': _lng,
      });
    } else {
      setState(() => _error = result.error ?? 'Güncelleme başarısız.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('Salon Bilgilerini Düzenle',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FieldLabel(text: 'Salon Adı'),
            const SizedBox(height: 6),
            AppTextField(
              controller: _nameCtrl,
              hint: 'Salon adı',
              prefix: const Icon(Icons.store_outlined, size: 18, color: AppColors.muted),
            ),
            const SizedBox(height: 18),

            const FieldLabel(text: 'Salon Adresi'),
            const SizedBox(height: 6),

            // Adres seçildiyse kilitli satır göster, değilse arama alanı
            if (_addressLocked)
              _LockedAddressRow(
                address: _addressCtrl.text,
                onClear: _clearAddress,
              )
            else ...[
              _AddressField(
                controller: _addressCtrl,
                focusNode: _addressFocus,
                onChanged: _onAddressChanged,
                isLoading: _loadingSuggestions,
              ),
              if (_suggestions.isNotEmpty)
                _SuggestionList(
                  suggestions: _suggestions,
                  onSelect: _selectSuggestion,
                ),
            ],

            // Adres seçildikten sonra detay alanı görünür
            if (_addressLocked) ...[
              const SizedBox(height: 10),
              AppTextField(
                controller: _addressDetailCtrl,
                hint: 'Daire No, Kat, Apartman adı... (isteğe bağlı)',
                prefix: const Icon(Icons.info_outline, size: 18, color: AppColors.muted),
              ),
            ],

            const SizedBox(height: 8),
            if (_locationConfirmed && _lat != null)
              Row(children: [
                const Icon(Icons.check_circle, size: 13, color: Colors.green),
                const SizedBox(width: 5),
                Text(
                  'Konum belirlendi — ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 11, color: Colors.green),
                ),
              ])
            else if (!_addressLocked)
              const Row(children: [
                Icon(Icons.info_outline, size: 13, color: AppColors.muted),
                SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Aşağıdan bir adres seçin — konum otomatik belirlenir.',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ),
              ]),

            const SizedBox(height: 28),
            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: 14),
            ],
            _saving
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : PrimaryButton(label: 'Kaydet', onTap: _save),
          ],
        ),
      ),
    );
  }
}

// Seçilmiş adres satırı — kilitli görünüm + değiştir butonu
class _LockedAddressRow extends StatelessWidget {
  final String address;
  final VoidCallback onClear;

  const _LockedAddressRow({required this.address, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.place, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              address,
              style: const TextStyle(fontSize: 13, color: AppColors.primary, height: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Değiştir',
                style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool isLoading;

  const _AddressField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: AppColors.primary),
      decoration: InputDecoration(
        hintText: 'Mahalle, sokak adı yazın...',
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
        suffixIcon: isLoading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                ),
              )
            : const Icon(Icons.search, color: AppColors.muted, size: 20),
        filled: true,
        fillColor: AppColors.surfaceSoft,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  final List<PlacePrediction> suggestions;
  final Future<void> Function(PlacePrediction) onSelect;

  const _SuggestionList({required this.suggestions, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
        itemBuilder: (_, i) {
          final s = suggestions[i];
          return InkWell(
            borderRadius: i == 0
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : i == suggestions.length - 1
                    ? const BorderRadius.vertical(bottom: Radius.circular(12))
                    : BorderRadius.zero,
            onTap: () => onSelect(s),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(children: [
                const Icon(Icons.place_outlined, size: 16, color: AppColors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(s.description,
                      style: const TextStyle(fontSize: 13, color: AppColors.primary, height: 1.3)),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}