import processing.serial.*;
PFont font; // instanciation de la fonte
PrintWriter database;

/*arduino information*/
Serial port;   
String portname = "/dev/cu.usbmodem1411"; // attention le nom dépend de l'ordinateur utilisé

void setup() {
  size(400,300); // définition de la surface de travail
  port = new Serial(this, portname, 9600);
  port.clear();
  background(0);
  frameRate(10); // taux de traitement par seconde
  
  // ouvrir le fichier qui sert de database pour en copier le contenu afin de pouvoir le repalancer dans le fichier qui sera écrasé.
  // problème, au bout d'un moment ça prend de la mémoire. il faut trouver un moyen de jouer avec deux fichiers.
  // donc pour palier ça on a deux copies de la base : database.txt et database_copy.txt et à la fin on écrit tout dans les deux :
  // mais on fera ça plus tard.
  String dbContent[] = loadStrings("../../database.txt");
  database = createWriter("../../database.txt");
  if(dbContent.length > 0){
    for(int i = 0 ; i < dbContent.length ; i++){
      database.println(dbContent[i]);
      database.flush();
    } 
  }
}


void draw() {
  
  if(keyPressed) { // si une touche a été pressée
  //envoyer la valeur de la touche à arduino
  port.write(key); 
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
  
  port.clear();// sécurité pour être sûr que le buffer est vide
  // on écrit dans la base de données
  String s = "" + key ;
  for(int i = 0 ; i < dataLength ; i++) s += ":" + answer[i] ;
  database.println(s);
  database.flush();
  
  // pour le debug
  background(0);
  String s_dbg = "data length : " + dataLength + "\n key : " + key + "\n data :";
  for(int i = 0 ; i < dataLength ; i++){
    s_dbg += "\n  " + answer[i] ;
    int h = 20+answer[i];
    rect(400 - 70 - 40*i, 20 + 255 - h, 20, h, 7);
  }
  s_dbg += "\n." ;
  text(s_dbg, 10, 30);
  
  
  
  }
}
