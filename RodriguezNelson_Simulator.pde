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
SamplePlayer tickSound;

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
  ac = new AudioContext(); // defined in helper functions; created using Beads library
  
  cadenceData = loadJSONArray("Cadence.json"); // retrive cadence from JSON array
  tickSound = getSamplePlayer("Cadence.mp3");
  tickSound.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);

  // Volume properties
  masterGainGlide = new Glide(ac, 1.0, 500);
  masterGain = new Gain(ac, 1, masterGainGlide);
  
  // low pass filter
  filterGlide = new Glide(ac, 10.0, 0.5f);
  bqFilter = new BiquadFilter(ac, BiquadFilter.LP, filterGlide, 0.5f);
  
  // add inputs to master gain
  masterGain.addInput(bqFilter);
  masterGain.addInput(tickSound);  
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
    
  p5.addSlider("MasterGainSlider")
    .setSize(30, 230)
    .setLabel("Master Gain")
    .setPosition(225, 325)
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
public void MasterGainSlider(float value) {
  masterGain.setValue(value);
}

void draw() {
  background(color(20, 20, 20));
  fill(40, 40, 40);
  rect(0, height/2, width, height/2);
 
}
