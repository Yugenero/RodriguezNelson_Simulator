//IMPORTANT:
//to use this you must import 'ttslib' into Processing, as this code uses the included FreeTTS library
//e.g. from the Menu Bar select Sketch -> Import Library... -> ttslib

import com.sun.speech.freetts.FreeTTS;
import com.sun.speech.freetts.Voice;
import com.sun.speech.freetts.VoiceManager;

class TextToSpeechMaker {

  final String TTS_FILE_DIRECTORY_NAME = "tts_samples";
  final String TTS_FILE_PREFIX = "tts";
  
  File ttsDir;
  boolean isSetup = false;
  
  int fileID = 0;
  
  FreeTTS freeTTS;
  
  private Voice voice;
    
  public TextToSpeechMaker() {
    
    VoiceManager voiceManager = VoiceManager.getInstance();
    voice = voiceManager.getVoice("kevin16");
    //using other voices is not supported (unfortunately), so you are stuck with Kevin16
    
    //find our tts_sample directory and clean it out if it has files from a previous running of this sketch
    findTTSDirectory();
    cleanTTSDirectory();
    
    freeTTS = new FreeTTS(voice);
    freeTTS.setMultiAudio(true);
    freeTTS.setAudioFile(getTTSFilePath() + "/" + TTS_FILE_PREFIX + ".wav");
    
    freeTTS.startup();
    voice.allocate();
  }
  
  //creates a WAV file of the input speech and returns the path to that file 
  public String createTTSWavFile(String input) {
    String filePath = TTS_FILE_DIRECTORY_NAME + "/" + TTS_FILE_PREFIX + Integer.toString(fileID) + ".wav";
    fileID++;
    voice.speak(input);
    return filePath; //you will need to use dataPath(filePath) if you need the full path to this file, see Example
  }
  
  //cleans up voice and FreeTTS object, use this if you are going to destroy the TextToSpeechServer object
  void cleanup() {
    voice.deallocate();
    freeTTS.shutdown();
  }
  
  String getTTSFilePath() {
    return dataPath(TTS_FILE_DIRECTORY_NAME);
  }
  
  //finds the tts file directory under the data path and creates it if it does not exist
  void findTTSDirectory() {
    File dataDir = new File(dataPath(""));
    if (!dataDir.exists()) {
      try {
        dataDir.mkdir();
      }
      catch(SecurityException se) {
        println("Data directory not present, and could not be automatically created.");
      }
    }
    
    ttsDir = new File(getTTSFilePath());
    boolean directoryExists = ttsDir.exists();
    if (!directoryExists) {
      try {
        ttsDir.mkdir();
        directoryExists = true;
      }
      catch(SecurityException se) {
        println("Error creating tts file directory '" + TTS_FILE_DIRECTORY_NAME + "' in the data directory.");
      }
    }
  }
  
  //deletes ALL files in the tts file directory found/created by this object ('tts_samples')
  void cleanTTSDirectory() {
    //delete existing files
    if (ttsDir.exists()) {
      for (File file: ttsDir.listFiles()) {
        if (!file.isDirectory())
          file.delete();
      }
    }
  }
  
}
