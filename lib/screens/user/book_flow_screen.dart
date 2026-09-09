import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/egypt_cities.dart';
import '../../providers/auth_provider.dart';
import '../../services/naql_api.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/models.dart';

class BookFlowScreen extends StatefulWidget {
  final VoidCallback onDone;
  const BookFlowScreen({super.key, required this.onDone});

  @override
  State<BookFlowScreen> createState() => _BookFlowScreenState();
}

class _BookFlowScreenState extends State<BookFlowScreen> {
  final _api = NaqlApi();
  final _pickupAddressController = TextEditingController();
  final _dropoffAddressController = TextEditingController();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  BookingStep _step = BookingStep.cargo;
  CargoType? _selectedCargo;
  VehicleTypeData? _selectedVehicle;
  EgyptCity? _pickupCity;
  EgyptCity? _dropoffCity;
  LatLng? _pickupPoint;
  LatLng? _dropoffPoint;
  bool _scheduleNow = true;
  DateTime? _scheduledTime;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _submitting = false;
  bool _vehicleAutoSelected = false;
  Future<List<VehicleTypeData>>? _vehiclesFuture;

  @override
  void initState() {
    super.initState();
    _vehiclesFuture = _api.vehicleTypes();
  }

  @override
  void dispose() {
    _pickupAddressController.dispose();
    _dropoffAddressController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  String _cityName(EgyptCity? c) {
    if (c == null) return '';
    final ar = S.of(context).isArabic;
    return ar ? c.nameAr : c.name;
  }

  String _addressLine(EgyptCity? city, TextEditingController ctrl) {
    final addr = ctrl.text.trim();
    if (city == null && addr.isEmpty) return '';
    if (city != null && addr.isEmpty) return _cityName(city);
    if (city == null) return addr;
    return '${_cityName(city)}, $addr';
  }

  EgyptCity? _nearestCity(LatLng point) {
    EgyptCity? nearest;
    var best = double.infinity;
    for (final c in egyptCities) {
      final dLat = (point.latitude - c.lat).abs();
      final dLng = (point.longitude - c.lng).abs();
      final dist = dLat + dLng;
      if (dist < best && dist < 0.5) {
        best = dist;
        nearest = c;
      }
    }
    return nearest;
  }

  void _nextStep() {
    if (_step == BookingStep.confirm) {
      _submit();
      return;
    }
    setState(() {
      _step = BookingStep.values[_step.index + 1];
    });
  }

  void _prevStep() {
    if (_step == BookingStep.cargo) return;
    setState(() {
      _step = BookingStep.values[_step.index - 1];
    });
  }

  bool get _canProceed {
    switch (_step) {
      case BookingStep.cargo:
        return _selectedCargo != null;
      case BookingStep.vehicle:
        return _selectedVehicle != null;
      case BookingStep.locations:
        return _pickupCity != null &&
            _pickupAddressController.text.trim().isNotEmpty &&
            _dropoffCity != null &&
            _dropoffAddressController.text.trim().isNotEmpty;
      case BookingStep.schedule:
      case BookingStep.payment:
      case BookingStep.confirm:
        return true;
      case BookingStep.budget:
        final min = double.tryParse(_minController.text);
        final max = double.tryParse(_maxController.text);
        return min != null && max != null && min <= max;
    }
  }

  Future<void> _submit() async {
    final s = S.of(context);
    final token = context.read<AuthProvider>().token;
    final min = double.tryParse(_minController.text);
    final max = double.tryParse(_maxController.text);

    if (token == null ||
        _selectedVehicle == null ||
        _pickupCity == null ||
        _dropoffCity == null ||
        min == null ||
        max == null ||
        min > max) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.completeFields)),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _api.createJob(
        token,
        truckId: _selectedVehicle!.id,
        pickup: _addressLine(_pickupCity, _pickupAddressController),
        dropoff: _addressLine(_dropoffCity, _dropoffAddressController),
        pickupLat: _pickupPoint?.latitude ?? 0.0,
        pickupLng: _pickupPoint?.longitude ?? 0.0,
        dropoffLat: _dropoffPoint?.latitude ?? 0.0,
        dropoffLng: _dropoffPoint?.longitude ?? 0.0,
        min: min,
        max: max,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.requestSubmitted)),
        );
        widget.onDone();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickLocation(bool pickup) async {
    final result = await showDialog<LatLng>(
      context: context,
      builder: (_) => const _MapPicker(),
    );
    if (result != null) {
      final nearest = _nearestCity(result);
      setState(() {
        if (pickup) {
          _pickupPoint = result;
          _pickupCity = nearest ?? _pickupCity;
          _pickupAddressController.text =
              '${result.latitude.toStringAsFixed(5)}, ${result.longitude.toStringAsFixed(5)}';
        } else {
          _dropoffPoint = result;
          _dropoffCity = nearest ?? _dropoffCity;
          _dropoffAddressController.text =
              '${result.latitude.toStringAsFixed(5)}, ${result.longitude.toStringAsFixed(5)}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final user = context.watch<AuthProvider>().user;
    if (user != null && !user.isVerified) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            s.t(
              'Verify your email or phone before submitting a truck request.',
              'توثيق بريدك أو هاتفك قبل إرسال طلب العربة.',
            ),
            textAlign: TextAlign.center,
            style: interStyle(size: 16, color: kUserMuted),
          ),
        ),
      );
    }

    return FutureBuilder<List<VehicleTypeData>>(
      future: _vehiclesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: PrimaryButton(
              label: s.retry,
              onPressed: () =>
                  setState(() => _vehiclesFuture = _api.vehicleTypes()),
            ),
          );
        }

        final vehicles = snapshot.data ?? [];
        if (vehicles.isEmpty) {
          return Center(
            child: Text('No vehicles are available right now.',
                style: interStyle(size: 16, color: kUserMuted)),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressBar(s),
            const SizedBox(height: 20),
            Expanded(child: _buildStepContent(vehicles)),
            _buildNavigationButtons(s),
          ],
        );
      },
    );
  }

  Widget _buildProgressBar(S s) {
    return Row(
      children: List.generate(BookingStep.values.length, (i) {
        final step = BookingStep.values[i];
        final done = _step.index > i;
        final current = _step == step;
        return Expanded(
          child: Row(
            children: [
              Expanded(child: StepDot(done: done, current: current)),
              if (i < BookingStep.values.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: done ? kRed : kUserBorder,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepContent(List<VehicleTypeData> vehicles) {
    switch (_step) {
      case BookingStep.cargo:
        return _buildCargoStep();
      case BookingStep.vehicle:
        return _buildVehicleStep(vehicles);
      case BookingStep.locations:
        return _buildLocationsStep();
      case BookingStep.schedule:
        return _buildScheduleStep();
      case BookingStep.budget:
        return _buildBudgetStep();
      case BookingStep.payment:
        return _buildPaymentStep();
      case BookingStep.confirm:
        return _buildConfirmStep();
    }
  }

  Widget _buildCargoStep() {
    final s = S.of(context);
    return _ScrollableStep(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.cargoStep,
              style: outfitStyle(size: 20, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(s.cargoStepHint,
              style: interStyle(size: 14, color: kUserMuted)),
          const SizedBox(height: 24),
          // Images / illustrations of the available truck sizes.
          const _TruckSizeGuide(),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kRedLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kRedBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: kRed, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.t(
                      'Choose what you are moving and we will suggest the best truck size.',
                      'اختر ماذا تقلّب وسنقترح عليك أفضل حجم عربة.',
                    ),
                    style: interStyle(size: 13, color: kUserTextSub),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(s.t('What are you moving?', 'ماذا تقلّب؟'),
              style: interStyle(size: 14, weight: FontWeight.w600)),
          const SizedBox(height: 12),
          _CargoOption(
            emoji: '🛋️',
            imageEmoji: '🚛',
            label: s.homeFurniture,
            sub: s.homeFurnitureSub,
            selected: _selectedCargo == CargoType.homeFurniture,
            onTap: () => setState(() => _selectedCargo = CargoType.homeFurniture),
          ),
          const SizedBox(height: 12),
          _CargoOption(
            emoji: '⚡',
            imageEmoji: '🚐',
            label: s.appliances,
            sub: s.appliancesSub,
            selected: _selectedCargo == CargoType.appliances,
            onTap: () => setState(() => _selectedCargo = CargoType.appliances),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleStep(List<VehicleTypeData> vehicles) {
    final s = S.of(context);
    final suggestedCode = _selectedCargo?.suggestedCode;

    // Auto-select the vehicle suggested by the chosen cargo type.
    if (!_vehicleAutoSelected &&
        suggestedCode != null &&
        _selectedVehicle == null) {
      _vehicleAutoSelected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final match = vehicles.firstWhere(
          (v) => v.code == suggestedCode,
          orElse: () => vehicles.first,
        );
        if (mounted) setState(() => _selectedVehicle = match);
      });
    }

    return _ScrollableStep(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.chooseVehicle,
              style: outfitStyle(size: 20, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(s.selectVehicleHint,
              style: interStyle(size: 14, color: kUserMuted)),
          const SizedBox(height: 16),
          // Visual guide of truck sizes (images).
          const _TruckSizeGuide(),
          const SizedBox(height: 16),
          if (suggestedCode != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${s.recommended} • ${_cargoSuggestionText(s)}',
                style: interStyle(size: 13, color: kRed, weight: FontWeight.w600),
              ),
            ),
          ...vehicles.map((option) {
            final isSuggested = option.code == suggestedCode;
            final isSelected = _selectedVehicle?.id == option.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedVehicle = option),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSuggested ? kRedLight : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? kRed
                        : isSuggested
                            ? kRed
                            : kUserBorder,
                    width: isSelected || isSuggested ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Text(option.emoji,
                        style: const TextStyle(fontSize: 34)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(option.label,
                              style: outfitStyle(
                                  size: 16, weight: FontWeight.w600)),
                          Text(option.description,
                              style:
                                  interStyle(size: 13, color: kUserMuted)),
                          Text('${option.capacity} · ${option.priceRange} EGP',
                              style: interStyle(
                                  size: 12, color: kUserTextSub)),
                        ],
                      ),
                    ),
                    if (isSuggested)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(s.recommended,
                            style: outfitStyle(
                                size: 11,
                                weight: FontWeight.w700,
                                color: kRed)),
                      ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: kRed, size: 24),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _cargoSuggestionText(S s) {
    return switch (_selectedCargo) {
      CargoType.homeFurniture => s.t('Large truck for furniture', 'عربة كبيرة للأثاث'),
      CargoType.appliances => s.t('Medium van for appliances', 'شاحنة متوسطة للأجهزة'),
      null => '',
    };
  }

  Widget _buildLocationsStep() {
    final s = S.of(context);
    return _ScrollableStep(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.locationsStep,
              style: outfitStyle(size: 20, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(s.locationsHint,
              style: interStyle(size: 14, color: kUserMuted)),
          const SizedBox(height: 20),
          _CityAddressField(
            label: s.pickup,
            city: _pickupCity,
            addressController: _pickupAddressController,
            onCityTap: (c) => setState(() => _pickupCity = c),
            onMapTap: () => _pickLocation(true),
          ),
          const SizedBox(height: 18),
          _CityAddressField(
            label: s.dropoff,
            city: _dropoffCity,
            addressController: _dropoffAddressController,
            onCityTap: (c) => setState(() => _dropoffCity = c),
            onMapTap: () => _pickLocation(false),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleStep() {
    final s = S.of(context);
    return _ScrollableStep(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.scheduleStep,
              style: outfitStyle(size: 20, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(s.scheduleHint,
              style: interStyle(size: 14, color: kUserMuted)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ScheduleOption(
                  emoji: '⚡',
                  label: s.bookNow,
                  sub: s.bookNowSub,
                  selected: _scheduleNow,
                  onTap: () => setState(() => _scheduleNow = true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScheduleOption(
                  emoji: '📅',
                  label: s.schedule,
                  sub: s.scheduleSub,
                  selected: !_scheduleNow,
                  onTap: () => setState(() => _scheduleNow = false),
                ),
              ),
            ],
          ),
          if (!_scheduleNow) ...[
            const SizedBox(height: 20),
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final date = await showDatePicker(
                  context: context,
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 30)),
                  initialDate: now.add(const Duration(days: 1)),
                );
                if (date != null && mounted) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      _scheduledTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kUserBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        color: _scheduledTime == null ? kUserMuted : kRed),
                    const SizedBox(width: 12),
                    Text(
                      _scheduledTime == null
                          ? s.t('Select date and time', 'اختر التاريخ والوقت')
                          : '${_scheduledTime!.year}/${_scheduledTime!.month}/${_scheduledTime!.day}',
                      style: interStyle(
                        size: 14,
                        color: _scheduledTime == null ? kUserMuted : kUserText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetStep() {
    final s = S.of(context);
    return _ScrollableStep(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.budgetStep,
              style: outfitStyle(size: 20, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(s.budgetHint,
              style: interStyle(size: 14, color: kUserMuted)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _budgetField(_minController, s.minEgp)),
              const SizedBox(width: 10),
              Expanded(child: _budgetField(_maxController, s.maxEgp)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['200', '500', '1,000', '1,500', '2,000'].map((val) {
              final isSelected = _maxController.text == val;
              return GestureDetector(
                onTap: () => setState(() => _maxController.text = val),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? kRedLight : kUserSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isSelected ? kRed : kUserBorder),
                  ),
                  child: Text(
                    '$val EGP',
                    style: interStyle(
                        size: 13, color: isSelected ? kRed : kUserText),
                  ),
                ),
              );
            }).toList(),
          ),
          ],
        ),
      );
    }

  Widget _budgetField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _buildPaymentStep() {
    final s = S.of(context);
    return _ScrollableStep(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.paymentStep,
              style: outfitStyle(size: 20, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(s.paymentHint,
              style: interStyle(size: 14, color: kUserMuted)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _PaymentOption(
                  emoji: '💵',
                  label: s.cash,
                  selected: _paymentMethod == PaymentMethod.cash,
                  onTap: () =>
                      setState(() => _paymentMethod = PaymentMethod.cash),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PaymentOption(
                  emoji: '💳',
                  label: s.visa,
                  selected: _paymentMethod == PaymentMethod.visa,
                  onTap: () =>
                      setState(() => _paymentMethod = PaymentMethod.visa),
                ),
              ),
            ],
          ),
          if (_paymentMethod == PaymentMethod.visa) ...[
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: s.cardNumber,
                hintText: '4242 4242 4242 4242',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(labelText: s.expiry),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(labelText: s.cvv),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            s.paymentNote,
            style: interStyle(size: 12, color: kUserMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmStep() {
    final s = S.of(context);
    final carLabel = _selectedVehicle?.label ?? s.unknown;
    final pickup = _addressLine(_pickupCity, _pickupAddressController);
    final dropoff = _addressLine(_dropoffCity, _dropoffAddressController);
    final min = _minController.text;
    final max = _maxController.text;
    final paymentLabel =
        _paymentMethod == PaymentMethod.cash ? s.cash : s.visa;
    final scheduleLabel = _scheduleNow
        ? s.now
        : (_scheduledTime != null
            ? '${_scheduledTime!.day}/${_scheduledTime!.month}/${_scheduledTime!.year}'
            : s.unknown);
    final cargoLabel = switch (_selectedCargo) {
          CargoType.homeFurniture => s.homeFurniture,
          CargoType.appliances => s.appliances,
          null => s.unknown,
        };

    return _ScrollableStep(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.confirmStep,
              style: outfitStyle(size: 20, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(s.confirmHint,
              style: interStyle(size: 14, color: kUserMuted)),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              children: [
                _confirmRow(s.cargoStep, cargoLabel),
                _confirmRow(s.vehicleLabel, carLabel),
                _confirmRow(s.pickup, pickup),
                _confirmRow(s.dropoff, dropoff),
                _confirmRow(s.scheduleLabel, scheduleLabel),
                _confirmRow(s.budgetLabel, '$min–$max EGP'),
                _confirmRow(s.paymentLabel, paymentLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: interStyle(size: 13, color: kUserMuted)),
          ),
          Expanded(
            child: Text(value,
                style: interStyle(size: 14, weight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  String _stepActionLabel(S s) {
    if (_step == BookingStep.confirm) return s.submitRequest;
    if (_step == BookingStep.cargo) return s.makeOrder;
    return s.next;
  }

  Widget _buildNavigationButtons(S s) {
    final isFirst = _step == BookingStep.cargo;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        children: [
          if (!isFirst)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(s.back,
                    style: outfitStyle(
                        size: 15, weight: FontWeight.w600)),
              ),
            ),
          if (!isFirst) const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceed && !_submitting ? _nextStep : null,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_stepActionLabel(s),
                      style: outfitStyle(
                          size: 15,
                          weight: FontWeight.w700,
                          color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scrollable wrapper so each step scrolls on small screens.
class _ScrollableStep extends StatelessWidget {
  final Widget child;
  const _ScrollableStep({required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: child,
      ),
    );
  }
}

class _TruckSizeGuide extends StatelessWidget {
  const _TruckSizeGuide();

  static const _sizes = <List<String>>[
    ['rb3-nq1.jpg', 'Small', 'صغير', 'Up to 500 kg', 'حتى 500 كجم'],
    ['3byh-nq2.jpg', 'Medium', 'متوسط', 'Up to 1.5 t', 'حتى 1.5 طن'],
    ['ns-nq.jpg', 'Large', 'كبير', 'Up to 5 t', 'حتى 5 طن'],
    ['nq3th.webp', 'X-Large', 'كبير جدا', 'Up to 10 t', 'حتى 10 طن'],
  ];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.truckSizeGuide,
            style: outfitStyle(size: 16, weight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _sizes.map((e) {
            return Container(
              width: 74,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 74,
                    height: 56,
                    decoration: BoxDecoration(
                      color: kUserSubtle,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kUserBorder),
                      image: DecorationImage(
                        image: AssetImage('truck-pic/${e[0]}'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(s.t(e[1], e[2]),
                      style: interStyle(size: 11, weight: FontWeight.w600)),
                  Text(s.t(e[3], e[4]),
                      style: interStyle(size: 10, color: kUserMuted)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CargoOption extends StatelessWidget {
  final String emoji;
  final String imageEmoji;
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  const _CargoOption({
    required this.emoji,
    required this.imageEmoji,
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? kRedLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? kRed : kUserBorder, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Text(imageEmoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          outfitStyle(size: 16, weight: FontWeight.w600)),
                  Text(sub,
                      style: interStyle(size: 13, color: kUserMuted)),
                ],
              ),
            ),
            Text(emoji, style: const TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}

class _CityAddressField extends StatelessWidget {
  final String label;
  final EgyptCity? city;
  final TextEditingController addressController;
  final void Function(EgyptCity) onCityTap;
  final VoidCallback onMapTap;

  const _CityAddressField({
    required this.label,
    required this.city,
    required this.addressController,
    required this.onCityTap,
    required this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: outfitStyle(size: 14, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        // City category selector
        InkWell(
          onTap: () async {
            final picked = await showDialog<EgyptCity>(
              context: context,
              builder: (_) => const _CityPickerDialog(),
            );
            if (picked != null) onCityTap(picked);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: kUserSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kUserBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.location_city,
                    color: city == null ? kUserMuted : kRed, size: 18),
                const SizedBox(width: 8),
                Expanded(
                   child: Text(
                     city == null ? s.selectCity : _cityName(context, city),
                    style: interStyle(
                      size: 14,
                      color: city == null ? kUserMuted : kUserText,
                      weight: city == null
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_left,
                    color: Color(0xFFD1D5DB), size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Full address text field
        TextField(
          controller: addressController,
          decoration: InputDecoration(
            labelText: s.fullAddress,
            hintText: s.fullAddressHint,
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onMapTap,
            icon: const Icon(Icons.map, size: 16),
            label: Text(s.pickOnMap,
                style: interStyle(size: 12, color: kRed)),
          ),
        ),
      ],
    );
  }

  String _cityName(BuildContext ctx, EgyptCity? c) {
    if (c == null) return '';
    final ar = S.of(ctx).isArabic;
    return ar ? c.nameAr : c.name;
  }
}

class _CityPickerDialog extends StatefulWidget {
  const _CityPickerDialog();

  @override
  State<_CityPickerDialog> createState() => _CityPickerDialogState();
}

class _CityPickerDialogState extends State<_CityPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final filtered = egyptCities.where((c) {
      final q = _query.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.nameAr.contains(q);
    }).toList();

    return AlertDialog(
      title: Text(s.pickCity,
          style: outfitStyle(size: 18, weight: FontWeight.w700)),
      content: SizedBox(
        width: double.maxFinite,
        height: 320,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: s.selectCityHint,
                prefixIcon: const Icon(Icons.search, size: 20),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(s.t('No city found', 'لا توجد مدينة'),
                          style: interStyle(size: 13, color: kUserMuted)),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        return ListTile(
                          leading: Icon(Icons.location_city,
                              color: kRed, size: 20),
                          title: Text(s.isArabic ? c.nameAr : c.name,
                              style: interStyle(
                                  size: 14, weight: FontWeight.w600)),
                          onTap: () => Navigator.pop(context, c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(s.cancelBtn)),
      ],
    );
  }
}

class _ScheduleOption extends StatelessWidget {
  final String emoji;
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  const _ScheduleOption({
    required this.emoji,
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? kRedLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? kRed : kUserBorder, width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(label,
                style: outfitStyle(size: 14, weight: FontWeight.w600)),
            Text(sub, style: interStyle(size: 12, color: kUserMuted)),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? kRedLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? kRed : kUserBorder, width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(label,
                style: outfitStyle(size: 14, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _MapPicker extends StatefulWidget {
  const _MapPicker();

  @override
  State<_MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<_MapPicker> {
  static const _cairo = LatLng(30.0444, 31.2357);
  LatLng? _point;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Text(s.pickOnMap),
      content: SizedBox(
        width: 600,
        height: 420,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: _cairo,
            initialZoom: 11,
            onTap: (tapPosition, point) => setState(() => _point = point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.naql.app',
            ),
            if (_point != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _point!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on,
                        color: Colors.red, size: 40),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancelBtn),
        ),
        ElevatedButton(
          onPressed:
              _point == null ? null : () => Navigator.pop(context, _point),
          child: Text(s.confirmCity),
        ),
      ],
    );
  }
}
