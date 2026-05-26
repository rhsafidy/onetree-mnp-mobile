// lib/core/constants/db_constants.dart

abstract class DbConstants {
  static const String dbName = 'une_touriste_un_arbre.db';
  static const int dbVersion = 1;
  static const int syncMaxRetries = 5;

  // Tables
  static const String tableUsers      = 'users';
  static const String tableTourists   = 'tourists';
  static const String tableParcels    = 'parcels';
  static const String tableTrees      = 'trees';
  static const String tablePhotos     = 'photos';
  static const String tableSyncQueue  = 'sync_queue';

  // Shared
  static const String colId          = 'id';
  static const String colCreatedAt   = 'created_at';
  static const String colUpdatedAt   = 'updated_at';
  static const String colSyncPending = 'sync_pending';

  // users
  static const String colUserName         = 'name';
  static const String colUserEmail        = 'email';
  static const String colUserPasswordHash = 'password_hash';
  static const String colUserRole         = 'role';

  // tourists
  static const String colTouristName        = 'name';
  static const String colTouristEmail       = 'email';
  static const String colTouristNationality = 'nationality';
  static const String colTouristPhone       = 'phone';

  // parcels
  static const String colParcelName          = 'name';
  static const String colParcelCode          = 'code';
  static const String colParcelPark          = 'park';
  static const String colParcelAreaHa        = 'area_ha';
  static const String colParcelLatitude      = 'latitude';
  static const String colParcelLongitude     = 'longitude';
  static const String colParcelNotes         = 'notes';
  static const String colParcelShapefileName = 'shapefile_name';

  // trees
  static const String colTreeExternalId        = 'external_id';
  static const String colTreeSpeciesScientific = 'species_scientific';
  static const String colTreeSpeciesVernacular = 'species_vernacular';
  static const String colTreePlanterName       = 'planter_name';
  static const String colTreePlanterFunction   = 'planter_function';
  static const String colTreePlantationDate    = 'plantation_date';
  static const String colTreeArea              = 'area';
  static const String colTreeFamily            = 'family';
  static const String colTreeHeightCm          = 'height_cm';
  static const String colTreeHoleNumber        = 'hole_number';
  static const String colTreeHealthStatus      = 'health_status';
  static const String colTreeLatitude          = 'latitude';
  static const String colTreeLongitude         = 'longitude';
  static const String colTreeNotes             = 'notes';
  static const String colTreeParcelId          = 'parcel_id';
  static const String colTreeTouristId         = 'tourist_id';
  static const String colTreePlantedByUserId   = 'planted_by_user_id';

  // photos
  static const String colPhotoUrl              = 'url';
  static const String colPhotoLocalPath        = 'local_path';
  static const String colPhotoType             = 'type';
  static const String colPhotoTreeId           = 'tree_id';
  static const String colPhotoUploadedByUserId = 'uploaded_by_user_id';

  // sync_queue
  static const String colSyncTypeAction  = 'type_action';
  static const String colSyncTableTarget = 'table_target';
  static const String colSyncEntityId    = 'entity_id';
  static const String colSyncPayloadJson = 'payload_json';
  static const String colSyncAttempts    = 'attempts';
  static const String colSyncStatus      = 'status';
}

abstract class SyncActions {
  static const String create      = 'CREATE';
  static const String update      = 'UPDATE';
  static const String uploadPhoto = 'UPLOAD_PHOTO';
  static const String delete      = 'DELETE';
}

abstract class SyncStatus {
  static const String pending    = 'pending';
  static const String inProgress = 'in_progress';
  static const String done       = 'done';
  static const String failed     = 'failed';
}

abstract class TreeHealthStatus {
  static const String pending   = 'pending';
  static const String planted   = 'planted';
  static const String monitored = 'monitored';
  static const String dead      = 'dead';
  static const String replaced  = 'replaced';
}

abstract class PhotoTypeValues {
  static const String plantation = 'plantation';
  static const String monthly    = 'monthly';
  static const String replanting = 'replanting';
}

abstract class UserRoles {
  static const String admin        = 'admin';
  static const String agent        = 'agent';
  static const String receptionist = 'receptionist';
}
