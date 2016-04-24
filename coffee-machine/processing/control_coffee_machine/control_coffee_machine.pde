//Simple script to use GPIO of Onion Omega as simple switch (i.e. on or off)
//Uses the serial inteface

//This script was used to control a basic coffee machine

import processing.serial.*;
import java.util.Map;

//board + interface config
Serial serialPort;
int gpioNumber = 26;
boolean machineOn = false;
String driverPath = "/dev/tty.SLAB_USBtoUART"; //OSX config
int baudRate = 115200;

//on/off visuals
int[] offColor = {245, 64, 178};
int[] onColor = {118, 245, 64};
int[] currentColor = offColor;
int[] buttonDimensions = {25, 25, 50, 50};

void setup(){
  //setupOnion
  serialPort = new Serial(this, driverPath, baudRate);
  
  try{
    executeCommand(GPIOSetOutput(gpioNumber), serialPort);
    executeCommand(GPIOSetOff(gpioNumber), serialPort); //make sure it is turned off
  }
  catch(Exception e){
   println(e);
   exit();
 }
  println("Board inited");
}

void draw(){
  //draws rectangular botton
  fill(currentColor[0], currentColor[1], currentColor[2]);
  rect(buttonDimensions[0], buttonDimensions[1], buttonDimensions[2], buttonDimensions[3]);
}

void mouseClicked() {
  try{
    println("Clicked the switch!");
    
    if(machineOn){
      executeCommand(GPIOSetOff(gpioNumber),serialPort);
      machineOn = false;
      println("Let's hope machine is OFF now....");
      currentColor = offColor;
      return;
    }
    
    executeCommand(GPIOSetOn(gpioNumber),serialPort);
    println("Let's hope machine is ON....");
    currentColor = onColor;
    machineOn = true;
 }
 
 catch(Exception e){
   println(e);
   exit();
 }
}

HashMap<String, String> GPIOSetOutput(int gpioNumber){
  HashMap<String,String> hm = new HashMap<String,String>();
  hm.put("cmd", "fast-gpio set-output "+ str(gpioNumber));
  hm.put("expected", "> Set direction GPIO" + str(gpioNumber) + ": output");
  return hm;
}

HashMap<String, String> GPIOSetOn(int gpioNumber){
  HashMap<String,String> hm = new HashMap<String,String>();
  hm.put("cmd", "fast-gpio set "+ str(gpioNumber) +" 1");
  hm.put("expected", "> Set GPIO" + str(gpioNumber) + ": 1");
  return hm;
}

HashMap<String, String> GPIOSetOff(int gpioNumber){
  HashMap<String,String> hm = new HashMap<String,String>();
  hm.put("cmd", "fast-gpio set "+ str(gpioNumber) +" 0");
  hm.put("expected", "> Set GPIO" + str(gpioNumber) + ": 0");
  return hm;
}

void executeCommand(HashMap<String, String> command, Serial port) throws Exception{
  int[] asciiCommand = int( command.get("cmd").toCharArray());
  int maxAttempts = 5; //no fancy logic here, just blunt pushing of command, no idea whether sterror can be read or so
  
  for(int attempt=0; attempt < maxAttempts; attempt++){ 
    //send command
    for (int i=0; i < asciiCommand.length; i++) {
      port.write(asciiCommand[i]);
    }
    //ascii 13  == carriage return -> execute
    port.write(13);
    
    println("waiting a 1 sec for board to respond");
    delay(1000);
    
    if(isResponseOk(port, command.get("expected"))){
      return;
    }
    println("Next attempt " + str(attempt));
  }
  println("UHOH did not expect to arrive here....");
  throw new Exception("Failed to execute command, unplug device, go hide!!");
}

boolean isResponseOk(Serial port, String expected){
  while (port.available() > 0) {
    String inBuffer = port.readString();   
    if (inBuffer != null) {
      println(inBuffer);
      String[] match = match(inBuffer, expected);
      if(match != null){
        return true;
      }
    }
  }
  return false;
}