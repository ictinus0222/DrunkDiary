import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/alcohol_repository.dart';

final alcoholRepositoryProvider = Provider((ref) => AlcoholRepository());
