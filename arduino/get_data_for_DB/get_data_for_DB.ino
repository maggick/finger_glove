int dataSize = 5;
int data[5] ;
int incomingByte = -1;/*pour savoir quelle lettre a été pressée*/

/*Min : {  355,  329,  315,  315,  308, } - Max : {  508,  526,  497,  530,  565, }*/
int Min[5] = {  355,  329,  315,  315,  308 };
int Max[5] = {  508,  526,  497,  530,  565 };


void setup() {
  Serial.begin(9600);
  Serial.flush();
  
  //initialisation des datas à 0
  for(int i = 0 ; i < dataSize ; i++){
    data[i] = i+5;
  }
}


void loop(){
  
 if(Serial.available() > 0) {
    //on reçoit les données une par une donc il ne doit y avoir qu'un seul byte à lire
    incomingByte = Serial.read();
    
    // envoyer d'abord une information sur le nombre de bytes qui vont etre envoyés en plus ce ce byte d'information
    Serial.write(dataSize);
    
    // envoyer des bytes un par un
    for(int i = 0 ; i < dataSize ; i++){
      data[i] = map(analogRead(i),Min[i]-10,Max[i]+10,0,255);
      Serial.write(data[i]);
    }
  }
  
}


