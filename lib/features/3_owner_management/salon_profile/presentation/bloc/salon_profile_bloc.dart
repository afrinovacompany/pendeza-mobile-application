import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/app/helpers/video_compressor_helper.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/shared/models/salon_video_model.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/repositories/salon_profile_repository.dart';
import 'salon_profile_event.dart';
import 'salon_profile_state.dart';

class SalonProfileBloc extends Bloc<SalonProfileEvent, SalonProfileState> {
  final SalonProfileRepository _repository;
  final AuthBloc _authBloc;
  final FirestoreService _firestoreService;

  String? _cachedSalonId;

  static const int maxVideosPerSalon = 3;

  bool _isVideoUploadCancelled = false;
  String? _currentUploadVideoId;

  SalonProfileBloc({
    required SalonProfileRepository repository,
    required AuthBloc authBloc,
    required FirestoreService firestoreService,
  })  : _repository = repository,
        _authBloc = authBloc,
        _firestoreService = firestoreService,
        super(const SalonProfileInitial()) {
    on<LoadSalonProfile>(_onLoadSalonProfile);
    on<RefreshSalonProfile>(_onRefreshSalonProfile);
    on<UpdateBasicInfo>(_onUpdateBasicInfo);
    on<UpdateContactInfo>(_onUpdateContactInfo);
    on<UploadSalonImage>(_onUploadSalonImage);
    on<DeletePrimaryImage>(_onDeletePrimaryImage);
    on<DeleteGalleryImage>(_onDeleteGalleryImage);
    on<UpdateBusinessHours>(_onUpdateBusinessHours);
    on<UpdateAmenities>(_onUpdateAmenities);
    on<LoadSalonVideos>(_onLoadSalonVideos);
    on<UploadSalonVideo>(_onUploadSalonVideo);
    on<UpdateVideoCaption>(_onUpdateVideoCaption);
    on<DeleteSalonVideo>(_onDeleteSalonVideo);
    on<CancelVideoUpload>(_onCancelVideoUpload);
  }

  Future<String> _getSalonId() async {
    if (_cachedSalonId != null) return _cachedSalonId!;

    final authState = _authBloc.state;
    if (authState is! Authenticated) {
      throw Exception('User not authenticated');
    }

    final ownerId = authState.user.uid;
    final salon = await _firestoreService.getSalonForOwner(ownerId: ownerId);
    if (salon == null) {
      throw Exception('No salon found for this owner');
    }

    _cachedSalonId = salon.id;
    return salon.id;
  }

  List<SalonVideoModel> _getCurrentVideos() {
    final currentState = state;
    if (currentState is SalonProfileLoaded) return currentState.videos;
    if (currentState is SalonProfileUploading) return currentState.videos;
    if (currentState is SalonProfileOperationSuccess) return currentState.videos;
    if (currentState is SalonVideoUploading) return currentState.videos;
    if (currentState is SalonVideoError) return currentState.videos;
    return [];
  }

  //============================================================================
  // 🎬 VIDEO METHODS
  //============================================================================

  Future<void> _onCancelVideoUpload(
      CancelVideoUpload event,
      Emitter<SalonProfileState> emit,
      ) async {
    _isVideoUploadCancelled = true;

    final currentState = state;
    if (currentState is SalonVideoUploading) {
      emit(SalonVideoError(
        salon: currentState.salon,
        videos: currentState.videos,
        message: 'Upload cancelled by user',
      ));

      await VideoCompressionHelper.deleteAllCache();

      await Future.delayed(const Duration(seconds: 2));
      _isVideoUploadCancelled = false;

      emit(SalonProfileLoaded(currentState.salon, videos: currentState.videos));
    }
  }

  //============================================================================
  // LOAD SALON PROFILE
  //============================================================================

  Future<void> _onLoadSalonProfile(
      LoadSalonProfile event,
      Emitter<SalonProfileState> emit,
      ) async {
    emit(const SalonProfileLoading());

    try {
      final salonId = await _getSalonId();
      final salon = await _repository.getSalonProfile(salonId);
      final videos = await _repository.getSalonVideos(salonId);

      emit(SalonProfileLoaded(salon, videos: videos));
    } catch (e) {
      emit(SalonProfileError('Failed to load salon profile: ${e.toString()}'));
    }
  }

  //============================================================================
  // REFRESH SALON PROFILE
  //============================================================================

  Future<void> _onRefreshSalonProfile(
      RefreshSalonProfile event,
      Emitter<SalonProfileState> emit,
      ) async {
    final currentState = state;
    try {
      final salonId = await _getSalonId();
      final salon = await _repository.getSalonProfile(salonId);
      final videos = await _repository.getSalonVideos(salonId);

      emit(SalonProfileLoaded(salon, videos: videos));
    } catch (e) {
      if (currentState is SalonProfileLoaded) {
        emit(currentState);
      } else {
        emit(SalonProfileError('Failed to refresh: ${e.toString()}'));
      }
    }
  }

  //============================================================================
  // 📝 UPDATE BASIC INFO
  //============================================================================

  Future<void> _onUpdateBasicInfo(
      UpdateBasicInfo event,
      Emitter<SalonProfileState> emit,
      ) async {
    final currentState = state;
    if (currentState is! SalonProfileLoaded) return;

    try {
      final salonId = await _getSalonId();

      await _repository.updateBasicInfo(
        salonId: salonId,
        salonName: event.salonName,
        description: event.description,
        address: event.address,
      );

      // Refresh the salon data
      final updatedSalon = await _repository.getSalonProfile(salonId);

      emit(SalonProfileOperationSuccess(
        updatedSalon,
        '✅ Basic information updated!',
        videos: currentState.videos,
      ));
      emit(SalonProfileLoaded(updatedSalon, videos: currentState.videos));
    } catch (e) {
      emit(SalonProfileError('Failed to update basic info: ${e.toString()}'));
    }
  }

  //============================================================================
  // 📞 UPDATE CONTACT INFO
  //============================================================================

  Future<void> _onUpdateContactInfo(
      UpdateContactInfo event,
      Emitter<SalonProfileState> emit,
      ) async {
    final currentState = state;
    if (currentState is! SalonProfileLoaded) return;

    try {
      final salonId = await _getSalonId();

      await _repository.updateContactInfo(
        salonId: salonId,
        phoneNumber: event.phoneNumber,
        whatsappNumber: event.whatsappNumber,
        instagram: event.instagram,
        facebook: event.facebook,
      );

      // Refresh the salon data
      final updatedSalon = await _repository.getSalonProfile(salonId);

      emit(SalonProfileOperationSuccess(
        updatedSalon,
        '✅ Contact information updated!',
        videos: currentState.videos,
      ));
      emit(SalonProfileLoaded(updatedSalon, videos: currentState.videos));
    } catch (e) {
      emit(SalonProfileError('Failed to update contact info: ${e.toString()}'));
    }
  }

  //============================================================================
  // 🖼️ UPLOAD SALON IMAGE
  //============================================================================

  Future<void> _onUploadSalonImage(
      UploadSalonImage event,
      Emitter<SalonProfileState> emit,
      ) async {
    final currentState = state;
    if (currentState is! SalonProfileLoaded) return;

    try {
      final salonId = await _getSalonId();

      emit(SalonProfileUploading(
        currentState.salon,
        0.0,
        videos: currentState.videos,
        uploadType: event.isPrimary ? 'primary' : 'gallery',
      ));

      // Upload image to storage
      final imageUrl = await _repository.uploadImage(
        salonId: salonId,
        imagePath: event.imagePath,
        isPrimary: event.isPrimary,
        onProgress: (progress) {
          if (!emit.isDone) {
            emit(SalonProfileUploading(
              currentState.salon,
              progress,
              videos: currentState.videos,
              uploadType: event.isPrimary ? 'primary' : 'gallery',
            ));
          }
        },
      );

      // Update Firestore based on image type
      if (event.isPrimary) {
        // Delete old primary image if exists
        if (currentState.salon.primaryImage != null) {
          try {
            await _repository.deleteImage(currentState.salon.primaryImage!);
          } catch (e) {
            // Log but don't fail if delete fails
          }
        }
        await _repository.updatePrimaryImage(salonId, imageUrl);
      } else {
        await _repository.addGalleryImage(salonId, imageUrl);
      }

      // Refresh salon data
      final updatedSalon = await _repository.getSalonProfile(salonId);

      final successMessage = event.isPrimary
          ? '✅ Primary photo updated!'
          : '✅ Photo added to gallery!';

      emit(SalonProfileOperationSuccess(
        updatedSalon,
        successMessage,
        videos: currentState.videos,
      ));
      emit(SalonProfileLoaded(updatedSalon, videos: currentState.videos));
    } catch (e) {
      emit(SalonProfileError('Failed to upload image: ${e.toString()}'));
    }
  }

  //============================================================================
  // 🗑️ DELETE PRIMARY IMAGE
  //============================================================================

  Future<void> _onDeletePrimaryImage(
      DeletePrimaryImage event,
      Emitter<SalonProfileState> emit,
      ) async {
    final currentState = state;
    if (currentState is! SalonProfileLoaded) return;
    if (currentState.salon.primaryImage == null) return;

    try {
      final salonId = await _getSalonId();

      // Delete from storage
      await _repository.deleteImage(currentState.salon.primaryImage!);

      // Delete from Firestore
      await _repository.deletePrimaryImage(salonId);

      // Refresh salon data
      final updatedSalon = await _repository.getSalonProfile(salonId);

      emit(SalonProfileOperationSuccess(
        updatedSalon,
        '🗑️ Primary photo deleted',
        videos: currentState.videos,
      ));
      emit(SalonProfileLoaded(updatedSalon, videos: currentState.videos));
    } catch (e) {
      emit(SalonProfileError('Failed to delete primary image: ${e.toString()}'));
    }
  }

  //============================================================================
  // 🗑️ DELETE GALLERY IMAGE
  //============================================================================

  Future<void> _onDeleteGalleryImage(
      DeleteGalleryImage event,
      Emitter<SalonProfileState> emit,
      ) async {
    final currentState = state;
    if (currentState is! SalonProfileLoaded) return;

    final gallery = currentState.salon.imageGallery ?? [];
    if (event.index < 0 || event.index >= gallery.length) return;

    try {
      final salonId = await _getSalonId();
      final imageUrl = gallery[event.index];

      // Delete from storage
      await _repository.deleteImage(imageUrl);

      // Delete from Firestore
      await _repository.deleteGalleryImage(salonId, event.index);

      // Refresh salon data
      final updatedSalon = await _repository.getSalonProfile(salonId);

      emit(SalonProfileOperationSuccess(
        updatedSalon,
        '🗑️ Photo deleted from gallery',
        videos: currentState.videos,
      ));
      emit(SalonProfileLoaded(updatedSalon, videos: currentState.videos));
    } catch (e) {
      emit(SalonProfileError('Failed to delete gallery image: ${e.toString()}'));
    }
  }

  //============================================================================
  // ⏰ UPDATE BUSINESS HOURS
  //============================================================================

  Future<void> _onUpdateBusinessHours(
      UpdateBusinessHours event,
      Emitter<SalonProfileState> emit,
      ) async {
    final currentState = state;
    if (currentState is! SalonProfileLoaded) return;

    try {
      final salonId = await _getSalonId();

      await _repository.updateBusinessHours(
        salonId: salonId,
        openingTime: event.openingTime,
        closingTime: event.closingTime,
      );

      // Refresh salon data
      final updatedSalon = await _repository.getSalonProfile(salonId);

      emit(SalonProfileOperationSuccess(
        updatedSalon,
        '✅ Business hours updated!',
        videos: currentState.videos,
      ));
      emit(SalonProfileLoaded(updatedSalon, videos: currentState.videos));
    } catch (e) {
      emit(SalonProfileError('Failed to update business hours: ${e.toString()}'));
    }
  }

  //============================================================================
  // ⭐ UPDATE AMENITIES
  //============================================================================

  Future<void> _onUpdateAmenities(
      UpdateAmenities event,
      Emitter<SalonProfileState> emit,
      ) async {
    final currentState = state;
    if (currentState is! SalonProfileLoaded) return;

    try {
      final salonId = await _getSalonId();

      await _repository.updateAmenities(
        salonId: salonId,
        amenities: event.amenities,
      );

      // Refresh salon data
      final updatedSalon = await _repository.getSalonProfile(salonId);

      emit(SalonProfileOperationSuccess(
        updatedSalon,
        '✅ Amenities updated!',
        videos: currentState.videos,
      ));
      emit(SalonProfileLoaded(updatedSalon, videos: currentState.videos));
    } catch (e) {
      emit(SalonProfileError('Failed to update amenities: ${e.toString()}'));
    }
  }

  //============================================================================
  // 🎬 LOAD SALON VIDEOS
  //============================================================================

  Future<void> _onLoadSalonVideos(
      LoadSalonVideos event,
      Emitter<SalonProfileState> emit,
      ) async {
    final currentState = state;
    if (currentState is! SalonProfileLoaded) return;

    try {
      final salonId = await _getSalonId();
      final videos = await _repository.getSalonVideos(salonId);

      emit(SalonProfileLoaded(currentState.salon, videos: videos));
    } catch (e) {
      // Don't change state on error, just log
    }
  }

  //============================================================================
  // 🎬 UPLOAD SALON VIDEO
  //============================================================================

  Future<void> _onUploadSalonVideo(
      UploadSalonVideo event,
      Emitter<SalonProfileState> emit,
      ) async {
    _isVideoUploadCancelled = false;
    _currentUploadVideoId = null;

    final currentState = state;
    if (currentState is! SalonProfileLoaded) return;

    final salon = currentState.salon;
    final currentVideos = currentState.videos;

    if (currentVideos.length >= maxVideosPerSalon) {
      emit(SalonVideoError(
        salon: salon,
        videos: currentVideos,
        message: 'Maximum $maxVideosPerSalon videos allowed. Please delete a video first.',
      ));
      await Future.delayed(const Duration(seconds: 2));
      emit(SalonProfileLoaded(salon, videos: currentVideos));
      return;
    }

    try {
      final salonId = await _getSalonId();
      final videoFile = File(event.videoPath);

      if (_isVideoUploadCancelled) {
        emit(SalonVideoError(
          salon: salon,
          videos: currentVideos,
          message: 'Upload cancelled',
        ));
        return;
      }

      emit(SalonVideoUploading(
        salon: salon,
        videos: currentVideos,
        progress: 0.0,
        stage: 'compressing',
      ));

      VideoProcessingResult? processingResult;

      try {
        processingResult = await VideoCompressionHelper.compressVideoTo720p(videoFile);

        if (processingResult != null &&
            processingResult.compressedVideoFile != null &&
            await processingResult.compressedVideoFile!.length() > 20 * 1024 * 1024) {
          processingResult = await VideoCompressionHelper.compressVideoTo360p(videoFile);
        }
      } catch (e) {
        processingResult = await VideoCompressionHelper.processVideo(videoFile);
      }

      if (_isVideoUploadCancelled) {
        await VideoCompressionHelper.deleteAllCache();
        emit(SalonVideoError(
          salon: salon,
          videos: currentVideos,
          message: 'Upload cancelled during compression',
        ));
        return;
      }

      if (processingResult == null || !processingResult.success) {
        emit(SalonVideoError(
          salon: salon,
          videos: currentVideos,
          message: processingResult?.errorMessage ?? 'Failed to compress video.',
        ));
        await Future.delayed(const Duration(seconds: 2));
        emit(SalonProfileLoaded(salon, videos: currentVideos));
        return;
      }

      emit(SalonVideoUploading(
        salon: salon,
        videos: currentVideos,
        progress: 0.0,
        stage: 'uploading_video',
      ));

      final videoUrl = await _repository.uploadVideo(
        salonId: salonId,
        videoPath: processingResult.compressedVideoFile!.path,
        onProgress: (progress) {
          if (!emit.isDone && !_isVideoUploadCancelled) {
            emit(SalonVideoUploading(
              salon: salon,
              videos: currentVideos,
              progress: progress * 0.8,
              stage: 'uploading_video',
            ));
          }
        },
      );

      if (_isVideoUploadCancelled) {
        try { await _repository.deleteVideoFile(videoUrl); } catch (_) {}
        await VideoCompressionHelper.deleteAllCache();
        emit(SalonVideoError(
          salon: salon,
          videos: currentVideos,
          message: 'Upload cancelled during upload',
        ));
        return;
      }

      emit(SalonVideoUploading(
        salon: salon,
        videos: currentVideos,
        progress: 0.9,
        stage: 'uploading_thumbnail',
      ));

      final thumbnailUrl = await _repository.uploadVideoThumbnail(
        salonId: salonId,
        videoId: DateTime.now().millisecondsSinceEpoch.toString(),
        thumbnailPath: processingResult.thumbnailFile!.path,
      );

      try {
        await _callVideoProcessingCloudFunction(
          salonId: salonId,
          videoUrl: videoUrl,
          duration: processingResult.durationSeconds!,
          caption: event.caption,
        );
      } catch (e) {
        // Log error and continue
      }

      emit(SalonVideoUploading(
        salon: salon,
        videos: currentVideos,
        progress: 0.95,
        stage: 'saving',
      ));

      final newVideo = await _repository.createVideoRecord(
        salonId: salonId,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        durationSeconds: processingResult.durationSeconds!,
        caption: event.caption,
      );

      _currentUploadVideoId = newVideo.id;
      await VideoCompressionHelper.deleteAllCache();

      final updatedVideos = [newVideo, ...currentVideos];
      emit(SalonProfileOperationSuccess(salon, '✅ Video uploaded!', videos: updatedVideos));
      emit(SalonProfileLoaded(salon, videos: updatedVideos));

    } catch (e) {
      await VideoCompressionHelper.deleteAllCache();
      emit(SalonVideoError(
        salon: salon,
        videos: currentVideos,
        message: 'Failed to upload video: ${e.toString()}',
      ));
      await Future.delayed(const Duration(seconds: 2));
      emit(SalonProfileLoaded(salon, videos: currentVideos));
    } finally {
      _isVideoUploadCancelled = false;
      _currentUploadVideoId = null;
    }
  }

  Future<void> _callVideoProcessingCloudFunction({
    required String salonId,
    required String videoUrl,
    required int duration,
    String? caption,
  }) async {
    try {
      final functions = FirebaseFunctions.instance;
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      await functions
          .httpsCallable('process_salon_video')
          .call({
        'salonId': salonId,
        'videoUrl': videoUrl,
        'duration': duration,
        'caption': caption,
        'ownerId': user.uid,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  //============================================================================
  // 🎬 UPDATE VIDEO CAPTION
  //============================================================================

  Future<void> _onUpdateVideoCaption(
      UpdateVideoCaption event,
      Emitter<SalonProfileState> emit
      ) async {
    final currentState = state;
    if (currentState is! SalonProfileLoaded) return;

    try {
      await _repository.updateVideoCaption(
          videoId: event.videoId,
          caption: event.caption
      );

      final updatedVideos = currentState.videos.map((v) =>
      v.id == event.videoId
          ? v.copyWith(caption: event.caption)
          : v
      ).toList();

      emit(SalonProfileOperationSuccess(
          currentState.salon,
          '✅ Caption updated!',
          videos: updatedVideos
      ));
      emit(SalonProfileLoaded(currentState.salon, videos: updatedVideos));
    } catch (e) {
      emit(SalonVideoError(
          salon: currentState.salon,
          videos: currentState.videos,
          message: e.toString()
      ));
    }
  }

  //============================================================================
  // 🎬 DELETE SALON VIDEO
  //============================================================================

  Future<void> _onDeleteSalonVideo(
      DeleteSalonVideo event,
      Emitter<SalonProfileState> emit
      ) async {
    final currentState = state;
    if (currentState is! SalonProfileLoaded) return;

    try {
      await _repository.deleteVideo(event.videoId);

      final updatedVideos = currentState.videos
          .where((v) => v.id != event.videoId)
          .toList();

      emit(SalonProfileOperationSuccess(
          currentState.salon,
          '🗑️ Video deleted',
          videos: updatedVideos
      ));
      emit(SalonProfileLoaded(currentState.salon, videos: updatedVideos));
    } catch (e) {
      emit(SalonVideoError(
          salon: currentState.salon,
          videos: currentState.videos,
          message: e.toString()
      ));
    }
  }
}