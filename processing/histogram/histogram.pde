import processing.serial.*;
PFont font; // instanciation de la fonte
char k;
boolean launched = false ;

/*arduino information*/
Serial port;   
String portname = "/dev/cu.usbmodem1411"; // attention le nom dépend de l'ordinateur utilisé

void setup() {
  size(1200,300); // définition de la surface de travail
  port = new Serial(this, portname, 9600);
  port.clear();
  background(0);
  frameRate(10); // taux de traitement par seconde
}


void draw() {
  
  
  if(!launched) {
    if(keyPressed){
      k = key;
      launched = true;
    }
  }
  else{
    //envoyer la valeur de la touche à arduino
    port.write(k); 
    int dataLength = 0;
    
    //attendre la première réponse qui sera l'info sur la taille du buffer
    boolean gotLengthInfo = false;
    
    while(!gotLengthInfo){// tant que l'information n'est pas reçue
      if(port.available() > 0){
        dataLength = port.read();
        gotLengthInfo = true;
      }
    }
    
    //création du tableau de bytes
    int[] answer = new int[dataLength];// le tableau lui-même
    int currentIndex = 0;//indice courant pour vérifier qu'on a bien lu toutes les données.
    // on est obligé de procéder comme ça car rien ne dit que le buffer est fini de remplir quand on commence à le lire. 
    // donc s'il a une pause, on ne veut pas que le le programme considère qu'il a fini le travail.
    // si on faisait while(port.available>0) et qu'on lit les données plus vite qu'on ne les reçoit, on finira par en rater à la fin
    
    while(currentIndex < dataLength){
      if(port.available() > 0){
        answer[currentIndex] = port.read();
        currentIndex++;  
      }
    }
    
    //port.clear();// sécurité pour être sûr que le buffer est vide
    
    // pour le debug
    background(0);
    for(int i = 0 ; i < dataLength ; i++){
      int h = 20+answer[i];
      rect(1200 - (1200/2 - 100) - 40*i, 20 + 255 - h, 20, h, 7);
    }
     
  } 
}
