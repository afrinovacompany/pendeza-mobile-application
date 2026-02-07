import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/app/helpers/video_compressor_helper.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/shared/models/salon_video_model.dart';

import '../../domain/repositories/salon_profile_repository.dart';
import 'salon_profile_event.dart';
import 'salon_profile_state.dart';

class SalonProfileBloc extends Bloc<SalonProfileEvent, SalonProfileState> {
  final SalonProfileRepository _repository;
  final AuthBloc _authBloc;
  final FirestoreService _firestoreService;

  String? _cachedSalonId;
  
  /// Maximum videos allowed per salon
  static const int maxVideosPerSalon = 3;

  SalonProfileBloc({
    required SalonProfileRepository repository,
    required AuthBloc authBloc,
    required FirestoreService firestoreService,
  })  : _repository = repository,
        _authBloc = authBloc,
        _firestoreService = firestoreService,
        super(const SalonProfileInitial()) {
    // Existing handlers
    on<LoadSalonProfile>(_onLoadSalonProfile);
    on<RefreshSalonProfile>(_onRefreshSalonProfile);
    on<UpdateBasicInfo>(_onUpdateBasicInfo);
    on<UpdateContactInfo>(_onUpdateContactInfo);
    on<UploadSalonImage>(_onUploadSalonImage);
    on<DeletePrimaryImage>(_onDeletePrimaryImage);
    on<DeleteGalleryImage>(_onDeleteGalleryImage);
    on<UpdateBusinessHours>(_onUpdateBusinessHours);
    on<UpdateAmenities>(_onUpdateAmenities);
    
    // 🆕 Video handlers
    on<LoadSalonVideos>(_onLoadSalonVideos);
    on<UploadSalonVideo>(_onUploadSalonVideo);
    on<UpdateVideoCaption>(_onUpdateVideoCaption);
    on<DeleteSalonVideo>(_onDeleteSalonVideo);
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

  /// Helper to get current videos from state
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
  // LOAD PROFILE (Updated to include videos)
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
  // REFRESH PROFILE
  //============================================================================

  Future<void> _onRefreshSalonProfile(
    RefreshSalonProfile event,
    Emitter<SalonProfileState> emit,
  ) async {
    final currentState = state;
    final currentVideos = _getCurrentVideos();

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
  // UPDATE BASIC INFO
  //============================================================================

  Future<void> _onUpdateBasicInfo(
    UpdateBasicInfo event,
    Emitter<SalonProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SalonProfileLoaded) return;
    final currentVideos = currentState.videos;

    emit(SalonProfileUploading(currentState.salon, 0, videos: currentVideos));

    try {
      final salonId = await _getSalonId();

      await _repository.updateBasicInfo(
        salonId: salonId,
        salonName: event.salonName,
        description: event.description,
        address: event.address,
      );

      final updatedSalon = await _repository.getSalonProfile(salonId);

      emit(SalonProfileOperationSuccess(
        updatedSalon,
        'Basic information updated successfully!',
        videos: currentVideos,
      ));

      emit(SalonProfileLoaded(updatedSalon, videos: currentVideos));
    } catch (e) {
      emit(SalonProfileError('Failed to update info: ${e.toString()}'));
      await Future.delayed(const Duration(milliseconds: 500));
      emit(currentState);
    }
  }

  //============================================================================
  // UPDATE CONTACT INFO
  //============================================================================

  Future<void> _onUpdateContactInfo(
    UpdateContactInfo event,
    Emitter<SalonProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SalonProfileLoaded) return;
    final currentVideos = currentState.videos;

    emit(SalonProfileUploading(currentState.salon, 0, videos: currentVideos));

    try {
      final salonId = await _getSalonId();

      await _repository.updateContactInfo(
        salonId: salonId,
        phoneNumber: event.phoneNumber,
        whatsappNumber: event.whatsappNumber,
        instagram: event.instagram,
        facebook: event.facebook,
      );

      final updatedSalon = await _repository.getSalonProfile(salonId);

      emit(SalonProfileOperationSuccess(
        updatedSalon,
        'Contact information updated successfully!',
        videos: currentVideos,
      ));

      emit(SalonProfileLoaded(updatedSalon, videos: currentVideos));
    } catch (e) {
      emit(SalonProfileError('Failed to update contact: ${e.toString()}'));
      await Future.delayed(const Duration(milliseconds: 500));
      emit(currentState);
    }
  }

  //============================================================================
  // UPLOAD IMAGE
  //============================================================================

  Future<void> _onUploadSalonImage(
    UploadSalonImage event,
    Emitter<SalonProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SalonProfileLoaded) return;
    final currentVideos = currentState.videos;

    try {
      final salonId = await _getSalonId();

      emit(SalonProfileUploading(
        currentState.salon,
        0.0,
        videos: currentVideos,
        uploadType: event.isPrimary ? 'primary' : 'gallery',
      ));

      final imageUrl = await _repository.uploadImage(
        salonId: salonId,
        imagePath: event.imagePath,
        isPrimary: event.isPrimary,
        onProgress: (progress) {
          if (!emit.isDone) {
            emit(SalonProfileUploading(
              currentState.salon,
              progress,
              videos: currentVideos,
              uploadType: event.isPrimary ? 'primary' : 'gallery',
            ));
          }
        },
      );

      if (event.isPrimary) {
        await _repository.updatePrimaryImage(salonId, imageUrl);
      } else {
        await _repository.addGalleryImage(salonId, imageUrl);
      }

      final updatedSalon = await _repository.getSalonProfile(salonId);

      emit(SalonProfileOperationSuccess(
        updatedSalon,
        'Photo uploaded successfully!',
        videos: currentVideos,
      ));

      emit(SalonProfileLoaded(updatedSalon, videos: currentVideos));
    } catch (e) {
      emit(SalonProfileError('Failed to upload image: ${e.toString()}'));
      await Future.delayed(const Duration(milliseconds: 500));
      emit(currentState);
    }
  }

  //============================================================================
  // DELETE PRIMARY IMAGE
  //============================================================================

  Future<void> _onDeletePrimaryImage(
    DeletePrimaryImage event,
    Emitter<SalonProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SalonProfileLoaded) return;
    final currentVideos = currentState.videos;

    emit(SalonProfileUploading(currentState.salon, 0, videos: currentVideos));

    try {
      final salonId = await _getSalonId();

      final imageUrl = currentState.salon.primaryImage;
      if (imageUrl == null) return;

      await _repository.deleteImage(imageUrl);
      await _repository.deletePrimaryImage(salonId);

      final updatedSalon = await _repository.getSalonProfile(salonId);

      emit(SalonProfileOperationSuccess(
        updatedSalon,
        'Primary photo deleted',
        videos: currentVideos,
      ));

      emit(SalonProfileLoaded(updatedSalon, videos: currentVideos));
    } catch (e) {
      emit(SalonProfileError('Failed to delete image: ${e.toString()}'));
      await Future.delayed(const Duration(milliseconds: 500));
      emit(currentState);
    }
  }

  //============================================================================
  // DELETE GALLERY IMAGE
  //============================================================================

  Future<void> _onDeleteGalleryImage(
    DeleteGalleryImage event,
    Emitter<SalonProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SalonProfileLoaded) return;
    final currentVideos = currentState.videos;

    emit(SalonProfileUploading(currentState.salon, 0, videos: currentVideos));

    try {
      final salonId = await _getSalonId();

      final gallery = currentState.salon.imageGallery;
      if (gallery == null || event.index >= gallery.length) return;

      final imageUrl = gallery[event.index];

      await _repository.deleteImage(imageUrl);
      await _repository.deleteGalleryImage(salonId, event.index);

      final updatedSalon = await _repository.getSalonProfile(salonId);

      emit(SalonProfileOperationSuccess(
        updatedSalon,
        'Photo deleted',
        videos: currentVideos,
      ));

      emit(SalonProfileLoaded(updatedSalon, videos: currentVideos));
    } catch (e) {
      emit(SalonProfileError('Failed to delete image: ${e.toString()}'));
      await Future.delayed(const Duration(milliseconds: 500));
      emit(currentState);
    }
  }

  //============================================================================
  // UPDATE BUSINESS HOURS
  //============================================================================

  Future<void> _onUpdateBusinessHours(
    UpdateBusinessHours event,
    Emitter<SalonProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SalonProfileLoaded) return;
    final currentVideos = currentState.videos;

    emit(SalonProfileUploading(currentState.salon, 0, videos: currentVideos));

    try {
      final salonId = await _getSalonId();

      await _repository.updateBusinessHours(
        salonId: salonId,
        openingTime: event.openingTime,
        closingTime: event.closingTime,
      );

      final updatedSalon = await _repository.getSalonProfile(salonId);

      emit(SalonProfileOperationSuccess(
        updatedSalon,
        'Business hours updated successfully!',
        videos: currentVideos,
      ));

      emit(SalonProfileLoaded(updatedSalon, videos: currentVideos));
    } catch (e) {
      emit(SalonProfileError('Failed to update hours: ${e.toString()}'));
      await Future.delayed(const Duration(milliseconds: 500));
      emit(currentState);
    }
  }

  //============================================================================
  // UPDATE AMENITIES
  //============================================================================

  Future<void> _onUpdateAmenities(
    UpdateAmenities event,
    Emitter<SalonProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SalonProfileLoaded) return;
    final currentVideos = currentState.videos;

    emit(SalonProfileUploading(currentState.salon, 0, videos: currentVideos));

    try {
      final salonId = await _getSalonId();

      await _repository.updateAmenities(
        salonId: salonId,
        amenities: event.amenities,
      );

      final updatedSalon = await _repository.getSalonProfile(salonId);

      emit(SalonProfileOperationSuccess(
        updatedSalon,
        'Amenities updated successfully!',
        videos: currentVideos,
      ));

      emit(SalonProfileLoaded(updatedSalon, videos: currentVideos));
    } catch (e) {
      emit(SalonProfileError('Failed to update amenities: ${e.toString()}'));
      await Future.delayed(const Duration(milliseconds: 500));
      emit(currentState);
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

    emit(SalonVideosLoading(currentState.salon));

    try {
      final salonId = await _getSalonId();
      final videos = await _repository.getSalonVideos(salonId);
      
      emit(SalonProfileLoaded(currentState.salon, videos: videos));
    } catch (e) {
      emit(SalonVideoError(
        salon: currentState.salon,
        videos: currentState.videos,
        message: 'Failed to load videos: ${e.toString()}',
      ));
    }
  }

  //============================================================================
  // 🎬 UPLOAD SALON VIDEO
  //============================================================================

  Future<void> _onUploadSalonVideo(
    UploadSalonVideo event,
    Emitter<SalonProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SalonProfileLoaded) return;
    
    final salon = currentState.salon;
    final currentVideos = currentState.videos;

    // Check video limit
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

      // Stage 1: Compress video and generate thumbnail
      emit(SalonVideoUploading(
        salon: salon,
        videos: currentVideos,
        progress: 0.0,
        stage: 'compressing',
      ));

      final processingResult = await VideoCompressionHelper.processVideo(videoFile);

      if (processingResult == null || !processingResult.success) {
        emit(SalonVideoError(
          salon: salon,
          videos: currentVideos,
          message: processingResult?.errorMessage ?? 'Failed to process video',
        ));
        await Future.delayed(const Duration(seconds: 2));
        emit(SalonProfileLoaded(salon, videos: currentVideos));
        return;
      }

      // Stage 2: Upload video
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
          if (!emit.isDone) {
            emit(SalonVideoUploading(
              salon: salon,
              videos: currentVideos,
              progress: progress,
              stage: 'uploading_video',
            ));
          }
        },
      );

      // Stage 3: Upload thumbnail
      emit(SalonVideoUploading(
        salon: salon,
        videos: currentVideos,
        progress: 0.9,
        stage: 'uploading_thumbnail',
      ));

      // Generate a temporary ID for the thumbnail upload
      final tempVideoId = DateTime.now().millisecondsSinceEpoch.toString();
      final thumbnailUrl = await _repository.uploadVideoThumbnail(
        salonId: salonId,
        videoId: tempVideoId,
        thumbnailPath: processingResult.thumbnailFile!.path,
      );

      // Stage 4: Save to Firestore
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

      // Cleanup temp files
      await VideoCompressionHelper.deleteAllCache();

      // Update videos list
      final updatedVideos = [newVideo, ...currentVideos];

      emit(SalonProfileOperationSuccess(
        salon,
        'Video uploaded! It will be visible after admin approval.',
        videos: updatedVideos,
      ));

      emit(SalonProfileLoaded(salon, videos: updatedVideos));

    } catch (e) {
      // Cleanup on error
      await VideoCompressionHelper.deleteAllCache();
      
      emit(SalonVideoError(
        salon: salon,
        videos: currentVideos,
        message: 'Failed to upload video: ${e.toString()}',
      ));
      await Future.delayed(const Duration(seconds: 2));
      emit(SalonProfileLoaded(salon, videos: currentVideos));
    }
  }

  //============================================================================
  // 🎬 UPDATE VIDEO CAPTION
  //============================================================================

  Future<void> _onUpdateVideoCaption(
    UpdateVideoCaption event,
    Emitter<SalonProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SalonProfileLoaded) return;

    final salon = currentState.salon;
    final currentVideos = currentState.videos;

    try {
      await _repository.updateVideoCaption(
        videoId: event.videoId,
        caption: event.caption,
      );

      // Update local video list
      final updatedVideos = currentVideos.map((video) {
        if (video.id == event.videoId) {
          return video.copyWith(caption: event.caption);
        }
        return video;
      }).toList();

      emit(SalonProfileOperationSuccess(
        salon,
        'Caption updated!',
        videos: updatedVideos,
      ));

      emit(SalonProfileLoaded(salon, videos: updatedVideos));
    } catch (e) {
      emit(SalonVideoError(
        salon: salon,
        videos: currentVideos,
        message: 'Failed to update caption: ${e.toString()}',
      ));
    }
  }

  //============================================================================
  // 🎬 DELETE SALON VIDEO
  //============================================================================

  Future<void> _onDeleteSalonVideo(
    DeleteSalonVideo event,
    Emitter<SalonProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SalonProfileLoaded) return;

    final salon = currentState.salon;
    final currentVideos = currentState.videos;

    emit(SalonProfileUploading(salon, 0, videos: currentVideos, uploadType: 'video'));

    try {
      await _repository.deleteVideo(event.videoId);

      // Remove from local list
      final updatedVideos = currentVideos
          .where((video) => video.id != event.videoId)
          .toList();

      emit(SalonProfileOperationSuccess(
        salon,
        'Video deleted',
        videos: updatedVideos,
      ));

      emit(SalonProfileLoaded(salon, videos: updatedVideos));
    } catch (e) {
      emit(SalonVideoError(
        salon: salon,
        videos: currentVideos,
        message: 'Failed to delete video: ${e.toString()}',
      ));
      await Future.delayed(const Duration(seconds: 2));
      emit(SalonProfileLoaded(salon, videos: currentVideos));
    }
  }
}
