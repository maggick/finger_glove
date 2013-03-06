import processing.serial.*;
PFont font; // instanciation de la fonte
char k;
boolean start = false ;
String text = "";


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
  size(400,200); // définition de la surface de travail
  port = new Serial(this, portname, 9600);
  port.clear();
  background(0);
  frameRate(10); // taux de traitement par seconde
  
  // Chargement de la base de données 
  database = loadDB("../../database.txt");
  
  // vérification du chargement
  checkDB(database);
}

void draw() {
  if(!start) {
    background(0);
    text("lll",10,30);
    if(keyPressed){
      k = key;
      start = true;
      background(0);
      text("start!!",10,30);
    }
    
  }
  else{
    background(0);
      text("?????",10,30);
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
    int[] data = getData(dataLength);
    
    // on match les datas avec la base de données.
    text += match(data, database);
    
    background(0);
    text(text,10,30);    
    
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
  background(0);
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


//calcul de distance
float distance(int[] t1, int[]t2){
 if(t1.length != t2.length) return 10000000;
 float result = 0;
 for(int i = 0 ; i < t1.length ; i++){
   result += pow(t2[i] - t1[i], 2);
 }
 
 return sqrt(result);
}
