import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/profile.dart';
import 'package:digital_wardrobe_app/features/profile/widgets/family_member_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Editing surface for a single wardrobe profile.
///
/// The form is split into three card sections — identity, sizing/measurements
/// and style preferences — that are all submitted together. It edits any
/// profile in the household: the account holder's own `self` row and every
/// relative. Measurements are always persisted in centimetres and kilograms;
/// the cm/ft and kg/lbs toggles only change how the value is displayed and
/// entered.
///
/// [profile] is the account's `profiles` row and should only be supplied when
/// [member] is the account holder. When present it enables the username field
/// and mirrors pronouns/gender back onto `profiles`, which the Profile header
/// still reads.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.member,
    this.profile,
  });

  final FamilyMember member;
  final Profile? profile;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

/// A selectable colour shade offered as a style preference.
class _ColorPreference {
  const _ColorPreference(this.name, this.color);

  final String name;
  final Color color;
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  static const String _lengthUnitCm = 'cm';
  static const String _lengthUnitFt = 'ft';
  static const String _weightUnitKg = 'kg';
  static const String _weightUnitLbs = 'lbs';

  static const double _cmPerInch = 2.54;
  static const double _inchesPerFoot = 12;
  static const double _lbsPerKg = 2.2046226218;

  static const List<String> _pronounOptions = <String>[
    'she/her',
    'he/him',
    'they/them',
    'Prefer not to say',
  ];

  static const List<String> _genderOptions = <String>[
    'Female',
    'Male',
    'Non-binary',
    'Prefer not to say',
  ];

  static const List<String> _shoeUnitOptions = <String>['EU', 'US', 'UK'];

  /// Child age sizes, ordered exactly as the outgrowth prediction engine ranks
  /// them in `size_growth_prediction_service.dart`.
  static const List<String> _childSizeOptions = <String>[
    '0-1M',
    '1-3M',
    '3-6M',
    '6-9M',
    '9-12M',
    '12-18M',
    '18-24M',
    '2-3Y',
    '3-4Y',
    '4-5Y',
    '5-6Y',
    '6-7Y',
    '7-8Y',
    '8-9Y',
    '9-10Y',
    '10-11Y',
    '11-12Y',
    '12-13Y',
    '13-14Y',
  ];

  static const List<String> _adultSizeOptions = <String>[
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
  ];

  static const List<String> _waistSizeOptions = <String>[
    '28',
    '30',
    '32',
    '34',
    '36',
  ];

  static List<String> get _topsSizeOptions => <String>[
    ..._childSizeOptions,
    ..._adultSizeOptions,
  ];

  static List<String> get _bottomsSizeOptions => <String>[
    ..._childSizeOptions,
    ..._waistSizeOptions,
  ];

  static const List<String> _styleAestheticOptions = <String>[
    'Casual',
    'Minimalist',
    'Streetwear',
    'Formal',
    'Traditional',
    'Sporty',
  ];

  static const List<_ColorPreference> _colorPreferenceOptions =
      <_ColorPreference>[
        _ColorPreference('Black', Color(0xFF000000)),
        _ColorPreference('White', Color(0xFFFFFFFF)),
        _ColorPreference('Gray', Color(0xFF808080)),
        _ColorPreference('Navy', Color(0xFF1F3A93)),
        _ColorPreference('Blue', Color(0xFF1E90FF)),
        _ColorPreference('Red', Color(0xFFD22B2B)),
        _ColorPreference('Pink', Color(0xFFFF8FB1)),
        _ColorPreference('Green', Color(0xFF2E7D32)),
        _ColorPreference('Beige', Color(0xFFD8C7A1)),
        _ColorPreference('Brown', Color(0xFF6D4C41)),
        _ColorPreference('Yellow', Color(0xFFF4C542)),
        _ColorPreference('Purple', Color(0xFF7B4397)),
      ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _shoeSizeController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  RelationshipType _relationship = RelationshipType.self;
  DateTime? _birthDate;
  String? _pronouns;
  String? _selectedGender;
  String? _avatarUrl;

  String _shoeUnit = 'EU';
  String? _topsSize;
  String? _bottomsSize;
  String _heightUnit = _lengthUnitCm;
  String _weightUnit = _weightUnitKg;

  final Set<String> _selectedAesthetics = <String>{};
  final Set<String> _selectedColors = <String>{};

  bool _isSaving = false;

  /// Whether this edit targets the account holder, which unlocks the username
  /// field and the mirrored `profiles` write.
  bool get _isAccount => widget.member.isAccount;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _shoeSizeController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();

    // The member is passed in directly by the caller, so the first frame is
    // always populated without a loading flash.
    _applyMember(widget.member);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _shoeSizeController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  /// Loads every editable field from [member] into the form state.
  ///
  /// The account's `profiles` row wins for the fields it still owns — name,
  /// username, pronouns and gender — so editing the Self member edits the
  /// account rather than orphaning it on the member row.
  void _applyMember(FamilyMember member) {
    final Profile? profile = _isAccount ? widget.profile : null;

    _nameController.text = profile?.fullName ?? member.name;
    _usernameController.text = profile?.username ?? '';
    _pronouns = profile?.pronouns ?? member.pronouns;
    _selectedGender = profile?.gender ?? member.gender;
    _avatarUrl = member.avatarUrl ?? profile?.avatarUrl;
    _relationship = member.relationship;
    _birthDate = member.birthDate;

    _shoeUnit = _shoeUnitOptions.contains(member.shoeUnit) ? member.shoeUnit : 'EU';
    _shoeSizeController.text = member.shoeSize ?? '';
    _topsSize = member.topsSize;
    _bottomsSize = member.bottomsSize;

    _heightController.text = _formatNumber(
      _cmToDisplay(member.heightCm, _heightUnit),
    );
    _weightController.text = _formatNumber(
      _kgToDisplay(member.weightKg, _weightUnit),
    );

    _selectedAesthetics
      ..clear()
      ..addAll(
        _styleAestheticOptions.where(member.styleAesthetics.contains),
      );
    _selectedColors
      ..clear()
      ..addAll(_colorPreferenceOptions
          .map((_ColorPreference option) => option.name)
          .where(member.colorPreferences.contains));
  }

  void _showImagePickerBottomSheet() {
    final ColorScheme colors = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Profile Photo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.camera_alt_outlined, color: colors.primary),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    // Camera upload logic goes here
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library_outlined, color: colors.primary),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    // Gallery picker logic goes here
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: colors.error),
                  title: Text(
                    'Remove Photo',
                    style: TextStyle(color: colors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Remove photo logic goes here
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Parses a user-entered measurement, returning `null` for blank input and
  /// rejecting negative or non-numeric values.
  static double? _parseOptionalNumber(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final double? parsed = double.tryParse(trimmed);
    if (parsed == null || parsed < 0) return null;

    return parsed;
  }

  static String _formatNumber(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) return value.toInt().toString();

    return value.toStringAsFixed(1);
  }

  /// Converts the canonical stored centimetres into the currently selected
  /// display unit.
  static double? _cmToDisplay(double? cm, String unit) {
    if (cm == null) return null;
    if (unit != _lengthUnitFt) return cm;

    return double.parse((cm / _cmPerInch / _inchesPerFoot).toStringAsFixed(1));
  }

  /// Converts a value typed in [unit] back to canonical centimetres.
  static double? _displayToCm(double? value, String unit) {
    if (value == null) return null;
    if (unit != _lengthUnitFt) return double.parse(value.toStringAsFixed(1));

    return double.parse(
      (value * _inchesPerFoot * _cmPerInch).toStringAsFixed(1),
    );
  }

  /// Converts the canonical stored kilograms into the currently selected
  /// display unit.
  static double? _kgToDisplay(double? kg, String unit) {
    if (kg == null) return null;
    if (unit != _weightUnitLbs) return kg;

    return double.parse((kg * _lbsPerKg).toStringAsFixed(1));
  }

  /// Converts a value typed in [unit] back to canonical kilograms.
  static double? _displayToKg(double? value, String unit) {
    if (value == null) return null;
    if (unit != _weightUnitLbs) return double.parse(value.toStringAsFixed(1));

    return double.parse((value / _lbsPerKg).toStringAsFixed(1));
  }

  void _changeHeightUnit(String? unit) {
    if (unit == null || unit == _heightUnit) return;

    final double? cm = _displayToCm(
      _parseOptionalNumber(_heightController.text),
      _heightUnit,
    );

    setState(() {
      _heightUnit = unit;
      _heightController.text = _formatNumber(_cmToDisplay(cm, unit));
    });
  }

  void _changeWeightUnit(String? unit) {
    if (unit == null || unit == _weightUnit) return;

    final double? kg = _displayToKg(
      _parseOptionalNumber(_weightController.text),
      _weightUnit,
    );

    setState(() {
      _weightUnit = unit;
      _weightController.text = _formatNumber(_kgToDisplay(kg, unit));
    });
  }

  void _toggleAesthetic(String aesthetic) {
    setState(() {
      if (!_selectedAesthetics.remove(aesthetic)) {
        _selectedAesthetics.add(aesthetic);
      }
    });
  }

  void _toggleColor(String colorName) {
    setState(() {
      if (!_selectedColors.remove(colorName)) {
        _selectedColors.add(colorName);
      }
    });
  }

  /// Opens the material date picker for the date of birth field. A child must
  /// have a birth date so the growth engine can project their sizes.
  Future<void> _pickBirthDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 10, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );

    if (picked == null || !mounted) return;

    setState(() => _birthDate = picked);
  }

  String get _birthDateLabel {
    final DateTime? date = _birthDate;
    if (date == null) return 'Not set';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// A unit-aware example value used in the numeric validation messages.
  String _example(String metric, String metricValue, String imperialValue) =>
      _isImperial(metric) ? imperialValue : metricValue;

  bool _isImperial(String metric) => metric == 'height'
      ? _heightUnit == _lengthUnitFt
      : _weightUnit == _weightUnitLbs;

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    if (_relationship == RelationshipType.child && _birthDate == null) {
      _showError('Add a date of birth for a child profile.');
      return;
    }

    final String name = _nameController.text.trim();
    final String username = _usernameController.text.trim();

    if (_isAccount && username.isEmpty) {
      _showError('Username is required for the account holder.');
      return;
    }

    final String shoeSize = _shoeSizeController.text.trim();
    if (shoeSize.isNotEmpty && double.tryParse(shoeSize) == null) {
      _showError('Enter a numeric shoe size, for example 38.');
      return;
    }

    final String rawHeight = _heightController.text.trim();
    final double? heightCm = _displayToCm(
      _parseOptionalNumber(rawHeight),
      _heightUnit,
    );
    if (heightCm == null && rawHeight.isNotEmpty) {
      _showError(
        'Enter a valid height, e.g. ${_example('height', '170', '5.7')}.',
      );
      return;
    }

    final String rawWeight = _weightController.text.trim();
    final double? weightKg = _displayToKg(
      _parseOptionalNumber(rawWeight),
      _weightUnit,
    );
    if (weightKg == null && rawWeight.isNotEmpty) {
      _showError(
        'Enter a valid weight, e.g. ${_example('weight', '68', '150')}.',
      );
      return;
    }

    setState(() => _isSaving = true);

    final String memberId = widget.member.id;

    try {
      await ref.read(familyRepositoryProvider).updateMemberProfileDetails(
        id: memberId,
        name: name,
        relationship: _relationship.name,
        birthDate: _birthDate,
        pronouns: _pronouns,
        gender: _selectedGender,
        heightCm: heightCm,
        weightKg: weightKg,
        shoeSize: shoeSize.isEmpty ? null : shoeSize,
        shoeUnit: _shoeUnit,
        topsSize: _topsSize,
        bottomsSize: _bottomsSize,
        styleAesthetics: _styleAestheticOptions
            .where(_selectedAesthetics.contains)
            .toList(growable: false),
        colorPreferences: _colorPreferenceOptions
            .map((_ColorPreference option) => option.name)
            .where(_selectedColors.contains)
            .toList(growable: false),
      );

      // The account holder also has a `profiles` row, which the Profile header
      // and `ProfileController` still read. Keep the two in step.
      if (_isAccount) {
        await ref.read(profileRepositoryProvider).updateProfileDetails(
          fullName: name,
          username: username,
          pronouns: _pronouns,
          gender: _selectedGender,
        );
        ref.invalidate(profileProvider);
      }

      ref.invalidate(familyMembersProvider);
      ref.invalidate(familyMemberProvider(memberId));

      // The Profile header renders the currently selected member, so refresh it
      // in place when the edited member is the active one.
      final FamilyMember? refreshed = await ref
          .read(familyRepositoryProvider)
          .getFamilyMemberById(memberId);
      if (refreshed != null &&
          ref.read(selectedFamilyMemberProvider)?.id == memberId) {
        ref.read(selectedFamilyMemberProvider.notifier).state = refreshed;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackArrowButton(),
        title: Text(_isAccount ? 'Edit Profile' : 'Edit ${widget.member.name}'),
        actions: <Widget>[
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.check, size: 26),
                  onPressed: _saveProfile,
                  tooltip: 'Save Changes',
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: <Widget>[
            _SectionCard(
              title: 'Personal Information',
              icon: Icons.badge_outlined,
              children: <Widget>[
                _AvatarPicker(
                  name: _nameController.text.trim().isEmpty
                      ? 'User'
                      : _nameController.text.trim(),
                  avatarUrl: _avatarUrl,
                  onTap: _showImagePickerBottomSheet,
                ),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  validator: (String? val) =>
                      val == null || val.trim().isEmpty
                          ? 'Name is required'
                          : null,
                  onChanged: (_) => setState(() {}),
                ),
                _ProfileDropdown<RelationshipType>(
                  labelText: 'Relationship',
                  prefixIcon: Icons.diversity_1_outlined,
                  value: _relationship,
                  options: RelationshipType.values,
                  optionLabel: (RelationshipType value) => value.label,
                  onChanged: (RelationshipType? val) {
                    if (val != null) setState(() => _relationship = val);
                  },
                ),
                InkWell(
                  onTap: _pickBirthDate,
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      prefixIcon: const Icon(Icons.cake_outlined),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      errorText:
                          _relationship == RelationshipType.child &&
                              _birthDate == null
                          ? 'Required for a child profile'
                          : null,
                    ),
                    child: Text(_birthDateLabel),
                  ),
                ),
                if (_isAccount)
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixText: '@',
                      prefixIcon: Icon(Icons.alternate_email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    validator: (String? val) =>
                        val == null || val.trim().isEmpty
                            ? 'Username is required'
                            : null,
                  ),
                _ProfileDropdown<String>(
                  labelText: 'Pronouns (Optional)',
                  prefixIcon: Icons.face_outlined,
                  value: _pronounOptions.contains(_pronouns) ? _pronouns : null,
                  options: _pronounOptions,
                  onChanged: (String? val) => setState(() => _pronouns = val),
                ),
                _ProfileDropdown<String>(
                  labelText: 'Gender',
                  prefixIcon: Icons.wc_outlined,
                  value: _genderOptions.contains(_selectedGender)
                      ? _selectedGender
                      : null,
                  options: _genderOptions,
                  onChanged: (String? val) =>
                      setState(() => _selectedGender = val),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionCard(
              title: 'Sizing & Measurements',
              icon: Icons.straighten_outlined,
              children: <Widget>[
                const _FieldLabel('Shoe Size'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _shoeSizeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Size',
                          hintText: 'e.g. 38',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _ProfileDropdown<String>(
                        labelText: 'System',
                        value: _shoeUnit,
                        options: _shoeUnitOptions,
                        onChanged: (String? val) {
                          if (val != null) setState(() => _shoeUnit = val);
                        },
                      ),
                    ),
                  ],
                ),
                const _FieldLabel('Apparel Sizes'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _ProfileDropdown<String>(
                        labelText: 'Tops',
                        value: _topsSizeOptions.contains(_topsSize)
                            ? _topsSize
                            : null,
                        options: _topsSizeOptions,
                        onChanged: (String? val) =>
                            setState(() => _topsSize = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ProfileDropdown<String>(
                        labelText: 'Bottoms',
                        value: _bottomsSizeOptions.contains(_bottomsSize)
                            ? _bottomsSize
                            : null,
                        options: _bottomsSizeOptions,
                        onChanged: (String? val) =>
                            setState(() => _bottomsSize = val),
                      ),
                    ),
                  ],
                ),
                const _FieldLabel('Body Metrics'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Height',
                          hintText: 'Optional',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ProfileDropdown<String>(
                        labelText: 'Unit',
                        value: _heightUnit,
                        options: const <String>[
                          _EditProfileScreenState._lengthUnitCm,
                          _EditProfileScreenState._lengthUnitFt,
                        ],
                        onChanged: _changeHeightUnit,
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Weight',
                          hintText: 'Optional',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ProfileDropdown<String>(
                        labelText: 'Unit',
                        value: _weightUnit,
                        options: const <String>[
                          _EditProfileScreenState._weightUnitKg,
                          _EditProfileScreenState._weightUnitLbs,
                        ],
                        onChanged: _changeWeightUnit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionCard(
              title: 'Style Preferences',
              icon: Icons.auto_awesome_outlined,
              children: <Widget>[
                const _FieldLabel('Style Aesthetics'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final String aesthetic in _styleAestheticOptions)
                      FilterChip(
                        label: Text(aesthetic),
                        avatar: const Icon(Icons.check, size: 18),
                        selected: _selectedAesthetics.contains(aesthetic),
                        onSelected: (_) => _toggleAesthetic(aesthetic),
                      ),
                  ],
                ),
                const _FieldLabel('Color Preferences'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final _ColorPreference option
                        in _colorPreferenceOptions)
                      _ColorPreferenceChip(
                        option: option,
                        selected: _selectedColors.contains(option.name),
                        onToggle: () => _toggleColor(option.name),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Changes'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card container that gives each group of fields a titled heading.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (int index = 0; index < children.length; index++) ...<Widget>[
            if (index > 0) const SizedBox(height: 16),
            children[index],
          ],
        ],
      ),
    );
  }
}

/// Uppercase-style caption used above each row of a section.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }
}

/// Dropdown that stays in sync with external state (e.g. hydration from the
/// fetched profile) by re-keying itself whenever the selected value changes.
class _ProfileDropdown<T> extends StatelessWidget {
  const _ProfileDropdown({
    required this.labelText,
    required this.value,
    required this.options,
    required this.onChanged,
    this.prefixIcon,
    this.optionLabel,
  });

  final String labelText;
  final T? value;
  final List<T> options;
  final ValueChanged<T?> onChanged;
  final IconData? prefixIcon;

  /// Overrides how each option is rendered. Needed for enums whose `toString`
  /// is not the user-facing label, e.g. [RelationshipType].
  final String Function(T value)? optionLabel;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      key: ValueKey<String>('$labelText::$value'),
      initialValue: value,
      isDense: true,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      items: options
          .map(
            (T option) => DropdownMenuItem<T>(
              value: option,
              child: Text(optionLabel?.call(option) ?? option.toString()),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

/// Profile avatar with a tappable edit badge, kept inside the personal
/// information card.
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.name,
    required this.onTap,
    this.avatarUrl,
  });

  final String name;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        children: <Widget>[
          Stack(
            alignment: Alignment.bottomRight,
            children: <Widget>[
              FamilyMemberAvatar(
                name: name,
                avatarUrl: avatarUrl,
                radius: 50,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.surfaceContainerLow,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 14,
                      color: colors.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.photo_camera_outlined, size: 18),
            label: const Text('Change Photo'),
          ),
        ],
      ),
    );
  }
}

/// Selectable colour pill used for the preferred shades list.
class _ColorPreferenceChip extends StatelessWidget {
  const _ColorPreferenceChip({
    required this.option,
    required this.selected,
    required this.onToggle,
  });

  final _ColorPreference option;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onToggle(),
      showCheckmark: false,
      avatar: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: option.color,
          shape: BoxShape.circle,
          // Keeps the white swatch visible against light surfaces.
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
      ),
      label: Text(option.name),
    );
  }
}
