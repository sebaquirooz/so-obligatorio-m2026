#include <stdio.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdint.h>

sem_t semBarraLlena; 
sem_t semBarraVacia;
sem_t mutexBarra;
int platosEntregados = 0;
int platosHechos = 0;
int platosEnBarra = 0;

void cocinar(int id) {
    sleep(1 + rand() % 4); 
    printf("Cocinero %d preparó un plato\n", id);
}

void retirar(int id) {
    sleep(1 + rand() % 2); 
    printf("Mozo %d retiró un plato de la barra (platos en barra: %d)\n", id, platosEnBarra);
}

void* cocinero(void* arg){
    int id = (int)(intptr_t)arg;

    while(1){
        sem_wait(&semBarraVacia);
        sem_wait(&mutexBarra);

        if (platosHechos >= 50) {
            sem_post(&mutexBarra);
            sem_post(&semBarraLlena);
            sem_post(&semBarraVacia);
            break;
        }
        
        sem_post(&mutexBarra);
        sem_wait(&mutexBarra);

        cocinar(id);
        platosHechos++;
        platosEnBarra++;
        printf("Cocinero %d dejó un plato en la barra (platos en barra: %d)\n",id, platosEnBarra);

        sem_post(&mutexBarra);
        sem_post(&semBarraLlena);
    }

    return NULL;
}

void* mozo(void* arg){
    int id = (int)(intptr_t)arg;

    while(1){
        sem_wait(&semBarraLlena);
        sem_wait(&mutexBarra);

        if (platosEntregados >= 50) {
            sem_post(&mutexBarra);
            sem_post(&semBarraVacia);
            sem_post(&semBarraLlena);
            break;
        }

        platosEnBarra--;
        retirar(id);
        printf("Mozo %d está entregando el plato\n", id);
        platosEntregados++;
        sem_post(&mutexBarra);
        sem_post(&semBarraVacia);
    }

    return NULL;
}

int main() {
    sem_init(&semBarraLlena, 0, 0);
    sem_init(&semBarraVacia, 0 , 8); 
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
    sem_destroy(&mutexBarra);

    printf("Todos los platos han sido entregados. Total: %d\n", platosEntregados);
    return 0;
}