import 'package:flutter/foundation.dart';

import '../repositories/auth_repository.dart';
import '../repositories/facility_repository.dart';
import '../repositories/offline_facility_repository.dart';

@immutable
class AppDependencies {
  const AppDependencies({
    required this.authRepository,
    required this.facilityRepository,
    required this.offlineFacilityRepository,
  });

  final AuthRepository authRepository;
  final FacilityRepository facilityRepository;
  final OfflineFacilityRepository offlineFacilityRepository;
}
