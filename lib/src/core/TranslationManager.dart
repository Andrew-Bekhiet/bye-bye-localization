import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Manager to help translate and download the AI Model for translation
class TranslationManager {
  late TranslateLanguage _originLanguage = TranslateLanguage.english;
  late TranslateLanguage _translateTo = TranslateLanguage.arabic;
  final _languageModelManager = OnDeviceTranslatorModelManager();
  late OnDeviceTranslator _onDeviceTranslator;
  late bool isInitiated = false;
  static final TranslationManager _singleton = TranslationManager.initObject();

  /// save a singleton to help preserve the state of the manager
  factory TranslationManager() {
    return _singleton;
  }

  TranslationManager.initObject();

  /// init the manger,
  /// originLanguage : is the language you wish to translate from By default it's English
  /// translateToLanguage : is the language you ish to translate to, by default it will be the Device's system language
  Future<bool> init({
    TranslateLanguage originLanguage = TranslateLanguage.english,
    TranslateLanguage? translateToLanguage,
  }) async {
    _originLanguage = originLanguage;
    _translateTo = translateToLanguage ??
        BCP47Code.fromRawValue(
            PlatformDispatcher.instance.locale.languageCode)!;
    _onDeviceTranslator = OnDeviceTranslator(
        sourceLanguage: _originLanguage, targetLanguage: _translateTo);
    isInitiated = await checkModels();
    return isInitiated;
  }

  /// handle the translation
  Future<String> translateText({
    required String text,
  }) async {
    if (!isInitiated) return text;
    _onDeviceTranslator = OnDeviceTranslator(
      sourceLanguage: _originLanguage,
      targetLanguage: _translateTo,
    );
    String translate = await _onDeviceTranslator.translateText(text);
    return translate;
  }

  /// check if the AI model is download if not, it will download it automatically
  Future<bool> checkModels() async {
    bool downloadStatus = false;
    print('Checking models ..');
    await _downloadModel(_originLanguage.bcpCode).then((value) {
      print('$_originLanguage model is downloaded');
      downloadStatus = true;
    }).onError((error, stackTrace) {
      print('$error and $stackTrace');
      downloadStatus = false;
    });
    await _downloadModel(_translateTo.bcpCode).then((value) {
      print('$_translateTo model is downloaded');
      downloadStatus = true;
    }).onError((error, stackTrace) {
      print('$error and $stackTrace');
      downloadStatus = false;
    });
    return Future.value(downloadStatus);
  }

  /// to download AI model
  Future<bool> _downloadModel(String language) async {
    print('^^^^^ downloading $language model');
    bool downloaded = await _languageModelManager.isModelDownloaded(language);
    if (!downloaded)
      await _languageModelManager
          .downloadModel(language)
          .then((value) => downloaded = true)
          .onError((error, stackTrace) => downloaded = false);
    return Future.value(downloaded);
  }
}
