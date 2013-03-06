int dataSize = 5;
int data[5] = { 0, 0, 0, 0, 0 };
int lastChange[5] = { 0, 0, 0, 0, 0 };
int incomingByte = -1;/*pour savoir quelle lettre a été pressée*/
boolean changeDetected = false;


/*Min : {  355,  329,  315,  315,  308, } - Max : {  508,  526,  497,  530,  565, }*/
int Min[5] = {  355,  329,  315,  315,  308 };
int Max[5] = {  508,  526,  497,  530,  565 };

void setup() {
  Serial.begin(9600);
  Serial.flush();
  for(int ii = 0 ; ii < 10000; ii++){
    acquireData();
  }
}


void loop(){
  
 if(Serial.available() > 0) {
    //on reçoit les données une par une donc il ne doit y avoir qu'un seul byte à lire
    incomingByte = Serial.read();// pour flush le buffer
    
    while(!changeDetected){
      //acquérir les donnees
      acquireData();
      changeDetected = detectChange();
    }// arrivé là on a détecté un changement dans les datas,changeDetected vaut maintenant true;
    
    changeDetected = false;
    //on update lastChange
    updateLastChange();
     
    //on va faire des acquisitions jusqu'à ce que ça ne bouge plus trop
    int cpt = 0;
    while(cpt < 500){   
      acquireData();
      if(!detectChange()){
        cpt = 0;
      }
      else{
        cpt++;
      }
    }
    
    //maintenant on est sur d'avoir un état stable... plus qu'à tout envoyer (en updatant lastChange)
    updateLastChange();
    writeData();
  }
  
}

// fonction poru acquérir toutes les datas du gant
void acquireData(){
  for(int i = 0 ; i < dataSize ; i++){
    int tmp = analogRead(i);
    if(Min[i]>tmp) Min[i] = tmp;
    if(Max[i]<tmp) Max[i] = tmp;
    data[i] = map(tmp,Min[i]-10,Max[i]+10,0,255);
  }
}


// fonction pour détecter un changement significatif dans le mouvement
boolean detectChange(){
  int thresh = 50;
  for(int i = 0 ; i < dataSize ; i++){
    if(abs(data[i]-lastChange[i]) > thresh) return true;
  }
  
  return false;
}

//fontion pour update lastChange
void updateLastChange(){
  for(int i = 0 ; i < dataSize ; i++){
    lastChange[i] = data[i];
  }
}


// fonction pour écrire dans le buffer toutes les infos
void writeData(){
  // envoyer d'abord une information sur le nombre de bytes qui vont etre envoyés en plus de ce byte d'information
    Serial.write(dataSize);
  //boucler sur les datas 
  for(int i = 0 ; i < dataSize ; i++){
    Serial.write(data[i]);
  }
}

