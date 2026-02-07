
// lib/features/3_owner_inspiration/presentation/bloc/inspiration_state.dart
import 'package:equatable/equatable.dart';

import '../../data/model/inspiration_article_model.dart';
import '../../data/model/lookbook_image_model.dart';
import 'inspiration_event.dart';

abstract class InspirationState extends Equatable {
  const InspirationState();
  @override
  List<Object?> get props => [];
}

class InspirationInitial extends InspirationState {
  const InspirationInitial();
}

class InspirationLoading extends InspirationState {
  const InspirationLoading();
}

class InspirationLoaded extends InspirationState {
  final List<InspirationArticleModel> articles;
  final List<LookbookImageModel> lookbook;
  final InspirationTab selectedTab;

  const InspirationLoaded({
    required this.articles,
    required this.lookbook,
    required this.selectedTab,
  });

  InspirationLoaded copyWith({InspirationTab? selectedTab}) {
    return InspirationLoaded(
      articles: articles,
      lookbook: lookbook,
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }

  @override
  List<Object?> get props => [articles, lookbook, selectedTab];
}

class InspirationError extends InspirationState {
  final String message;
  const InspirationError(this.message);
  @override
  List<Object?> get props => [message];
}