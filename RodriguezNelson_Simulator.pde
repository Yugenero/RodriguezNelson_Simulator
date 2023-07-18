// Import Necessary Libraries
import guru.ttslib.*;
import beads.*;
import org.jaudiolibs.beads.*;
import java.util.*;
import controlP5.*;

// Global Variables
ControlP5 p5;
TextToSpeechMaker ttsMaker;

JSONArray cadenceData;
JSONArray heartRateData;
JSONArray stepImpactData;
PImage Navigation;

WavePlayer wavePlayer;
SamplePlayer simulatorStart;
SamplePlayer toggle;
SamplePlayer unToggle;
SamplePlayer cadenceTick;
SamplePlayer heartRateBeep;
SamplePlayer stepImpactIntensity;
SamplePlayer strideLengthSynth;

Slider paceSlider;
Slider stepImpactSlider;
Knob cadenceKnob;
Knob heartRateKnob;
Knob testKnob;

float cadenceValue;
float heartRateValue;
float stepImpactValue;
float targetHeartRate;
float targetPace;
float StepImpactValue;
float StrideLengthValue;
float velocity;
float increment = 0.01;
int framerate = 1000;

boolean enableCadence = true;
boolean enableHeartRate = true;
boolean enableStepImpact = true;
boolean enableStrideLength = true;
boolean enableGPS = true;
boolean cadenceAlert = true;
boolean heartRateAlert = true;
boolean stepImpactAlert = true;
boolean toggleFilter = true;
boolean toggleDemoCondition = false;

Button Cadence;
Button StepImpact;
Button HeartRate;
Button StrideLength;

Glide masterGainGlide;
Glide toggleGlide;
Glide cadenceGlide;
Glide heartRateGlide;
Glide stepImpactGlide;
Glide strideLengthGlide;
Glide paceGlide;
Glide filterGlide;

Gain masterGain;
BiquadFilter filter;
Reverb reverb;

String eventJSON1 = "Cadence.json";
String eventJSON2 = "Heart_rate.json";
String eventJSON3 = "Step_impact.json";
String NavigationTTS;
String heartRateStatus;
String stepImpactI;


NotificationServer server;
ArrayList<Notification> notifications;
NotificationListener notificationListener;

// UI/Simulator Setup
void setup() {
  size(800, 600);
  p5 = new ControlP5(this);
  ac = new AudioContext(); // defined in helper functions; created using Beads library
  
  server = new NotificationServer();
  server.addListener(notificationListener);

  toggle = getSamplePlayer("Toggle.wav");
  unToggle = getSamplePlayer("Untoggle.wav");
  cadenceTick = getSamplePlayer("Cadence.wav");
  heartRateBeep = getSamplePlayer("Heart_rate.wav");
  stepImpactIntensity = getSamplePlayer("Step_impact.wav");
  strideLengthSynth = getSamplePlayer("Stride_length.wav"); // non-intrusive seamless loop
  simulatorStart = getSamplePlayer("Simulator_start.wav");

  toggle.pause(true);
  unToggle.pause(true);
  cadenceTick.pause(true);
  heartRateBeep.pause(true);
  stepImpactIntensity.pause(true);
  strideLengthSynth.pause(true);

  Navigation = loadImage("Navigation.png");
  cadenceData = loadJSONArray("Cadence.json"); 
  heartRateData = loadJSONArray("Heart_rate.json");
  stepImpactData = loadJSONArray("Step_impact.json");
  
  cadenceTick.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
  heartRateBeep.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
  stepImpactIntensity.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
  strideLengthSynth.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);

  // Volume properties
  masterGainGlide = new Glide(ac, 1.0, 500);
  masterGain = new Gain(ac, 1, masterGainGlide);

  filterGlide = new Glide(ac, 10.0, 0.5f);
  filter = new BiquadFilter(ac, BiquadFilter.LP, filterGlide, 0.5f);
  filter.setFrequency(1000); // 1000 -> cutoff
  reverb = new Reverb(ac);

  cadenceGlide = new Glide(ac, 1.0, 10);
  cadenceTick.setRate(cadenceGlide);

  heartRateGlide = new Glide(ac, 1.0, 10);
  heartRateBeep.setRate(heartRateGlide);

  stepImpactGlide = new Glide(ac, 1.0, 10);
  stepImpactIntensity.setRate(stepImpactGlide);

  strideLengthGlide = new Glide(ac, 1.0, 10);
  strideLengthSynth.setRate(strideLengthGlide);

  paceGlide = new Glide(ac, 1.0, 10);
  ttsMaker = new TextToSpeechMaker();

  toggleGlide = new Glide(ac, 1.0, 1);
  toggle.setRate(toggleGlide);
  toggleGlide.setValue(3);

  // Set up the WavePlayer with a sine waveform
  float frequency = 440.0;
  wavePlayer = new WavePlayer(ac, frequency, Buffer.SINE);
  wavePlayer.pause(true);

  // add inputs to gain and ac
  masterGain.addInput(filter);
  masterGain.addInput(reverb);
  masterGain.addInput(cadenceTick);
  masterGain.addInput(heartRateBeep);
  masterGain.addInput(stepImpactIntensity);
  masterGain.addInput(strideLengthSynth);

  ac.out.addInput(masterGain);
  ac.out.addInput(simulatorStart);
  ac.out.addInput(toggle);
  ac.out.addInput(unToggle);
  ac.out.addInput(cadenceTick);
  ac.out.addInput(heartRateBeep);
  ac.out.addInput(stepImpactIntensity);
  ac.out.addInput(strideLengthSynth);
  ac.out.addInput(wavePlayer);

  // User Interface
  ConstructUI();
  ac.start();
}

// controls overall volume of audio sonifications
public void MasterGainSlider(float value) {
  masterGainGlide.setValue(value/100);
}

public void StepImpactSlider(float value) {
  wavePlayer.setFrequency(value/60);
  filter.setFrequency(value/500);
}

// control frequency of runner cadence
public void SetTargetCadence(float value) {
  cadenceGlide.setValue(value/60.0f); // SPM
  // note; have stepImpact be its own method, dont augment it with cadence.
  // stepImpactGlide.setValue(value/30.0f); // SPM
}

// control frequency of runner heart rate
public void SetTargetHeartRate(float value) {
  heartRateGlide.setValue(value/60.0f); // BPM
}

// value -> number in seconds
public void setTargetPace(float value) {
  paceGlide.setValue(value/60.0f); //output in minutes per mile;
}

// stride length (feet) =  velocity / (cadence/60)
public void setStrideLength() {
  velocity = 60.0f/paceSlider.getValue() * 60;
  StrideLengthValue = velocity / (cadenceKnob.getValue()/60);
  // a function of velocity, pace, and cadence in feet
  strideLengthGlide.setValue(1/(StrideLengthValue/2.5)); // arbitrary value
}

public String getStepImpactIntensity() {
  if (!enableStepImpact && stepImpactSlider.getValue() < 4000) {
    return "Forceful";
  } else if (!enableStepImpact && stepImpactSlider.getValue() >= 4000 &&
    stepImpactSlider.getValue() <= 10000) {
    return "Moderate";
  } else if (!enableStepImpact && stepImpactSlider.getValue() > 10000) {
    return "Light";
  } else {
    return "N/A";
  }
}

public void toggleCadence() {
  enableCadence = !enableCadence;
  if (!enableCadence) {
    toggle.start(0);
    cadenceTick.pause(false);
  } else {
    unToggle.start(0);
    cadenceTick.pause(true);
  }
}

public void toggleHeartRate() {
  enableHeartRate = !enableHeartRate;
  if (!enableHeartRate) {
    toggle.start(0);
    heartRateBeep.pause(false);
  } else {
    unToggle.start(0);
    heartRateBeep.pause(true);
  }
}

public void toggleStrideLength() {
  if (enableStrideLength) {
    toggle.start(0);
    strideLengthSynth.pause(false);
  } else {
    unToggle.start(0);
    strideLengthSynth.pause(true);
  }
  enableStrideLength = !enableStrideLength;
}

public void toggleGPS() {
  if (enableGPS) {
    toggle.start(0);
    ttsExamplePlayback("GPS Enabled");
  } else {
    unToggle.start(0);
    ttsExamplePlayback("GPS Disabled");
  }
  enableGPS = !enableGPS;
}

public void recommendNavigation() {
  if (enableGPS) {
    ttsExamplePlayback("Please enable GPS First");
  } else {
    toggle.start(0);
    ttsExamplePlayback("Start at Georgia Institute of Technology, North Avenue North West." +
      "Then make a left onto Techwood Drive North West.Area is high traffic and construction." +
      "Please proceed with caution of vehicles and other obstacles on the sidewalk.");
  }
}

// uses wavePlayer to generate sine wave
// low frequency indicating forceful, high frequency indicating light
public void toggleStepImpact() {
  if (enableStepImpact) {
    toggle.start(0);
    wavePlayer.start();
  } else {
    unToggle.start(0);
    wavePlayer.pause(true);
  }
  enableStepImpact = !enableStepImpact;
}

// reset all sonfications
public void resetAll() {
  unToggle.start(0);
  cadenceTick.pause(true);
  enableCadence = !enableCadence;
  heartRateBeep.pause(true);
  enableHeartRate = !enableHeartRate;
  stepImpactIntensity.pause(true);
  enableStepImpact = !enableStepImpact;
  strideLengthSynth.pause(true);
  enableStrideLength = !enableStrideLength;
}

public void setFilter() {
  if (toggleLowPassFilter() == true) {
    masterGainGlide.setValue(filterGlide.getValue() * 1000);
  }
}

public boolean toggleLowPassFilter() {
  if (toggleFilter == true) {
    toggle.start(0);
    toggleFilter = !toggleFilter;
    return toggleFilter;
  } else {
    unToggle.start(0);
    toggleFilter = !toggleFilter;
    return toggleFilter;
  }
}

// gradualy change cadence value using linear interpolation
public void heartRateCheck() {
  // Heart Rate too high -> Lower Target Cadence until heart rate reaches healthy level
  if (heartRateKnob.getValue() > 185) {
    heartRateKnob.setColorForeground(color(255, 0, 100));
    heartRateKnob.setColorActive(color(255, 0, 100));
    heartRateStatus = "Too High";
  } else {
    heartRateKnob.setColorForeground(color(100, 200, 100));
    heartRateKnob.setColorActive(color(100, 255, 100));
    heartRateStatus = "Stable";
  }
  if (heartRateKnob.getValue() > 185) {
    float value = lerp((float)cadenceKnob.getValue(), 120.0, 0.002);
    cadenceKnob.setValue(value);
  }
}

public void ConstructUI() {
  p5.addButton("toggleCadence")
    .setSize(150, 30)
    .setLabel("Toggle Cadence")
    .setPosition(30, 330)
    .setColorForeground(color(255, 0, 100))
    .setColorBackground(color(120, 0, 50))
    .setColorActive(color(255, 0, 100))
    .activateBy((ControlP5.RELEASE));

  p5.addButton("toggleHeartRate")
    .setSize(150, 30)
    .setLabel("Toggle Heart Rate")
    .setPosition(30, 370)
    .setColorForeground(color(255, 0, 100))
    .setColorBackground(color(120, 0, 50))
    .setColorActive(color(255, 0, 100))
    .activateBy((ControlP5.RELEASE));

  p5.addButton("toggleStrideLength")
    .setSize(150, 30)
    .setLabel("Toggle Stride Length")
    .setPosition(30, 410)
    .setColorForeground(color(255, 0, 100))
    .setColorBackground(color(120, 0, 50))
    .setColorActive(color(255, 0, 100))
    .activateBy((ControlP5.RELEASE));

  p5.addButton("toggleStepImpact")
    .setSize(150, 30)
    .setLabel("Toggle Step Impact")
    .setPosition(30, 450)
    .setColorForeground(color(255, 0, 100))
    .setColorBackground(color(120, 0, 50))
    .setColorActive(color(255, 0, 100))
    .activateBy((ControlP5.RELEASE));

  p5.addButton("toggleGPS")
    .setSize(150, 30)
    .setLabel("Toggle GPS")
    .setPosition(30, 490)
    .setColorForeground(color(255, 0, 100))
    .setColorBackground(color(120, 0, 50))
    .setColorActive(color(255, 0, 100))
    .activateBy((ControlP5.RELEASE));

  p5.addButton("resetAll")
    .setLabel("Reset Sonifications")
    .setSize(150, 30)
    .setPosition(30, 530)
    .setColorForeground(color(255, 0, 100))
    .setColorBackground(color(120, 0, 50))
    .setColorActive(color(255, 0, 100))
    .activateBy((ControlP5.RELEASE));
    
  p5.addButton("toggleDemo")
    .setLabel("Toggle Demo")
    .setSize(150, 15)
    .setPosition(width/2 + 20, 550)
    .setColorForeground(color(255, 0, 100))
    .setColorBackground(color(120, 0, 50))
    .setColorActive(color(255, 0, 100))
    .activateBy((ControlP5.RELEASE));
  

  p5.addButton("recommendNavigation")
    .setLabel("Suggest Route Guidance")
    .setSize(250, 20)
    .setPosition(width/2 + 120, 275)
    .setColorForeground(color(255, 0, 100))
    .setColorBackground(color(120, 0, 50))
    .setColorActive(color(255, 0, 100))
    .activateBy((ControlP5.RELEASE));

  p5.addSlider("MasterGainSlider")
    .setValue(20)
    .setSize(30, 230)
    .setLabel("Master Gain")
    .setPosition(200, 330)
    .setColorForeground(color(255, 0, 100))
    .setColorBackground(color(120, 0, 50))
    .setColorActive(color(255, 0, 100));

  stepImpactSlider = p5.addSlider("StepImpactSlider")
    .setValue(2500)
    .setSize(30, 230)
    .setRange(10, 20000)
    .setLabel("Step Impact")
    .setPosition(330, 330)
    .setColorForeground(color(255, 0, 100))
    .setColorBackground(color(120, 0, 50))
    .setColorActive(color(255, 0, 100));

  paceSlider = p5.addSlider("paceSlider")
    .setSize(30, 230)
    .setRange(1500, 200)
    .setValue(500)
    .setLabel("Target Pace")
    .setPosition(265, 330)
    .setColorForeground(color(255, 0, 100))
    .setColorBackground(color(120, 0, 50))
    .setColorActive(color(255, 0, 100));

  // controls frequency of both cadence (SPM) and step impact intensity.
  cadenceKnob = p5.addKnob("SetTargetCadence")
    .setViewStyle(Knob.ARC)
    .setColorForeground(color(150, 0, 60))
    .setColorActive(color(255, 0, 100))
    .setColorBackground(color(90, 0, 30))
    .setNumberOfTickMarks(15)
    .setTickMarkLength(4)
    .snapToTickMarks(false)
    .setDragDirection(Slider.VERTICAL)
    .setPosition(55, 50)
    .setRadius(100)
    .setAngleRange(2*PI) // radians
    .setRange(120, 220)
    .setValue(140)
    .setLabel("Target Cadence")
    .plugTo(this, "SetTargetCadence");

  // controls frequency of heart rate (BPM)
  heartRateKnob = p5.addKnob("SetTargetHeartRate")
    .setViewStyle(Knob.ARC)
    .setColorForeground(color(255, 0, 100))
    .setColorActive(color(0, 200, 150))
    .setColorBackground(color(90, 0, 30))
    .setNumberOfTickMarks(15)
    .setTickMarkLength(4)
    .setDragDirection(Slider.VERTICAL)
    .setPosition(280, 50)
    .setRadius(100)
    .setAngleRange(2*PI) // radians
    .setRange(60, 200)
    .setValue(100)
    .setLabel("Target Heart Rate");

  // replace with GPS
}

// UI Geometry and Function Calls
void draw() {
  
  frameRate(framerate);
  
  // function calls
  if (cadenceKnob.getValue() >= 150 && heartRateKnob.getValue() >= 150.0) {
    if (cadenceAlert) {
      ttsExamplePlayback("Remember to inhale deeply and exhale fully");
      // maybe play a breathing pattern using samplePlayer
      cadenceAlert = false;
    } else {
      // otherwise pause the breathing pattern, and/or suggest a slower one
    }
  }
  heartRateCheck();
  if (heartRateKnob.getValue() >= 185) {
    if (heartRateAlert) {
      ttsExamplePlayback("Heart rate too high, lowering target cadence");
      heartRateAlert = false;
    }
    if (heartRateAlert == false && heartRateKnob.getValue() < 160) {
      ttsExamplePlayback("Heart rate now stable");
    }
  }
  setStrideLength();

  // UI Geometry/Data Visual
  background(color(20, 20, 20));

  fill(40, 40, 40);
  rect(10, height/2, 780, 290);
  rect(10, height/2, 385, 290);
  rect(width/2 + 120, 20, 250, 250);
  image(Navigation, width/2 + 130, 30, 230, 230);

  fill (20, 20, 20);
  rect(width/2 + 10, height/2 + 30, 370, 240);

  fill(255);
  textSize(15);
  text("Sonification Toggles", 30, height/2 + 20);
  text("Sensor Data", width/2 + 10, height/2 + 20);
  text("Current Cadence (SPM) - " + (int)cadenceKnob.getValue(), width/2 + 20, height/2 + 60);
  text("Current Heart Rate (BPM) - " + (int)heartRateKnob.getValue(), width/2 + 20, height/2 + 90);
  text("Step Impact Intensity - ", width/2 + 20, height/2 + 120);
  text("Stride length (feet) - " + String.format("%.02f", StrideLengthValue), width/2 + 20, height/2 + 150);
  text("Velocity (miles/hour) - " + String.format("%.02f", velocity), width/2 + 20, height/2 + 180);
  text("Pace (minutes/mile) - " + String.format("%.02f", paceSlider.getValue()/60.0f), width/2 + 20, height/2 + 210);

  // UI extras
  if (heartRateKnob.getValue() > 185) {
    fill(255, 0, 0);
    text(heartRateStatus, width/2 + 215, height/2 + 90);
  } else {
    fill(0, 255, 0);
    text(heartRateStatus, width/2 + 215, height/2 + 90);
  }

  stepImpactI = getStepImpactIntensity();
  if (stepImpactI == "Light") {
    fill(0, 120, 255);
    text(stepImpactI, width/2 + 165, height/2 + 120);
  } else if (stepImpactI == "Moderate") {
    fill(0, 255, 0);
    text(stepImpactI, width/2 + 165, height/2 + 120);
  } else if (stepImpactI == "Forceful") {
    fill(255, 0, 0);
    text(stepImpactI, width/2 + 165, height/2 + 120);
  } else {
    fill(255);
    text(stepImpactI, width/2 + 165, height/2 + 120);
  }
  
    
  if (toggleDemoCondition) { 
    if (frameCount < cadenceData.size()) {
      JSONObject cadenceObject = cadenceData.getJSONObject(frameCount);
      if (cadenceObject != null && cadenceObject.hasKey("cadence")) {
        float cadence = cadenceObject.getFloat("cadence");
        cadenceKnob.setValue(cadence);
      }
    } if (frameCount < heartRateData.size()) {
      JSONObject hrObject = heartRateData.getJSONObject(frameCount);
      if (hrObject != null && hrObject.hasKey("heart_rate")) {
        float hr = hrObject.getFloat("heart_rate");
        heartRateKnob.setValue(hr);
      }
    }
    frameCount++;
  }
}

public void toggleDemo() {
  if (!toggleDemoCondition) {
    toggle.start(0);
    ttsExamplePlayback("Loading J-SON Data");
    toggleDemoCondition = !toggleDemoCondition;
    framerate = 1;
    frameCount = 0;
  } else {
    unToggle.start(0);
    ttsExamplePlayback("Interactive Mode");
    toggleDemoCondition = !toggleDemoCondition;
    framerate = 1000;
    frameCount = 0;
  }
  
}

public Bead endListener() {
  Bead endListener = new Bead() {
    public void messageReceived(Bead message) {
      SamplePlayer sp = (SamplePlayer) message;
      cadenceGlide.setValue(0);
      heartRateGlide.setValue(0);
      sp.pause(true);
    }
  };
  return endListener;
}

// Text to Speech Requirement
void ttsExamplePlayback(String inputSpeech) {
  //create TTS file and play it back immediately
  //the SamplePlayer will remove itself when it is finished in this case
  String ttsFilePath = ttsMaker.createTTSWavFile(inputSpeech);
  println("File created at " + ttsFilePath);

  //createTTSWavFile makes a new WAV file of name ttsX.wav, where X is a unique integer
  //it returns the path relative to the sketch's data directory to the wav file

  //see helper_functions.pde for actual loading of the WAV file into a SamplePlayer
  SamplePlayer sp = getSamplePlayer(ttsFilePath, true);
  //true means it will delete itself when it is finished playing
  //you may or may not want this behavior!

  ac.out.addInput(sp);
  sp.setToLoopStart();
  sp.start();
  println("TTS: " + inputSpeech);
}
