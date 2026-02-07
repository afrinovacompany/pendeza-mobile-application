// profile_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
// To trigger ReloadUser

import '../../../0_auth/presentation/bloc/auth_event.dart';
import '../../data/models/profile_stats.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;
  final AuthBloc _authBloc;

  ProfileBloc({
    required ProfileRepository profileRepository,
    required AuthBloc authBloc,
  })  : _profileRepository = profileRepository,
        _authBloc = authBloc,
        super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfileImage>(_onUpdateProfileImage);
    on<UpdateProfileInfo>(_onUpdateProfileInfo);
  }

  Future<void> _onLoadProfile(
      LoadProfile event,
      Emitter<ProfileState> emit,
      ) async {
    emit(ProfileLoading());
    try {
      final stats = await _profileRepository.getUserStats(event.userId);
      emit(ProfileLoaded(stats: stats));
    } catch (e) {
      log.e('ProfileBloc: Error loading profile', error: e);
      emit(const ProfileError('Could not load profile data'));
    }
  }

  Future<void> _onUpdateProfileImage(
      UpdateProfileImage event,
      Emitter<ProfileState> emit,
      ) async {
    // Preserve current stats if possible
    ProfileStats? currentStats;
    if (state is ProfileLoaded) {
      currentStats = (state as ProfileLoaded).stats;
    }

    emit(ProfileImageUploading(previousStats: currentStats));

    try {
      // 1. Upload logic via repo
      await _profileRepository.updateProfileImage(
        userId: event.userId,
        imageFile: event.imageFile,
      );

      // 2. IMPORTANT: Tell AuthBloc to reload the user!
      // This ensures the sidebar, header, and other auth-dependent widgets
      // see the new image URL immediately.
      _authBloc.add(ReloadUser());

      // 3. Emit Success (which UI can listen to show a snackbar)
      emit(const ProfileUpdateSuccess('Profile picture updated!'));

      // 4. Return to Loaded state
      if (currentStats != null) {
        emit(ProfileLoaded(stats: currentStats));
      }
    } catch (e) {
      emit(const ProfileError('Failed to upload image'));
      // Fallback
      if (currentStats != null) {
        emit(ProfileLoaded(stats: currentStats));
      }
    }
  }

  Future<void> _onUpdateProfileInfo(
      UpdateProfileInfo event,
      Emitter<ProfileState> emit,
      ) async {
    emit(ProfileLoading());
    try {
      await _profileRepository.updateProfileData(
        userId: event.userId,
        data: event.data,
      );

      // Sync AuthBloc
      _authBloc.add(ReloadUser());

      emit(const ProfileUpdateSuccess('Profile updated successfully'));

      // Re-fetch stats to return to stable state
      add(LoadProfile(userId: event.userId));
    } catch (e) {
      emit(const ProfileError('Failed to update profile info'));
    }
  }
}