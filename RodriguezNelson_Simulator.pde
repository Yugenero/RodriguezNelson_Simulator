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
SamplePlayer toggle;
SamplePlayer unToggle;
SamplePlayer cadenceTick;
SamplePlayer heartRateBeep;

Knob cadenceKnob;
Knob heartRateKnob;

float targetCadence;
float targetHeartRate;
float tempo;
float StepImpactValue;
float StrideLengthValue;
float increment = 0.01;

boolean enableCadence = true;
boolean enableHeartRate = true;

Button Cadence;
Button StepImpact;
Button HeartRate;
Button StrideLength;
Button Navigation;

Slider targetCadenceSlider;

Glide masterGainGlide;
Glide cadenceGlide;
Glide heartRateGlide;
Glide filterGlide;

Gain masterGain;

BiquadFilter bqFilter;

String eventJSON1 = "Cadence.json";
String eventJSON2 = "Heart_Rate.json";
String eventJSON3 = "Step_Impact.json";
String NavigationTTS;

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
  toggle.pause(true);
  unToggle.pause(true);
  cadenceTick.pause(true);
  heartRateBeep.pause(true);

  cadenceData = loadJSONArray("Cadence.json"); // retrive cadence from JSON array
  cadenceTick.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
  heartRateBeep.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
 
  // Volume properties
  masterGainGlide = new Glide(ac, 1.0, 500);
  masterGain = new Gain(ac, 1, masterGainGlide);
  
  cadenceGlide = new Glide(ac, 1.0, 10);
  cadenceTick.setRate(cadenceGlide);
  
  heartRateGlide = new Glide(ac, 1.0, 10);
  heartRateBeep.setRate(heartRateGlide);
  
  // low pass filter
  filterGlide = new Glide(ac, 10.0, 0.5f);
  bqFilter = new BiquadFilter(ac, BiquadFilter.LP, filterGlide, 0.5f);
  
  ttsMaker = new TextToSpeechMaker();
  ttsExamplePlayback("can you marry someone whos the person you didnt have do not when was before love its cannot be there by you wasnt go for itbecause then what would you do if when you okay when she would go"); //see ttsExamplePlayback below for usage
  
  // add inputs to gain and ac
  masterGain.addInput(bqFilter);
  masterGain.addInput(cadenceTick);  
  masterGain.addInput(heartRateBeep);
  
  ac.out.addInput(masterGain);
  ac.out.addInput(toggle);
  ac.out.addInput(unToggle);
  ac.out.addInput(cadenceTick);
  ac.out.addInput(heartRateBeep);
  
  // User Interface
  ConstructUI();
  
  ac.start();
}

// controls overall volume of audio sonifications
public void MasterGainSlider(float value) {
  masterGainGlide.setValue(value/100);
}

public void SetTargetCadence(float value) {  
  tempo = 60.0f;
  cadenceGlide.setValue(value/60.0f); // SPM
}

public void SetTargetHeartRate(float value) {
  heartRateGlide.setValue(value/60.0f); // BPM
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

// reset all sonfications
public void resetAll() {
  unToggle.start(0);
  if (!enableCadence) {
      cadenceTick.pause(false);
      enableCadence = !enableCadence;
  } if (!enableHeartRate) {
    heartRateBeep.pause(true);
    enableHeartRate = !enableHeartRate;
  }
}

// gradualy change cadence value using linear interpolation
public void heartRateCheck() {
  // Heart Rate too high -> Lower Target Cadence until heart rate reaches healthy level
  if (heartRateKnob.getValue() > 185) { 
    heartRateKnob.setColorForeground(color(255, 0, 100));
    heartRateKnob.setColorActive(color(255, 0, 100)); 
  } else { 
    heartRateKnob.setColorForeground(color(0, 200, 150));
    heartRateKnob.setColorActive(color(0, 200, 150));
  }
  if (heartRateKnob.getValue() > 185 && !enableHeartRate) {
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
    
  p5.addButton("StrideLength")
    .setSize(150, 30)
    .setLabel("Toggle Stride Length")
    .setPosition(50, 410)
    .setColorForeground(color(255, 0, 100))
    .setColorBackground(color(120, 0, 50))
    .setColorActive(color(255, 0, 100))
    .activateBy((ControlP5.RELEASE));
   
  p5.addButton("StepImpact")
    .setSize(150, 30)
    .setLabel("Toggle Step Impact")
    .setPosition(50, 450)
    .setColorForeground(color(255, 0, 100))
    .setColorBackground(color(120, 0, 50))
    .setColorActive(color(255, 0, 100))
    .activateBy((ControlP5.RELEASE));
    
  p5.addButton("Navigation")
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
       
  cadenceKnob = p5.addKnob("SetTargetCadence")
    .setViewStyle(Knob.ARC)
    .setColorForeground(color(0, 200, 150))
    .setColorActive(color(0, 200, 150))
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
    .setValue(140)
    .setLabel("Set Target Heart Rate");
    
  /*p5.addKnob("test2")
    .setViewStyle(Knob.ELLIPSE)
    .setNumberOfTickMarks(15)
    .setDragDirection(10)
    .setPosition(525, 50)
    .setRadius(100)
    .setAngleRange(2*PI)
    .setRange(100, 200)
    .setValue(140)
    .setLabel("Set Target Heart Rate");*/
}

// UI Geometry and Function Calls
void draw() {

  
  // function calls
  heartRateCheck();
 
  // UI Geometry
  background(color(20, 20, 20));
  
  fill(40, 40, 40);
  rect(10, height/2, 780, 290);
  
  fill (20, 20, 20);
  rect(width/2, height/2 + 30, 370, 230);
  
  fill(255); 
  textSize(15);
  text("Sonification Toggles", 50, height/2 + 20);
  text("Physical Performance Data ", width/2 + 10, height/2 + 20);
  text("Current Cadence (SPM) - " + (int)cadenceKnob.getValue(), width/2 + 20, height/2 + 60);
  text("Current Heart Rate (BPM) - " + (int)heartRateKnob.getValue(), width/2 + 20, height/2 + 90);
  
   
  // fill(0, 200, 200);
  // circle(width/2, 150, 203);
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
