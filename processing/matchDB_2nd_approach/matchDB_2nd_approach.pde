import processing.serial.*;
PFont font; // instanciation de la font
char k;
boolean start = false ;
String sentence = "";
String lastLetter = "";
String currentLetter = "";

/*variables utiles*/
int[] data = {0,0,0,0,0};// là où on va récupérer les données du gant à chaque boucle
int[] lastStableData = {0,0,0,0,0};// là où sont stockées les données du la dernière acquisition stable (pour détecter s'il y a besoin de faire un traitement)
int[] avgStableData = {0,0,0,0,0};// là où est stockée la somme des données stables enregistrées. la moyenne est calculée juste avant le matching
int stabilityCounter = 1;// décompte du nombre de mesures consécutives stables. commence à zéro car on a la première.
boolean freeze = true;// pour détecter qu'il y a bien une activité : si on reste pendant très longtemps sur une position, on ne veut pas avoir la lettre 36 fois. 
// une solution est de ne pas afficher la lettre si elle est la même que la dernière lettre, mais avec ça ça empêche les doubles lettres...
// pour une double lettre, on fait furtivement un mouvement quelconque ui va débloquer la situation et on réeffectue le signe de la lettre.
final int STABILITY_COUNTER_THRESH = 10;// limite de mesures stables avant de décider de faire la comparaison
final int STABILITY_DISTANCE_THRESH = 20;//limite de distance à partir de laquelle on considère qu'un mouvement a changé significativement;

/* données d'affichage*/
final int W_HEIGHT = 450;// 16:9
final int W_WIDTH = 800;
final int HIST_BAR_WIDTH = 40;
final int HIST_BAR_MAX_HEIGHT = 100;
final int HIST_BAR_MIN_HEIGHT = 10;
final int MARGIN = 20;
final color ORANGE = color(204,102,0);
final color RED = color(205,0,0);
final color GREEN = color(0,205,0);
final color WHITE = color(255,255,255);
final color BLACK = color(0,0,0);

/*arduino information*/
Serial port;   
String portname = "/dev/cu.usbmodem1411"; // attention le nom dépend de l'ordinateur utilisé

// créer les variables
//ArrayList database = new ArrayList(); // pas de hashmap ici pour pouvoir le parcourir facilement
HashMap database;

// définir l"alphabet
/*HashMap alphabet = new HashMap();
alphabet.put("a",0);
alphabet.put("b",1);
alphabet.put("c",2);
alphabet.put("d",3);
alphabet.put("e",4);
alphabet.put("f",5);
alphabet.put("g",6);
alphabet.put("h",7);
alphabet.put("i",8);
alphabet.put("j",9);
alphabet.put("k",10);
alphabet.put("l",11);
alphabet.put("m",12);
alphabet.put("n",13);
alphabet.put("o",14);
alphabet.put("p",15);
alphabet.put("q",16);
alphabet.put("r",17);
alphabet.put("s",18);
alphabet.put("t",19);
alphabet.put("u",20);
alphabet.put("v",21);
alphabet.put("w",22);
alphabet.put("x",23);
alphabet.put("y",24);
alphabet.put("z",25);*/
ArrayList alphabet = new ArrayList();//[] = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"};

void setup() {
  size(W_WIDTH,W_HEIGHT); // définition de la surface de travail
  port = new Serial(this, portname, 9600);
  port.clear();
  background(BLACK);
  frameRate(10); // taux de traitement par seconde
  
  // Chargement de la base de données 
  database = loadDB("../../database.txt");
  
  // vérification du chargement
  checkDB(database);
}

void draw() {
  if(!start) {// attente du signal de mise en route du logiciel
    background(BLACK);
    //displayHistogram(data,orange);
    if(keyPressed){
      k = key;// c'est la clé qui sera passée en permanence pour donner à arduino le signal d'acquisition
      start = true;
      background(BLACK);
      text("start!!",10,30);
      //displayHistogram(data,orange);
    }
    
  }
  else{// le logiciel tourne
    //ecrire la valeur de k dans le port pour signaler qu'on peut faire une acquisition.
    port.write(k);
    
    //attendre la première réponse qui sera l'info sur la taille du buffer
    boolean gotLengthInfo = false;
    int dataLength = 0;
    
    
    while(!gotLengthInfo){// tant que l'information n'est pas reçue
      if(port.available() > 0){
        dataLength = port.read();
        gotLengthInfo = true;
      }
    }// l'info sur la taille du buffer est reçue
    
    // création du tableau d'acquisition
    data = getData(dataLength);
    
    // affichage de l'histogramme correspondant
    refresh(WHITE);
    
    // checking pour savoir si on est toujours stable
    boolean statusStable = true;
    for(int i = 0 ; i < data.length ; i++){
      if(abs(data[i] - lastStableData[i]) > STABILITY_DISTANCE_THRESH){
        statusStable = false;
      }
    }
    
    if(statusStable){// si c'est toujours stable, on incrémente
      stabilityCounter++;
      for(int i = 0 ; i < data.length ; i++){
        avgStableData[i] += data[i];
      }
    }else{// sinon on recommence, en faisant attention que stabilityCount soit bien à 1 et non à 0 (car on laisse UNE valeur cumulée dans avgStableData)
      stabilityCounter = 1;
      freeze = false;
      for(int i = 0 ; i < data.length ; i++){
        lastStableData[i] = data[i];
        avgStableData[i] = data[i]; 
      }
    }
    
    // si on a atteint le quota de esures stables consécutives, on peut faire le matching
    if(stabilityCounter >= STABILITY_COUNTER_THRESH && !freeze){
      refresh(ORANGE);
      for(int i = 0 ; i < avgStableData.length ; i++){
        avgStableData[i]  = (int) (avgStableData[i] / stabilityCounter);
      }
      currentLetter = match(avgStableData, database);
      if(!currentLetter.equals("*")){
        //lastLetter = currentLetter;
        if(sentence.length() % 20 == 0) sentence += "\n";
        sentence += currentLetter;
        refresh(GREEN);
      }else{
        refresh(RED);
      }
      
      stabilityCounter = 1;
      freeze = true;
    }
    
    
    // on match les datas avec la base de données et on vérifie que ç'est pas la même lettre que la dernière pour ne pas imprimer 36 fois le même caractère.
   /* currentLetter = match(data, database);
    if(!currentLetter.equals(lastLetter) && !currentLetter.equals("*")){
      lastLetter = currentLetter;
      text += currentLetter;
      background(0);
      text(text,10,30); 
    } */

  }
}


//fonction de chargement de la base de données
HashMap loadDB(String base) {  
  HashMap result = new HashMap();
  String dbContent[] = loadStrings(base);
  String split[];
  int elt[];
  ArrayList currentElt;
  if(dbContent.length > 0){
    for(int i = 0 ; i < dbContent.length ; i++){
      
      // spliter le contenu de la chaine de caractères pour récupérer les données
      split = split(dbContent[i], ":");
      
      // s'il n'y a pas encore d"entrée dans la db j'en crée une et j'ajoute la lettre en question dans l'alphabet 
      // en effet, on ne peut pas prétendre avoir un alphabet défini par avance a-z, car 
      // si la base de données décrit les chiffres ou les caractères ascii, on veut pouvoir la charger sans que ça pose de pb.
      // ça s'adapte tout seul.
      if(!result.containsKey(split[0])){
        result.put(split[0], new ArrayList());
        alphabet.add(split[0]);
      }
      
      // ajout de l"élément à la base
      elt = new int[split.length-1];
      for(int j = 0 ; j < elt.length ; j++){
        elt[j] = Integer.parseInt(split[j+1]);
      }
      currentElt = (ArrayList) result.get(split[0]);
      currentElt.add(elt);
    } 
  }
  
  return result;
}


// fonction de vérification de la base de données (pour le debug)
void checkDB(HashMap map){
  background(BLACK);
  String s_debug = "db loaded : " + map.size() + " elements \n===================================";
  ArrayList data ;
  int values[];
  for(int i = 0 ; i < alphabet.size() ; i++){
    String mapkey = (String) alphabet.get(i);
    
    if(map.containsKey(mapkey)){
      s_debug += "\n" + mapkey + " : ";
      data = (ArrayList) map.get(mapkey);
      for(int j = 0 ; j < data.size() ; j++){
        s_debug += "[" ;
        values = (int[]) data.get(j);
        for(int k = 0 ; k < values.length ; k++){
          s_debug += values[k] + ", " ;
        }  
        s_debug += "] , " ;
      }
    }
  }
  text(s_debug, 10, 30);
}

//fonction pour récupérer les datas du buffer
int[] getData(int l){
    int[] result = new int[l];// le tableau lui-même
    int currentIndex = 0;//indice courant pour vérifier qu'on a bien lu toutes les données.
    // on est obligé de procéder comme ça car rien ne dit que le buffer est fini de remplir quand on commence à le lire. 
    // donc s'il a une pause, on ne veut pas que le le programme considère qu'il a fini le travail.
    // si on faisait while(port.available>0) et qu'on lit les données plus vite qu'on ne les reçoit, on finira par en rater à la fin
    
    while(currentIndex < l){
      if(port.available() > 0){
        result[currentIndex] = port.read();
        currentIndex++;  
      }
    }
    
    return result;
}

// fonction pour matcher des datas avec la base de données
String match(int[] d, HashMap map){
  // attention à bien vérifier la taille des datas (à faire plus tard)
  boolean gotMatch = false;
  ArrayList currentLetterInDB;
  int currentElt[];
  float minDistanceFound = 100000000;
  float thresh = 100000000;
  String result = "";
  
  //on fait le match
  for(int i = 0 ; i < alphabet.size() ; i++){
    String mapkey = (String) alphabet.get(i);
    if(map.containsKey(mapkey)){
      currentLetterInDB = (ArrayList) map.get(mapkey);
      for(int j = 0 ; j < currentLetterInDB.size() ; j++){
        currentElt = (int[]) currentLetterInDB.get(j);
        float currentDistance = distance(d,currentElt);
        if(currentDistance < minDistanceFound){
          minDistanceFound = currentDistance;
          result = mapkey;
        }
      }
    }
  }
  
  // on ne renvoie la lettre que si le match est suffisant
  if(minDistanceFound > thresh) return "*";
  return result;
  
}


// fonction de calcul de distance
float distance(int[] t1, int[]t2){
 if(t1.length != t2.length) return 10000000;
 float result = 0;
 for(int i = 0 ; i < t1.length ; i++){
   result += pow(t2[i] - t1[i], 2);
 }
 
 return sqrt(result);
}


// fonction d'affichage de l'histogramme
void displayHistogram(color c){
  for(int i = 0 ; i < data.length ; i++){
    int letterBoxHeight = 100;
    int h = (int) (HIST_BAR_MIN_HEIGHT + data[i] * HIST_BAR_MAX_HEIGHT / 255 );
    int posX = (int) (MARGIN + i * 1.5 * HIST_BAR_WIDTH);
    int posY = (int) (W_HEIGHT - MARGIN - letterBoxHeight - h);
    fill(c);
    rect(posX, posY, HIST_BAR_WIDTH, h, 2);
  }
} 

// simulation de delay
void chrono(int tps){
  int t1 = millis();
  while(millis() - t1 < tps){
    //boucle vide
  }
  return;
}


// rafraichissement de l'écran
void refresh(color histColor){
  background(BLACK);
  fill(WHITE);
  textSize(18);
  text("stable since " + stabilityCounter + " loops." ,MARGIN + 30, MARGIN + 30);
  textSize(24);
  text(sentence,W_WIDTH - MARGIN - 400, MARGIN + 50, 400, W_HEIGHT - 2 * MARGIN - 100);
  textSize(72);
  text(currentLetter, MARGIN + 150, W_HEIGHT - MARGIN - 20);
  displayHistogram(histColor);
  
}
