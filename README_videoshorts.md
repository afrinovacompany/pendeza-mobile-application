# 🎬 Video Shorts Feature - Pendeza

Instagram/TikTok-style video shorts for salon owners to showcase their work.

## ✅ Features Implemented

### Phase 1: Owner Upload
- ✅ Video upload from camera or gallery
- ✅ 60-second max duration validation
- ✅ Auto-generated thumbnail (first frame)
- ✅ Video compression for faster uploads
- ✅ 3 videos max per salon
- ✅ Admin approval workflow (pending → approved/rejected)
- ✅ Caption editing
- ✅ Delete videos

### Phase 2: Client View
- ✅ Instagram-style story circles on dashboard
- ✅ Gradient ring around thumbnails
- ✅ Salon name below each circle
- ✅ Video count badge for multiple videos
- ✅ Full-screen TikTok-style viewer
- ✅ Vertical swipe navigation
- ✅ Auto-play and loop
- ✅ Tap to pause/play
- ✅ "Book Now" button → Service Selection
- ✅ Progress bar at bottom
- ✅ Salon info overlay

---

## 📁 File Structure

```
lib/
├── shared/models/
│   └── salon_video_model.dart          # Video data model
│
├── app/
│   ├── helpers/
│   │   └── video_compressor_helper.dart # Compression & thumbnail
│   ├── config/
│   │   └── app_router_additions.dart    # Router additions guide
│   └── services/
│       └── service_locator_additions.dart # DI additions guide
│
├── features/
│   ├── 3_owner_management/salon_profile/
│   │   ├── domain/repositories/
│   │   │   └── salon_profile_repository.dart    # Updated interface
│   │   ├── data/repositories/
│   │   │   └── salon_profile_repository_impl.dart # Updated impl
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── salon_profile_bloc.dart   # Updated with video events
│   │       │   ├── salon_profile_event.dart  # Added video events
│   │       │   └── salon_profile_state.dart  # Added video states
│   │       └── widgets/
│   │           └── salon_videos_section.dart # NEW: Owner video management
│   │
│   ├── video_shorts/                          # NEW FEATURE MODULE
│   │   ├── domain/
│   │   │   └── video_shorts_repository.dart
│   │   ├── data/
│   │   │   └── video_shorts_repository_impl.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── video_shorts_bloc.dart
│   │       │   ├── video_shorts_event.dart
│   │       │   └── video_shorts_state.dart
│   │       ├── widgets/
│   │       │   └── video_story_widget.dart   # Instagram circles
│   │       └── screens/
│   │           └── video_viewer_screen.dart  # TikTok viewer
│   │
│   └── 2_client_dashboard/presentation/screens/
│       └── client_dashboard_screen.dart       # Updated with stories
│
├── firestore.rules                            # Updated Firestore rules
└── PUBSPEC_ADDITIONS.yaml                     # Required packages
```

---

## 🔧 Integration Steps

### Step 1: Add Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  video_player: ^2.8.2
  video_compress: ^3.1.2
  image_picker: ^1.0.7  # If not already present
```

Run: `flutter pub get`

### Step 2: Copy Files

Copy all files from this package to your project maintaining the same structure.

### Step 3: Update Service Locator

Add to `service_locator.dart`:
```dart
// Imports
import 'package:pendeza/features/video_shorts/domain/video_shorts_repository.dart';
import 'package:pendeza/features/video_shorts/data/video_shorts_repository_impl.dart';
import 'package:pendeza/features/video_shorts/presentation/bloc/video_shorts_bloc.dart';

// In setupServiceLocator():
sl.registerLazySingleton<VideoShortsRepository>
  () => VideoShortsRepositoryImpl(firestore: sl<FirebaseFirestore>()),
);

sl.registerFactory<VideoShortsBloc>(
  () => VideoShortsBloc(repository: sl<VideoShortsRepository>()),
);
```

### Step 4: Update Firestore Rules

Deploy the updated `firestore.rules` file:
```bash
firebase deploy --only firestore:rules
```

### Step 5: Create Firestore Index

Create a composite index for `salon_videos` collection:
- Collection: `salon_videos`
- Fields: `status` (Ascending), `approvedAt` (Descending)

### Step 6: Update Salon Profile Screen

Add the `SalonVideosSection` widget to your salon profile screen:
```dart
// In salon_profile_screen.dart, inside the loaded state builder:

SalonVideosSection(
  videos: state.videos,
),
```

### Step 7: Android/iOS Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to record videos.</string>
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to record audio with videos.</string>
```

---

## 📊 Firestore Structure

### salon_videos Collection
```javascript
{
  id: "auto-generated",
  salonId: "LZ8RMsaWTb4DdPAw1pqe",
  salonName: "Cutting Master Barbershop",  // Denormalized
  salonImage: "https://...",                // Denormalized
  salonAddress: "Kinondoni, Dar es Salaam", // Denormalized
  videoUrl: "https://firebasestorage...",
  thumbnailUrl: "https://firebasestorage...",
  caption: "Fresh fade for the weekend! 💈",
  durationSeconds: 45,
  createdAt: Timestamp,
  approvedAt: Timestamp | null,
  expiresAt: Timestamp | null,              // For auto-delete
  status: "pending" | "approved" | "rejected",
  rejectionReason: null | "String",
  ownerId: "rsIfmHpNKmYFRQANw6m6gCqy1PN2"
}
```

### Firebase Storage Structure
```
salon_videos/
├── {salonId}/
│   ├── {timestamp}.mp4          # Compressed video
│   └── thumbnails/
│       └── {videoId}_thumb.jpg  # Auto-generated thumbnail
```

---

## 🎯 Usage

### Owner Side
1. Navigate to Salon Profile
2. Scroll to "Video Shorts" section
3. Tap "Add Video"
4. Record or select video (max 60 sec)
5. Add optional caption
6. Tap "Upload Video"
7. Video goes to "Pending Review"
8. Admin approves → Video goes live

### Client Side
1. Open Dashboard
2. See "Trending Now" story circles at top
3. Tap any circle
4. Full-screen video player opens
5. Swipe up/down to navigate videos
6. Tap "Book Now" → Service Selection

---

## 🛠️ Admin Panel (Future)

For admin approval, you'll need an admin panel to:
1. View pending videos
2. Preview video
3. Approve or reject with reason

Query for pending videos:
```dart
FirebaseFirestore.instance
  .collection('salon_videos')
  .where('status', isEqualTo: 'pending')
  .orderBy('createdAt', descending: false) // Oldest first
  .get();
```

Approve video:
```dart
await doc.update({
  'status': 'approved',
  'approvedAt': FieldValue.serverTimestamp(),
  'expiresAt': Timestamp.fromDate(
    DateTime.now().add(Duration(days: 30)), // 30-day expiry
  ),
});
```

Reject video:
```dart
await doc.update({
  'status': 'rejected',
  'rejectionReason': 'Content guidelines violation',
});
```

---

## ⚡ Performance Notes

- Videos are compressed before upload (~70% size reduction)
- Thumbnails auto-generated from first frame
- Pre-loading of adjacent videos in viewer
- Memory cleanup for distant videos
- Lazy loading of video controllers

---

## 🔮 Phase 3 Ideas (Future)

- [ ] Like/heart videos
- [ ] Share videos
- [ ] Service tagging
- [ ] View analytics
- [ ] Promoted/featured videos
- [ ] Video categories/filters
- [ ] Sound on/off toggle
- [ ] Comment section

---

Built with ❤️ for Pendeza
