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
PImage Navigation;
SamplePlayer simulatorStart;
SamplePlayer toggle;
SamplePlayer unToggle;
SamplePlayer cadenceTick;
SamplePlayer heartRateBeep;
SamplePlayer stepImpactIntensity;
SamplePlayer strideLengthSynth;

Slider paceSlider;
Knob cadenceKnob;
Knob heartRateKnob;
Knob testKnob;

float targetCadence;
float targetHeartRate;
float targetPace;
float StepImpactValue;
float StrideLengthValue;
float velocity;
float increment = 0.01;

boolean enableCadence = true;
boolean enableHeartRate = true;
boolean enableStepImpact = true;
boolean enableStrideLength = true;
boolean enableGPS = true;
boolean cadenceAlert = true;
boolean heartRateAlert = true;
boolean stepImpactAlert = true;

Button Cadence;
Button StepImpact;
Button HeartRate;
Button StrideLength;

Glide masterGainGlide;
Glide cadenceGlide;
Glide heartRateGlide;
Glide stepImpactGlide;
Glide strideLengthGlide;
Glide paceGlide;
Glide filterGlide;

Gain masterGain;

BiquadFilter bqFilter;

String eventJSON1 = "Cadence.json";
String eventJSON2 = "Heart_Rate.json";
String eventJSON3 = "Step_Impact.json";
String NavigationTTS;
String heartRateStatus;


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

  cadenceData = loadJSONArray("Cadence.json"); // retrive cadence from JSON array
  cadenceTick.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
  heartRateBeep.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
  stepImpactIntensity.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
  strideLengthSynth.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);

  // Volume properties
  masterGainGlide = new Glide(ac, 1.0, 500);
  masterGain = new Gain(ac, 1, masterGainGlide);
  
  filterGlide = new Glide(ac, 10.0, 0.5f);
  bqFilter = new BiquadFilter(ac, BiquadFilter.LP, filterGlide, 0.5f);

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

  // add inputs to gain and ac
  masterGain.addInput(bqFilter);
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

  // User Interface
  ConstructUI();
  ac.start();
}

// controls overall volume of audio sonifications
public void MasterGainSlider(float value) {
  masterGainGlide.setValue(value/100);
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
  // play a tts maybe
  return "Forceful";
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

public void toggleStepImpact() {
  enableStepImpact = !enableStepImpact;
  if (!enableStepImpact) {
    toggle.start(0);
    // in order to avoid overwhelming user with redundant sonfication
    cadenceTick.pause(true); // researcher still has option to enable cadence through toggle;
    stepImpactIntensity.pause(false);
  } else {
    unToggle.start(0);
    stepImpactIntensity.pause(true);
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
    image(Navigation, width/2, height/2);
  } else {
    unToggle.start(0);
    ttsExamplePlayback("GPS Disabled");
  }
  enableGPS = !enableGPS;
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


// gradualy change cadence value using linear interpolation
public void heartRateCheck() {
  // Heart Rate too high -> Lower Target Cadence until heart rate reaches healthy level
  if (heartRateKnob.getValue() > 185) {
    heartRateKnob.setColorForeground(color(255, 0, 100));
    heartRateKnob.setColorActive(color(255, 0, 100));
    heartRateStatus = "Too High";
  } else {
    heartRateKnob.setColorForeground(color(100, 255, 100));
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
    .setPosition(50, 330)
    .setColorForeground(color(255, 0, 100))
    .setColorBackground(color(120, 0, 50))
    .setColorActive(color(255, 0, 100))
    .activateBy((ControlP5.RELEASE));

  p5.addButton("toggleHeartRate")
    .setSize(150, 30)
    .setLabel("Toggle Heart Rate")
    .setPosition(50, 370)
    .setColorForeground(color(255, 0, 100))
    .setColorBackground(color(120, 0, 50))
    .setColorActive(color(255, 0, 100))
    .activateBy((ControlP5.RELEASE));

  p5.addButton("toggleStrideLength")
    .setSize(150, 30)
    .setLabel("Toggle Stride Length")
    .setPosition(50, 410)
    .setColorForeground(color(255, 0, 100))
    .setColorBackground(color(120, 0, 50))
    .setColorActive(color(255, 0, 100))
    .activateBy((ControlP5.RELEASE));

  p5.addButton("toggleStepImpact")
    .setSize(150, 30)
    .setLabel("Toggle Step Impact")
    .setPosition(50, 450)
    .setColorForeground(color(255, 0, 100))
    .setColorBackground(color(120, 0, 50))
    .setColorActive(color(255, 0, 100))
    .activateBy((ControlP5.RELEASE));

  p5.addButton("toggleGPS")
    .setSize(150, 30)
    .setLabel("Toggle GPS")
    .setPosition(50, 490)
    .setColorForeground(color(255, 0, 100))
    .setColorBackground(color(120, 0, 50))
    .setColorActive(color(255, 0, 100))
    .activateBy((ControlP5.RELEASE));


  p5.addButton("resetAll")
    .setLabel("Reset Sonifications")
    .setSize(150, 30)
    .setPosition(50, 530)
    .setColorForeground(color(255, 0, 100))
    .setColorBackground(color(120, 0, 50))
    .setColorActive(color(255, 0, 100))
    .activateBy((ControlP5.RELEASE));

  p5.addSlider("MasterGainSlider")
    .setValue(20)
    .setSize(30, 230)
    .setLabel("Master Gain")
    .setPosition(225, 325)
    .setColorForeground(color(255, 0, 100))
    .setColorBackground(color(120, 0, 50))
    .setColorActive(color(255, 0, 100));
    
  // add low pass filter slider here.
    
  paceSlider = p5.addSlider("paceSlider")
    .setSize(30, 230)
    .setRange(1500, 200)
    .setValue(500)
    .setLabel("Target Pace")
    .setPosition(290, 325)
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
    .setPosition(75, 50)
    .setRadius(100)
    .setAngleRange(2*PI) // radians
    .setRange(120, 220)
    .setValue(140)
    .setLabel("Set Target Cadence")
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
    .setPosition(300, 50)
    .setRadius(100)
    .setAngleRange(2*PI) // radians
    .setRange(60, 200)
    .setValue(100)
    .setLabel("Set Target Heart Rate");

  // replace with GPS
}

// UI Geometry and Function Calls
void draw() {
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
  // UI Geometry
  background(color(20, 20, 20));

  fill(40, 40, 40);
  rect(10, height/2, 780, 290);
  rect(10, height/2, 370, 290);
  // rect(width/2 + 100, 10, 370, 290);

  fill (20, 20, 20);
  rect(width/2, height/2 + 30, 370, 230);
  
  if (!enableGPS) {
      image(Navigation, width/2 + 130, 30, 230, 230);
  }


  fill(255);
  textSize(15);
  text("Sonification Toggles", 50, height/2 + 20);
  text("Physical Performance Data ", width/2 + 10, height/2 + 20);
  text("Current Cadence (SPM) - " + (int)cadenceKnob.getValue(), width/2 + 20, height/2 + 60);
  text("Current Heart Rate (BPM) - " + (int)heartRateKnob.getValue(), width/2 + 20, height/2 + 90);
  text("Step Impact Intensity - " + getStepImpactIntensity(), width/2 + 20, height/2 + 120);
  text("Stride length (feet) - " + String.format("%.02f", StrideLengthValue), width/2 + 20, height/2 + 150);
  text("Velocity (miles/hour) - " + String.format("%.02f", velocity), width/2 + 20, height/2 + 180);
  text("Pace (minutes/mile) - " + String.format("%.02f", paceSlider.getValue()/60.0f), width/2 + 20, height/2 + 210);

  if (heartRateKnob.getValue() > 185) {
    fill(255, 0, 0);
    text(heartRateStatus, width/2 + 215, height/2 + 90);
  } else {
    fill(0, 255, 0);
    text(heartRateStatus, width/2 + 215, height/2 + 90);
  }
}

public Bead endListener() {
  Bead endListener = new Bead() {
    public void messageReceived(Bead message) {
      SamplePlayer sp = (SamplePlayer) message;
      cadenceGlide.setValue(10.0);
      heartRateGlide.setValue(10.0);
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
