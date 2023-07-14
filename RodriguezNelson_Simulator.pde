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
Clock metronome;

float CadenceValue;
float StepImpactValue;
float HeartRateValue;
float StrideLengthValue;
String NavigationTTS;

Button Cadence;
Button StepImpact;
Button HeartRate;
Button StrideLength;
Button Navigation;

Slider targetCadenceSlider;
Slider targetHeartRate;

Glide masterGainGlide;
Gain masterGain;

BiquadFilter bqFilter;
Glide filterGlide;

String eventJSON1 = "Cadence.json";
String eventJSON2 = "Heart_Rate.json";
String eventJSON3 = "Step_Impact.json";

NotificationServer server;
ArrayList<Notification> notifications;

// UI/Simulator Setup
void setup() {
  size(1000, 600);
  p5 = new ControlP5(this);
  ac = new AudioContext(); // defined in helper functions 
  
  /*ttsMaker = new TextToSpeechMaker();
  String exampleSpeech = "Text to speech is okay, I guess.";
  ttsExamplePlayback(exampleSpeech); //see ttsExamplePlayback below for usage*/

  masterGainGlide = new Glide(ac, 1.0, 200);
  masterGainGlide.setValue(0.5); // initial glide value
  masterGain = new Gain(ac, 1, masterGainGlide); // controls volume of audio signals
  
  // low pass filter
  filterGlide = new Glide(ac, 10.0, 0.5f);
  bqFilter = new BiquadFilter(ac, BiquadFilter.LP, filterGlide, 0.5f);
  
  masterGain.addInput(bqFilter);
  ac.out.addInput(masterGain);
  
  // User Interface
  p5.addButton("Cadence")
    .setSize(150, 30)
    .setLabel("Toggle Cadence")
    .setPosition(50, 325)
    .setColorForeground(color(0, 200, 200))
    .setColorBackground(color(0, 100, 200))
    .activateBy((ControlP5.RELEASE));
    
  p5.addButton("HeartRate")
    .setSize(150, 30)
    .setLabel("Toggle Heart Rate")
    .setPosition(50, 375)
    .setColorForeground(color(0, 200, 200))
    .setColorBackground(color(0, 100, 200))
    .activateBy((ControlP5.RELEASE));
    
  p5.addButton("StrideLength")
    .setSize(150, 30)
    .setLabel("Toggle Stride Length")
    .setPosition(50, 425)
    .setColorForeground(color(0, 200, 200))
    .setColorBackground(color(0, 100, 200))
    .activateBy((ControlP5.RELEASE));
   
  p5.addButton("StepImpact")
    .setSize(150, 30)
    .setLabel("Toggle Step Impact")
    .setPosition(50, 475)
    .setColorForeground(color(0, 200, 200))
    .setColorBackground(color(0, 100, 200))
    .activateBy((ControlP5.RELEASE));
    
  p5.addButton("Navigation")
    .setSize(150, 30)
    .setLabel("Toggle GPS")
    .setPosition(50, 525)
    .setColorForeground(color(0, 200, 200))
    .setColorBackground(color(0, 100, 200))
    .activateBy((ControlP5.RELEASE));
    
  p5.addSlider("MasterVolume")
    .setSize(30, 230)
    .setLabel("Master Gain")
    .setPosition(225, 325)
    .setRange(0, 100)
    .setColorForeground(color(0, 200, 200))
    .setColorBackground(color(0, 100, 200));
       
  p5.addKnob("knob")
    .setViewStyle(Knob.ELLIPSE)
    .setPosition(235, 100)
    .setRadius(60)
    .setAngleRange(PI*2)
    .setRange(100, 200)
    .setLabel("Set Target Cadence");
    
  ac.start();
}

// controls overall volume of audio sonifications
public void MasterVolume(float value) {
  masterGain.setValue(value/50);
}

// Text-To-Speech Functionality 
/*void ttsExamplePlayback(String inputSpeech) {
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
}*/

void draw() {
  // method should be here even if empty
  background(color(20, 20, 20));
  
  fill(40, 40, 40);
  rect(0, height/2, width, height/2);
}
