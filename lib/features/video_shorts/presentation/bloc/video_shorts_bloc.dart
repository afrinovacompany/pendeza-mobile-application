import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/video_shorts_repository.dart';
import 'video_shorts_event.dart';
import 'video_shorts_state.dart';

class VideoShortsBloc extends Bloc<VideoShortsEvent, VideoShortsState> {
  final VideoShortsRepository _repository;

  VideoShortsBloc({
    required VideoShortsRepository repository,
  })  : _repository = repository,
        super(const VideoShortsInitial()) {
    on<LoadVideoShorts>(_onLoadVideoShorts);
    on<RefreshVideoShorts>(_onRefreshVideoShorts);
    on<LoadSalonVideoShorts>(_onLoadSalonVideoShorts);
  }

  Future<void> _onLoadVideoShorts(
    LoadVideoShorts event,
    Emitter<VideoShortsState> emit,
  ) async {
    emit(const VideoShortsLoading());

    try {
      final videos = await _repository.getApprovedVideos();
      emit(VideoShortsLoaded(videos));
    } catch (e) {
      emit(VideoShortsError('Failed to load videos: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshVideoShorts(
    RefreshVideoShorts event,
    Emitter<VideoShortsState> emit,
  ) async {
    // Don't show loading state on refresh
    try {
      final videos = await _repository.getApprovedVideos();
      emit(VideoShortsLoaded(videos));
    } catch (e) {
      // Keep current state on refresh failure
      if (state is VideoShortsLoaded) {
        // Silently fail, keep existing videos
      } else {
        emit(VideoShortsError('Failed to refresh videos: ${e.toString()}'));
      }
    }
  }

  Future<void> _onLoadSalonVideoShorts(
    LoadSalonVideoShorts event,
    Emitter<VideoShortsState> emit,
  ) async {
    emit(const VideoShortsLoading());

    try {
      final videos = await _repository.getSalonApprovedVideos(event.salonId);
      emit(VideoShortsLoaded(videos));
    } catch (e) {
      emit(VideoShortsError('Failed to load salon videos: ${e.toString()}'));
    }
  }
}
