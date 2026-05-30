#include <stdio.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdint.h>

// Semaforos necesarios para el problema
sem_t semBarraLlena; // Representa capacidad de la barra
sem_t semBarraVacia;
sem_t semMozo; // Indica que un mozo está disponible para servir
sem_t mutexBarra;
int platosEntregados = 0;
long platos = 8;
int platosHechos = 0;


void* cocinero(void* arg){
    int id = (int)(intptr_t)arg;
    while(1){
        if (platosHechos > 10) break;
        sem_wait(&semBarraVacia);
        sem_wait(&mutexBarra);
        printf("Cocinero %d preparó un plato\n", id);
        sleep(1 + rand() % 4); 
        sem_post(&mutexBarra);
        sem_post(&semBarraLlena);
        int platosEnBarra;
        sem_getvalue(&semBarraVacia, &platosEnBarra);
        platosHechos++;
        printf("Cocinero %d dejó un plato en la barra | Platos en barra: %i | Platos hechos: %i\n", id, platosEnBarra, platosHechos);
        
    }
    return NULL;
}

void* mozo(void* arg){
    int id = (int)(intptr_t)arg;
    while(1){
        sem_wait(&semBarraLlena); 
        sem_wait(&semMozo);
        int platosEnBarra;
        sem_getvalue(&semBarraVacia, &platosEnBarra);
        printf("Mozo %d retiró un plato de la barra | Platos en barra: %i.\n", id, platosEnBarra);
        sem_post(&semMozo);
        sleep(1+ rand() % 3); 
        platosEntregados++;
        printf("Mozo %d entegó el plato | Platos entregados: %d\n", id, platosEntregados);
        sem_post(&semBarraVacia);
    }
    return NULL;
}

int main() {
    sem_init(&semBarraLlena, 0, 0);
    sem_init(&semBarraVacia, 0 , 8); 
    sem_init(&semMozo, 0, 1);
    sem_init(&mutexBarra, 0, 1);    
    pthread_t cocineros[5];
    pthread_t mozos[10];

    
    for(int i = 0; i < 5; i++) {
        pthread_create(&cocineros[i], NULL, cocinero, (void*)(intptr_t)i);
    }
    for(int i = 0; i < 10; i++) {
        pthread_create(&mozos[i], NULL, mozo, (void*)(intptr_t)i);
    }

    for(int i = 0; i < 5; i++) {
        pthread_join(cocineros[i], NULL);
    }

    for(int i = 0; i < 10; i++) {
        pthread_join(mozos[i], NULL);
    }

    sem_destroy(&semBarraLlena);
    sem_destroy(&semBarraVacia);
    sem_destroy(&semMozo);
    sem_destroy(&mutexBarra);
    printf("Todos los platos han sido entregados. Total: %d\n", platosEntregados);
    return 0;
}

/* 
5 cocineros
10 mozos
tamaño barra = 8 platos
Cocinero: prepara en un tiempo random no mayor a 3 segundos -> intenta ponerlo en la barra
Mozo: Retira plato de la barra -> lo entrega en un tiempo random no mayor a 2 segudos
*/