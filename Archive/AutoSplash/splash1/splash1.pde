import processing.pdf.*;

//import processing.opengl.*;

void setup() {
  size(320, 480);
  textMode(SCREEN);
  background(0);
  int POND = 1; 
  int FADE = 2; 
  int TABLE = 3;
  int TABLE_BIGTEXT = 4;
  int TABLE_BIGTEXT2 = 5;
  int TABLE_BIGTEXT3 = 6;
  PImage b;
  // 3 -> SF, 95 -> 2010 Olmpics, 4 -> stanford, 130 -> everglades, 96 -> family vancouver, 17 -> new york essential, 82 -> chinatown
  b = loadImage("../../../content/82/Icon_512x512.png");
  int effect = TABLE_BIGTEXT3;
  fill(150);

  image(b, 0,0,320,320);
  //smooth();
  PFont font = loadFont("Futura-Medium-36.vlw");
  PFont thirtyPoint = loadFont("Futura-Medium-30.vlw");
  PFont twelvePoint = loadFont("Futura-Medium-12.vlw");
  
//  font = loadFont("Helvetica-Bold-36.vlw");


  if(effect == POND) {
    for(int i = 0; i < 320; i++) {
      for(int j = 320; j < 400; j++) {
        color toMimic = get(i, 319 - 4 * (j - 320));
        color faded = color(red(toMimic), green(toMimic), blue(toMimic),i);
        set(i, j, blendColor(toMimic,color(0,0,0,sq((j - 320)/4.)),BLEND));
      }
    }

    textFont(font,18);
    text("San Francisco Exploration Guide",10,420);
    textFont(font,12);
    text("By Kevin Collins and Tobin Fisher", 20, 440);
  }
  else if(effect == FADE) {
    for(int i = 0; i < 320; i++) {
      for(int j = 280; j < 320; j++) {
        color toMimic = get(i, j);
        set(i, j, blendColor(toMimic,color(0,0,0,sq((j - 280)/2.)),BLEND));
      }
    }
    textFont(font,30);
    text("San Francisco",20,360);
    text("Exploration Guide",45, 395);
    textFont(font,15);
    text("By Kevin Collins and Tobin Fisher", 45, 430);

  }
  else if(effect == TABLE) {
    for(int i = 0; i < 320; i++) {
      for(int j = 320; j < 480; j++) {
        color toMimic = get(i, 319 - 2 * (j - 320));
        set(i, j, blendColor(toMimic,color(0,0,0,30 + (j - 320) * 1.8),BLEND));
      }
    }

    textFont(font,18);
    text("San Francisco Exploration Guide",10,430);
    textFont(font,12);
    text("By Kevin Collins and Tobin Fisher", 20, 455);
  }
  
  else if(effect == TABLE_BIGTEXT) {
    for(int i = 0; i < 320; i++) {
      for(int j = 320; j < 480; j++) {
        color toMimic = get(i, 319 - 2 * (j - 320));
        set(i, j, blendColor(toMimic,color(0,0,0,50 + (j - 320) * 1.2),BLEND));
      }
    }
    fill(255);
    textFont(font,30);
    int startY = 370;
    text("San Francisco",20,startY);
    text("Exploration Guide",45, startY + 35);
    textFont(font,12);
    text("By Kevin Collins and Tobin Fisher", 70, startY + 65);
  }
  else if(effect == TABLE_BIGTEXT2) {
    for(int i = 0; i < 320; i++) {
      for(int j = 320; j < 480; j++) {
        color toMimic = get(i, 319 - 2 * (j - 320));
        set(i, j, blendColor(toMimic,color(0,0,0,80 + log(j - 320) * 30),BLEND));
      }
    }
    fill(255);
//    println("PFont.list() returns " + join(PFont.list(), ", "));
//    textFont(createFont("Futura-Medium",30));
    textFont(thirtyPoint);
    int startY = 368;
    text("San Francisco's",20,startY);
    text("Exploration Guide",45, startY + 35);
//    textFont(createFont("Futura-Medium",12));
      textFont(twelvePoint);
    text("By Kevin Collins and Tobin Fisher", 70, startY + 65);
  }  
  else if(effect == TABLE_BIGTEXT3) {
    for(int i = 0; i < 320; i++) {
      for(int j = 320; j < 480; j++) {
        color toMimic = get(i, 319 - 2 * (j - 320));
        set(i, j, blendColor(toMimic,color(0,0,0,80 + log(j - 320) * 30),BLEND));
      }
    }
    fill(255);//,150);
//    println("PFont.list() returns " + join(PFont.list(), ", "));
//    textFont(createFont("Futura-Medium",30));
    textFont(thirtyPoint);
    int startY = 368;
//    fill(255,0,0, 128);
//    noStroke();
//    ellipse(50,50,25,25);
    text("San Francisco's",20,startY);
 //   textAlign(RIGHT)
    text("Chinatown",45, startY + 35);
//    textFont(createFont("Futura-Medium",12));
      textFont(twelvePoint);
    text("By Laura del Rosso", 70, startY + 65);
  }  
}





