/// English UI string constants for NilamAI.
///
/// Class name `TamilStrings` is kept for backwards compatibility with the
/// 60+ existing call sites; values were swapped to English when the demo
/// scope shifted to English-only output. STT/recording keys have been
/// removed with the voice pipeline.
class TamilStrings {
  TamilStrings._();

  // -- App --
  static const String appName = 'NilamAI';
  static const String appTagline = 'AI that grows with your land';

  // -- Greetings --
  static const String greeting = 'Hello!';

  // -- Navigation --
  static const String home = 'Home';
  static const String settings = 'Settings';
  static const String history = 'History';
  static const String help = 'Help';

  // -- Actions --
  static const String askQuestion = 'Ask a question';
  static const String play = 'Play';
  static const String stop = 'Stop';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String confirm = 'Submit';
  static const String add = 'Add';
  static const String done = 'Done';
  static const String close = 'Close';

  // -- Status --
  static const String loading = 'Loading…';
  static const String processing = 'Processing…';
  static const String ready = 'Ready';

  // -- Errors --
  static const String errorGeneral = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'No internet connection.';
  static const String errorDatabase = 'Database error. Please try again.';
  static const String errorDatabaseInit = 'Could not initialize the database.';

  // -- Home --
  static const String homeTitle = 'NilamAI';
  static const String recentQuestions = 'Recent questions';
  static const String noRecentQuestions = 'No questions yet';
  static const String askQuestionCta = '✏️ Ask a question';
  static const String queryInputHint = 'Type your question here…';
  static const String quickActions = 'Quick actions';
  static const String activeCrops = 'My crops';
  static const String noActiveCrops = 'No crops added yet';

  // -- Response --
  static const String responseTitle = 'Answer';
  static const String yourQuestion = 'Your question';
  static const String aiResponse = 'AI answer';
  static const String responsePlaceholder = '🌾 The AI answer will appear here…';
  static const String gemmaLoadingModel = 'Loading AI model…';
  static const String gemmaGenerating = 'Thinking…';
  static const String gemmaError = 'AI answer unavailable';
  static const String gemmaGenerateAnswer = '✨ Get AI answer';
  static const String audioComingSoon = '🔊 Tap play to listen';
  static const String helpful = '👍 Helpful';
  static const String notHelpful = '👎 Not helpful';
  static const String ratingSaved = 'Rating saved';
  static const String goHome = '🔙 Home';
  static const String playSpeed = 'Speed';
  static const String queryNotFound = 'Question not found';
  static const String readAloud = 'Read aloud';

  // -- History --
  static const String historyTitle = 'History';
  static const String searchHint = 'Search…';
  static const String historyEmpty = '📜 No questions yet';
  static const String deleteConfirmTitle = 'Delete?';
  static const String deleteConfirmMessage =
      'Permanently delete this question?';
  static const String deleted = 'Deleted';

  // -- Settings --
  static const String settingsTitle = 'Settings';
  static const String ttsSpeedLabel = 'Voice speed';
  static const String notificationsLabel = 'Notifications';
  static const String clearHistoryLabel = '🗑️ Clear history';
  static const String clearHistoryConfirmTitle = 'Clear history?';
  static const String clearHistoryConfirmMessage =
      'All saved questions will be permanently deleted.';
  static const String historyCleared = 'History cleared';
  static const String aboutLabel = 'About';
  static const String versionLabel = 'Version';
  static const String landAreaSetting = 'Land area (acres)';
  static const String landAreaHint = 'Used for scheme eligibility';

  // -- Bottom navigation --
  static const String navHome = 'Home';
  static const String navCrops = 'Crops';
  static const String navDiagnose = 'Diagnose';
  static const String navMarket = 'Market';
  static const String navSchemes = 'Schemes';

  // -- Crop profiles --
  static const String cropsTitle = 'My crops';
  static const String addCropTitle = 'Add crop';
  static const String editCropTitle = 'Edit crop';
  static const String selectCropType = 'Crop type';
  static const String cropVariety = 'Variety (optional)';
  static const String sowingDate = 'Sowing date';
  static const String landAreaAcres = 'Land area (acres)';
  static const String soilType = 'Soil type (optional)';
  static const String irrigationType = 'Irrigation (optional)';
  static const String saveCrop = 'Save crop';
  static const String deleteCrop = 'Delete crop';
  static const String deleteCropConfirm = 'Delete this crop and its history?';
  static const String currentStage = 'Current stage';
  static const String dayOfStage = 'Day';
  static const String daysToHarvest = 'Days to harvest';
  static const String harvestExpected = 'Expected harvest';
  static const String stageActivities = 'What to do now';
  static const String stageDiseasesWatch = 'Watch for these problems';
  static const String stageFertilizer = 'Recommended fertilizer';
  static const String topDiseases = 'Common diseases';
  static const String harvestIndicators = 'When to harvest';
  static const String storageTip = 'Storage tip';
  static const String noCropsTitle = 'Track your first crop';
  static const String noCropsBody =
      'Add a crop to get stage-based reminders and AI advice tailored to your field.';
  static const String addFirstCrop = 'Add a crop';
  static const String openTimeline = 'View timeline';
  static const String askAboutThisCrop = 'Ask about this crop';
  static const String diagnoseFromCrop = 'Diagnose disease';

  // -- Disease diagnosis --
  static const String diagnoseTitle = 'Disease diagnosis';
  static const String diagnoseSubtitle =
      'Take or upload a leaf photo, and optionally describe what you see.';
  static const String capturePhoto = 'Take photo';
  static const String chooseFromGallery = 'Choose from gallery';
  static const String describeSymptoms = 'Describe symptoms';
  static const String symptomsHint =
      'Optional. e.g., yellow diamond-shaped patches on rice leaves…';
  static const String runDiagnosis = 'Run diagnosis';
  static const String diagnosisResultTitle = 'Diagnosis result';
  static const String diseaseName = 'Disease';
  static const String confidence = 'Confidence';
  static const String confidenceHigh = 'High';
  static const String confidenceMedium = 'Medium';
  static const String confidenceLow = 'Low';
  static const String cause = 'Cause';
  static const String symptoms = 'Symptoms';
  static const String treatmentChemical = 'Chemical treatment';
  static const String treatmentOrganic = 'Organic alternative';
  static const String dosage = 'Dosage and method';
  static const String safetyPrecautions = 'Safety precautions';
  static const String diagnoseEmptyState =
      'Take or pick a photo to start. You can also describe symptoms instead.';
  static const String diagnoseInputRequired =
      'Add a photo or describe symptoms first.';
  static const String diagnoseLowConfidenceAdvice =
      'Confidence is low. Consider taking another photo or consulting a local agriculture officer.';
  static const String selectCropForDiagnosis = 'Crop being diagnosed';
  static const String autoSelectStage =
      '(stage auto-selected from sowing date)';

  // -- Market prices --
  static const String marketTitle = 'Market prices';
  static const String fetchPrices = 'Fetch latest prices';
  static const String lastUpdated = 'Last updated';
  static const String priceMandi = 'Mandi';
  static const String priceModal = 'Modal';
  static const String priceMin = 'Min';
  static const String priceMax = 'Max';
  static const String pricePerQuintal = '₹ per quintal';
  static const String noPriceData = 'No price data yet. Tap refresh to fetch.';
  static const String marketHelper =
      'Live prices from data.gov.in AgMarknet. Requires an internet connection.';
  static const String marketApiKeyMissing =
      'AgMarknet API key not configured. Add DATA_GOV_IN_API_KEY to .env to enable live prices.';

  // -- Government schemes --
  static const String schemesTitle = 'Government schemes';
  static const String eligibleBadge = 'Eligible';
  static const String checkRequiredBadge = 'Check eligibility';
  static const String benefitLabel = 'What you get';
  static const String eligibilityLabel = 'Eligibility';
  static const String howToApply = 'How to apply';
  static const String openOfficialPortal = 'Open official portal';
  static const String schemesSubtitle =
      'Schemes you may be eligible for, based on your declared land size.';
  static const String setLandAreaPrompt =
      'Add land area in Settings to refine eligibility checks.';
}
