/// Tamil string constants for NilamAI UI.
///
/// All user-facing Tamil text should be defined here for
/// consistency and future i18n support.
class TamilStrings {
  TamilStrings._();

  // -- App --
  static const String appName = 'நிலம்AI';
  static const String appTagline = 'உங்கள் விவசாய உதவியாளர்';

  // -- Greetings --
  static const String greeting = 'வணக்கம்!';

  // -- Navigation --
  static const String home = 'முகப்பு';
  static const String settings = 'அமைப்புகள்';
  static const String history = 'வரலாறு';
  static const String help = 'உதவி';

  // -- Actions --
  static const String askQuestion = 'கேள்வி கேளுங்கள்';
  static const String record = 'பதிவு செய்';
  static const String stop = 'நிறுத்து';
  static const String play = 'இயக்கு';
  static const String retry = 'மீண்டும் முயற்சிக்கவும்';
  static const String cancel = 'ரத்து செய்';
  static const String save = 'சேமி';
  static const String delete = 'நீக்கு';

  // -- Status --
  static const String loading = 'ஏற்றுகிறது...';
  static const String listening = 'கேட்கிறேன்...';
  static const String processing = 'செயலாக்குகிறது...';
  static const String ready = 'தயார்';

  // -- Recording --
  static const String recordingTitle = 'உங்கள் கேள்வியைக் கேளுங்கள்';
  static const String tapToRecord = 'பதிவு செய்ய தட்டுங்கள்';
  static const String recordingActive = 'பதி���ு செய்கிறது...';
  static const String recordingComplete = 'பதி��ு முடிந்தது';

  // -- Permissions --
  static const String micPermissionNeeded = 'மைக்ரோஃபோன் அனுமதி தேவை';
  static const String micPermissionExplain =
      'உங்கள் குரலை பதிவு செய்ய மைக்ரோஃபோன் அனுமதி அவசியம்';
  static const String openSettings = 'அமைப்புகளைத் திற';

  // -- Quality warnings --
  static const String warningTooQuiet =
      'சத்தம் குறைவாக உள்ளது. சற்று சத்தமாகப் ப���சுங்கள்';
  static const String warningClipping =
      'சத்தம் அதிகமாக உள்��து. சற்று மெதுவாகப் பேசுங்கள்';

  // -- Errors --
  static const String errorGeneral = 'பிழை ஏற்பட்டது. மீண்டும் முயற்சிக்கவும்.';
  static const String errorMicrophone = 'மைக்ரோஃபோன் அணுக முடியவில்லை';
  static const String errorNetwork = 'இணைய இணைப்பு இல்லை';
  static const String errorCodecUnsupported =
      'இந்த சாதனத்தில் ஒலி பதிவு ஆதரிக்கப்படவில்லை';
  static const String errorRecordingFailed =
      'பதிவு தோல்வி. மீண்டும் முயற்சிக்கவும்';
  static const String errorMaxDuration = 'அதிகபட்ச நேரம் எட்டப்பட்டத���';
  static const String errorDatabase = 'தரவுத்தள பிழை. மீண்டும் முயற்சிக்கவும்.';
  static const String errorDatabaseInit = 'தரவுத்தளத்தை துவக்க முடியவில்லை';

  // -- STT (Speech-to-Text) --
  static const String sttTranscribing = 'உரையாக மாற்றுகிறது...';
  static const String sttModelLoading = 'மாதிரி ஏற்றப்படுகிறது...';

  // -- Transcription review --
  static const String reviewTitle = 'பதிவு செய்த உரை';
  static const String reviewInstructions = 'தவறு இருந்தால் திருத்தவும்';
  static const String confirm = 'உறுதிசெய்';
  static const String retake = 'மீண்டும் பதிவு செய்';
  static const String transcriptionEmpty = 'எந்த உரையும் கண்டறியப்படவில்லை';
  static const String transcriptionSaved = 'சேமிக்கப்பட்டது';

  // -- STT errors (E006/E007/E008) --
  static const String errorSttModelMissing =
      'பேச்சு அறிதல் மாதிரி கிடைக்கவில்லை';
  static const String errorSttFailed =
      'உரை மாற்றம் தோல்வி. மீண்டும் முயற்சிக்கவும்';
  static const String errorSttLowConfidence =
      'உரை தெளிவாக இல்லை. திருத்தவும்';
}
