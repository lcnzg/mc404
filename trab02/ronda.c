/*
Fazer o robô andar em uma "espiral quadrada".
Para isso, o robô deve andar um pouco para a frente, fazer uma curva de
aproximadamente 90 graus para a direita, andar mais um pouco para a frente,
fazer outra curva para a direita, e assim por diante. É importante que, após
cada curva, a distância percorrida para frente seja um pouco maior. A distância
deve ser ajustada em unidades de tempo do sistema (veja abaixo). Para isso, você
deve utilizar as rotinas de alarm para temporizar os movimentos. Seu robô deve
ser configurado para andar para frente por uma unidade de tempo até a primeira
curva à direita, depois andar por 2 unidades de tempo para frente antes de
realizar a próxima curva, e assim por diante, até atingir 50 unidades de tempo.
A partir daí o robô deve iniciar uma nova ronda. Sua lógica deve verificar os
sensores para garantir que o robô não colida com as paredes. Caso haja uma
parede no traçado do robô, você deve ajustar o curso do robô girando-o para a
direita, certificando-se de que ele não colida com a parede.
*/

#include "api_robot2.h"

#define SPEED 15
#define LIMIAR 900
#define LIMIAR2 250
#define TEMPOMAX 50
#define TEMPO90GRAUS 1300
#define MULT 5

void ronda();
void vira90Dir();
void viraDir();

int curva = 1;
unsigned int tAtual;
unsigned int tFinal;
unsigned int sonars[2];

// Cria structs para cada motor
motor_cfg_t m0;
motor_cfg_t m1;

int _start() {

  // Inicializa as structs para cada motor
  m0.id = 0;
  m1.id = 1;
  m0.speed = SPEED;
  m1.speed = SPEED;
  set_motors_speed(&m0, &m1);

  // Reinicia o timer
  set_time(0);

  // Desvia de uma possivel parede inicial
  viraDir();

  vira90Dir();

  // Chama a ronda
  ronda();
  while(1){}

  return 0;
}

void ronda() {

  //register_proximity_callback(3, LIMIAR, &viraDir);
  //register_proximity_callback(4, LIMIAR+LIMIAR2, &viraDir);

  // Anda para frente
  m0.speed = SPEED;
  m1.speed = SPEED;
  set_motors_speed(&m0, &m1);

}

// Vira 90 graus para direita
void vira90Dir() {

  // Vira para direita
  m0.speed = 0;
  m1.speed = SPEED / 2;
  set_motors_speed(&m0, &m1);

  // Delay para virar 90 graus
  get_time(&tAtual);
  tFinal = tAtual + TEMPO90GRAUS;
  while (tAtual < tFinal) {
      get_time(&tAtual);
  }

  // Aumenta o tempo para a proxima curva
  curva++;
  if (curva > TEMPOMAX) {
    curva = 1; // Reinicia o tempo para curvar apos TEMPOMAX
  }

  // Cria alarme para virar para direita em tempo crescente
  get_time(&tAtual);
  get_time(&tAtual);
  get_time(&tAtual);
  tAtual += (MULT*curva);
  add_alarm(&vira90Dir, tAtual);

  // Anda para frente
  //m0.speed = SPEED;
  //m1.speed = SPEED;
  //set_motors_speed(&m0, &m1);

  // Chama a ronda novamente
  ronda();
}

// Desvia das paredes
void viraDir() {

  // Vira para direita
  m0.speed = 0;
  m1.speed = SPEED / 2;
  set_motors_speed(&m0, &m1);

  // Continua enquanto tiver parede em frente
  do {
    read_sonars(3, 4, sonars);
  } while (sonars[0] < (LIMIAR+LIMIAR2) || sonars[1] < (LIMIAR+LIMIAR2));

  // // Para o robo
  // m0.speed = SPEED;
  // m1.speed = SPEED;
  // set_motors_speed(&m0, &m1);
  //
  // // Callback para virar se estiver perto da parede nos sensores frontais (3/4)
  // if (register_proximity_callback(3, LIMIAR, &viraDir) == -1){
  //   m0.speed = 0;
  //   m1.speed = 0;
  //   set_motors_speed(&m0, &m1);
  //
  //   while(1){};
  //
  // }
  //register_proximity_callback(2, LIMIAR-LIMIAR2, &viraDir);
  register_proximity_callback(3, LIMIAR, &viraDir);
  register_proximity_callback(4, LIMIAR+LIMIAR2, &viraDir);
  //register_proximity_callback(5, LIMIAR-LIMIAR2, &viraDir);

  // Chama a ronda novamente
  //ronda();
}
