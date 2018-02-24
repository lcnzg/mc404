/*
a) A lógica busca-parede é iniciada assim que o Uóli é ligado. Esta lógica deve
fazer o Uóli andar em linha reta até se aproximar de uma parede (o Uóli não deve
colidir com a parede). Após encontrar a parede, o Uóli deve ajustar sua posição
de forma que a parede fique do lado esquerdo dele.
b) Uma vez que a posição foi ajustada, o modo segue-parede deve ser ativado.
Neste modo, o Uóli deve andar para frente acompanhando a parede, ou seja, sempre
mantendo a parede à sua esquerda, ajustando o traçado à medida que a parede se
distanciar ou ficar muito próxima do robô. Novamente, é importante que o Uóli não
colida com as paredes do ambiente.
*/

#include "api_robot2.h"

#define SPEED 20
#define LIMIAR 1000

void buscaParede();
void segueParede();
void viraDir();

// Cria structs para cada motor
motor_cfg_t m0;
motor_cfg_t m1;

int main(){

  // Inicializa as structs para cada motor
  m0.id = 0;
  m1.id = 1;

  // Reinicia o timer
  set_time(0);

  // Encontra uma parede
  buscaParede();

  // Segue a parede a esquerda
  segueParede();

  return 0;
}

void buscaParede(){

  int sonars[2];

  // Anda pra frente
  m0.speed = SPEED;
  m1.speed = SPEED;
  set_motors_speed(&m0, &m1);

  // Continua enquanto nao encontrar
  do {
    read_sonars(3, 4, &sonars);
  } while (sonars[0] > LIMIAR && sonars[1] > LIMIAR);

  // Ajusta parede a esquerda
  ajustaEsq();
}

// Deixa parede a esquerda
void ajustaEsq(){

  int sonars[2];

  // Vira para direita
  m0.speed = 0;
  m1.speed = SPEED / 2;
  set_motors_speed(&m0, &m1);

  // Continua enquanto nao ajustar parede a esquerda
  do {
    read_sonar(0, &sonar[0]);
    read_sonar(15, &sonar[1]);

  } while (sonars[0] > LIMIAR || sonars[1] > LIMIAR);
}

void segueParede(){

  int sonars[2];

  // Callback para virar se estiver perto da parede nos sensores frontais (3/4)
  register_proximity_callback(3, LIMIAR, &viraDir);
  register_proximity_callback(4, LIMIAR, &viraDir);

  // lOOP INFINITO
  while(1){
    read_sonar(1, &sonar[0]); // Sonar esquerda frente
    read_sonar(14, &sonar[1]); // Sonar esuerda tras

    // Vira esquerda
    if (sonar[0] > sonar[1]){
      m0.speed = SPEED / 2;
      m1.speed = 0;
      set_motors_speed(&m0, &m1);
    }
    // Vira direita
    else {
      m0.speed = 0;
      m1.speed = SPEED / 2;
      set_motors_speed(&m0, &m1);
    }

    // Anda pra frente
    m0.speed = SPEED;
    m1.speed = SPEED;
    set_motors_speed(&m0, &m1);
  }
}

// Desvia das paredes
void viraDir() {
  int sonars[2];

  // Vira para direita
  m0.speed = 0;
  m1.speed = SPEED / 2;
  set_motors_speed(&m0, &m1);

  // Continua enquanto tiver parede em frente
  do {
    read_sonars(3, 4, &sonars);
  } while (sonars[0] < LIMIAR || sonars[1] < LIMIAR);
}
