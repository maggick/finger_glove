int dataSize = 5;
int min[5] = {999,999,999,999,999};
int max[5] = {0,0,0,0,0};
int currentVal = 0;
String currentMin= "", currentMax = "", currentValues = "";

void setup() {
  Serial.begin(9600);
  Serial.flush();
}

void loop(){
  
  currentMin = "Min : { ";
  currentMax = "Max : { ";
  currentValues = "current : { ";
  
  for(int i = 0 ; i < dataSize ; i++){
    currentVal = (int) analogRead(i);
    if(currentVal < min[i]){
      min[i] = currentVal;
    }
    if(currentVal > max[i]){
      max[i] = currentVal;
    }
    
    currentMin = currentMin + " " + min[i] + ", " ;
    currentMax = currentMax + " " + max[i] + ", " ;
    currentValues = currentValues + " " + currentVal + ", " ; 
  }
  
  //currentMin -= ", ";
  currentMin = currentMin + "}";
  //currentMax -= ", ";
  currentMax = currentMax + "}";
  currentValues = currentValues + "}";
  
  
  
  Serial.println(currentMin + " - " + currentMax + " - " + currentValues);
}
