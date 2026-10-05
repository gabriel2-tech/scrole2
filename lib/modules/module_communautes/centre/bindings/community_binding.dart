import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/local_storage/structured/app_cache_database.dart';
import '../../externe/repositories/community_repository.dart';
import '../../interne/controllers/community/community_creation_controller.dart';
import '../../interne/controllers/community/community_preview_controller.dart';
import '../../interne/controllers/community/community_management_controller.dart';
import '../services/community_service.dart';

class CommunityBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CommunityRepository>()) Get.put<CommunityRepository>(CommunityRepository(Supabase.instance.client), permanent:true);
    if (!Get.isRegistered<CommunityService>()) Get.put<CommunityService>(CommunityService(Get.find<CommunityRepository>(),Get.find<AppDatabase>()), permanent:true);
    Get.lazyPut<CommunityCreationController>(()=>CommunityCreationController(Get.find<CommunityService>()),fenix:true);
    Get.lazyPut<CommunityManagementController>(()=>CommunityManagementController(Get.find<CommunityService>()),fenix:true);
    Get.lazyPut<CommunityPreviewController>(()=>CommunityPreviewController(Get.find<CommunityService>(),Get.parameters['id']??''),fenix:true);
  }
}
