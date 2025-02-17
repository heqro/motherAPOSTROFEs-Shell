
#include <stdio.h>
#include <string.h>
#include "parser.h"
#include <unistd.h>
#include <stdlib.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <errno.h>

    
typedef struct elemento
{
    pid_t pid;
    int estado;
    int indice;
    char* buf;
}elem_t;

elem_t* crearElemento(pid_t pid, char* buf){
    elem_t* elemAux = malloc(sizeof(elem_t));
    elemAux->buf = malloc(1024*sizeof(char));
    elemAux->pid = pid;
    elemAux->estado = 1; // 1 -> ejecutando; 0 -> ejecutado;
    elemAux->buf = strcpy(elemAux->buf, buf);
    elemAux->indice = 1;
    return elemAux;
}

void asignar(elem_t* elem1, elem_t* elem2){
    elem1->pid = elem2->pid;
    elem1->pid = elem2->pid;
    elem1->estado = elem2->estado;
    elem1->buf = elem2->buf;
    elem1->indice = elem2->indice;
}

int igual(elem_t* elem1, elem_t* elem2){
    if(elem1->pid == elem2->pid){
        return 0;
    } else {
        return 1;
    }
}

void terminarElem(elem_t* elem){
    elem->estado = 0;
}

pid_t pidElem(elem_t elem){
    return elem.pid;
}

typedef struct nodo //nombre estructura
{
	elem_t elem;
    //int indice;
	struct nodo* sig;
} nodo_t; //tipo dato estructura

void mostrarNodo(nodo_t* nodo){
    if(nodo->elem.estado == 0){
        printf("[%i] - Hecho     %s", nodo->elem.indice, nodo->elem.buf);
    }else{
        printf("[%i] - Ejecutando     %s", nodo->elem.indice, nodo->elem.buf);
    }
}


typedef struct listaPIDInsercionFinal
{
    nodo_t* cabecera;
    nodo_t* final;
} listaPIDInsercionFinal_t;



//Lista 
listaPIDInsercionFinal_t ListaPID;





void crearVacia(listaPIDInsercionFinal_t* L){
    //L = malloc(sizeof(listaPIDInsercionFinal_t));
    L->cabecera = NULL;
    L->final = NULL;
}

int esVacia(listaPIDInsercionFinal_t* L){
    return (L->cabecera == NULL) && (L->final == NULL);
}

void insertarFinal(elem_t elem, listaPIDInsercionFinal_t* L, int clasificar){
	//1 print 0 noprint
    nodo_t* nodoAux = malloc(sizeof(nodo_t));
    asignar(&(nodoAux->elem), &elem);
    nodoAux->sig = NULL;
    if(esVacia(L)){
        L->cabecera = nodoAux;
        L->final = nodoAux;
    } else {
        if(clasificar == 1){
            nodoAux->elem.indice = L->final->elem.indice + 1;
        }
        L->final->sig = nodoAux;
        L->final = L->final->sig;
    }
    if(clasificar == 1){
        printf("[%d] %d\n", nodoAux->elem.indice, nodoAux->elem.pid);
    }
}


void borrarElementoPID(pid_t pid, listaPIDInsercionFinal_t* L){
    nodo_t* ptrAnterior;
    nodo_t* ptrActual;
	ptrActual = L->cabecera;
	ptrAnterior = NULL;
    if(!esVacia(L)){
        
        while((ptrActual->sig != NULL) && pid != pidElem(ptrActual->elem)){
            ptrAnterior = ptrActual;
            ptrActual = ptrActual->sig;
        }
        
        if(ptrAnterior == NULL){
			if(pid == pidElem(ptrActual->elem)){
				if(ptrActual->sig == NULL){
					L->cabecera = NULL;
					L->final = NULL;
				
					free(ptrActual);
					
				}else{
					L->cabecera = ptrActual->sig;
					free(ptrActual);
					
				}
			}
		}else{
			if(pid == pidElem(ptrActual->elem)){
				if(ptrActual->sig == NULL){
					L->final = ptrAnterior;
					ptrAnterior->sig = NULL;
					free(ptrActual);
				
				}else{
					ptrAnterior->sig = ptrActual->sig;
					free(ptrActual);
				}
			}
		
		
		}
    }
}

void copiarLista(listaPIDInsercionFinal_t* L, listaPIDInsercionFinal_t* lAux){
    nodo_t* ptrAux;
    if(!esVacia(L) && esVacia(lAux)){
        ptrAux = L->cabecera;
        while(ptrAux != NULL){
            insertarFinal(ptrAux->elem, lAux,0);
            ptrAux = ptrAux->sig;
        }
    }
}

int limpiarLista(listaPIDInsercionFinal_t* L, int clasificar){ //1 JOBS 0 MANDATO NORMAL
	nodo_t* ptrAux;
    listaPIDInsercionFinal_t lAux;
    
    crearVacia(&lAux);
    copiarLista(L, &lAux);
	if(!esVacia(&lAux)){
		ptrAux = lAux.cabecera;
		while(ptrAux != NULL){
			if(ptrAux->elem.estado==0){
				if(clasificar == 0){
					mostrarNodo(ptrAux);
				}
				borrarElementoPID(ptrAux->elem.pid,L);
			}
			ptrAux = ptrAux->sig;
        }
	}
	return 0;
}

void mostrarLista(listaPIDInsercionFinal_t* L){ //jobs
    nodo_t* ptrAux = L->cabecera;
    while(ptrAux != NULL){
        mostrarNodo(ptrAux);
        ptrAux = ptrAux->sig;
    }
    limpiarLista(L,1);
}

elem_t* getElemPID(pid_t pid, listaPIDInsercionFinal_t* L){
    nodo_t* ptrAux = L->cabecera;
    while(ptrAux != NULL){
        if(pid == pidElem(ptrAux->elem)){
            return &ptrAux->elem;
        } else {
            ptrAux = ptrAux->sig;
        }
    }
    return NULL;
}
nodo_t* getUltimo(listaPIDInsercionFinal_t* L){
    if (!esVacia(L)){
		return L->final;
	}else{		
		return NULL;
	}
}

int cambiarDirectorio(int nArgs, char** lArgs){
    char* nuevoDir = NULL;
    char* buf;
    char* barra;
    
    buf = NULL;
    barra = malloc(sizeof(char));
    
    if (nArgs == 1) { // ir a home
        nuevoDir = getenv("HOME");
    } else {
        if (nArgs > 2) {
            // número incorrecto de argumentos
            // lanzar mensaje
            fprintf(stderr,"Error numero incorrecto de argumentos\n");
            return 1; //No podemos matar al padre
        }
        if (*(lArgs[1]) != '/'){//ruta relativa
            nuevoDir = getcwd(nuevoDir, 0);
            *barra = '/';
            nuevoDir = strcat(nuevoDir, barra);
            nuevoDir = strcat(nuevoDir, lArgs[1]);
        } else { // ruta absoluta
            nuevoDir = lArgs[1];
        }
    }
    int aux = chdir(nuevoDir);
    if(aux==0){
		buf=getcwd(buf,0);
		printf("%s\n", buf);
	}else{
		fprintf(stderr,"Error en chdir.\n");
	}
	free(buf);
	free(barra);
	
    return aux;
}


void crearPrimero(int pipe[2], tline* line){
    
    close(pipe[1]);
    dup2(pipe[1],STDOUT_FILENO);
    
    // comprobación de error
    if(line->redirect_input){//hay redirección de entrada
        int aux = open(line->redirect_input, O_RDONLY);
        dup2(aux,STDIN_FILENO);
        close(aux);
    }
    
}

void crearUltimo(int pipe[2], tline* line,int* stdoutAux,int* stdinAux){
    close(pipe[1]); // Nunca utilizaremos el pipe de salida, por lo que lo cerramos
    
    if(line->redirect_output) { //hay redirección de salida
        //pipe[1] = open(line->redirect_output, O_CREAT, O_WRONLY);
        dup2(pipe[1],open(line->redirect_output, O_CREAT, O_WRONLY));
        
    } else { //Escuchar por stdout
		dup2(*stdoutAux,1);
        close(*stdoutAux);
        dup2(*stdinAux,0);
        close(*stdinAux);
    }
}

int esHijo(pid_t pid){
    return pid == 0; //devuelve 1 si es hijo
}

void errorFork(pid_t pid){
    if(pid < 0){
        fputs("Fallo en el fork", stderr);
        exit(1);
    }
}

int comprobarComando(char* comando){
    int esCd, esFg, esJobs;
    esCd = strcmp(comando, "cd");
    esFg = strcmp(comando, "fg");
    esJobs = strcmp(comando, "jobs");
    return esCd || esFg || esJobs;
}


void ejecutarComando(int i, tline* line){
	int status;
    char* const* argumentos = line->commands[i].argv;	
    execvp(argumentos[0], argumentos);
    fflush(stdout);
	fprintf(stderr,"%s: No se encuentra el mandato\n",argumentos[0]);
    exit(1);
}


void redirStdin(char* inp){
	int dirAux;
	
	if (inp!=NULL){
		dirAux = open(inp,O_RDONLY);
		if(dirAux < 0){
			fprintf(stderr,"Fichero : Error. %s\n",strerror(errno));
			exit(1);
		}else{
			dup2(dirAux,STDIN_FILENO);
			close(dirAux);
		}
		
	}
}
void redirStdout(char* output){
	int dirAux;
	
	if (output!=NULL){
		dirAux = open(output,O_WRONLY | O_CREAT);
		if(dirAux < 0){
			fprintf(stderr,"Fichero : Error. %s\n",strerror(errno));
			exit(1);
		}else{
			dup2(dirAux,STDOUT_FILENO);
			close(dirAux);
		}
		
	}
}
void redirStderr(char* outerror){
	int dirAux;
	
	if (outerror!=NULL){
		dirAux = open(outerror,O_WRONLY| O_CREAT);
		if(dirAux < 0){
			fprintf(stderr,"Fichero : Error. %s\n",strerror(errno));
			exit(1);
		}else{
			dup2(dirAux,STDERR_FILENO);
			close(dirAux);
		}
		
	}
}

int control=0; //Señal que nos permite hacer ctrl c si entra a fg
pid_t pidglobal = 0;



void manejador1(int sig){
	if(sig == SIGCHLD){
		pid_t pid;
		pid = wait(NULL);
	
		if (pid !=-1){ //Para que no entre el hijo sin hijo
			elem_t *aux = getElemPID(pid,&ListaPID);
			terminarElem(aux);
			fflush(stdout);
		}
	}
	if(sig == SIGUSR1){
		
		
		control = 1;
        
        //kill(pidglobal,SIGUSR2);
		
		fprintf(stderr,"2 %i\n",pidglobal);
	
	}
	if(sig == SIGUSR2){
		
		fprintf(stdout,"3\n");
        fflush(stdout);
		signal(SIGINT,SIG_DFL);
		signal(SIGQUIT,SIG_DFL);
		
		fprintf(stdout,"4\n");
	}
}

int escribirPrompt(){
    char* dirActual = NULL;
    dirActual = getcwd(dirActual, 0);
    char* inicio = getenv("HOME");
    if(inicio == NULL) {
        return 0;
    }
    if(!strcmp(inicio, dirActual)){
        printf("%s@msh | ~ >> ", getenv("LOGNAME"));
    } else {
        printf("%s@msh | %s >> ", getenv("LOGNAME"), dirActual);
    }
    return 1;
}
#define CD "cd"
#define JOBS "jobs"
#define FG "fg"



int main() {
    // Definición de variables
    char buf [1024];
    int i;
    pid_t pid;
    tline* line;
    int status;
    int stdoutAux = dup(1); //guardamos stdout actual
    int stdinAux = dup(0);	//guardamos stdin actual
    int stderrAux = dup(2);
    int **pipes;
    
    crearVacia(&ListaPID);
    
    signal(SIGUSR1,manejador1);
    signal(SIGUSR2,manejador1);
    
    signal(SIGINT,SIG_IGN);
	signal(SIGQUIT,SIG_IGN);
    while(escribirPrompt() && fgets(buf, 1024, stdin)){
		//Comprobar y limpiar lista de pids
        
        line = tokenize(buf);
        if (line==NULL || !strcmp(buf,"\n")) {
            limpiarLista(&ListaPID,0);
            continue;
        } else {
            if(strcmp(line->commands[0].argv[0],JOBS)==0){
                mostrarLista(&ListaPID);
                continue;
            }else if(strcmp(line->commands[0].argv[0],CD)==0){
                cambiarDirectorio(line->commands[0].argc,line->commands[0].argv);
                limpiarLista(&ListaPID,0);
                continue;
            }
            else if(strcmp(line->commands[0].argv[0],FG)==0){
                //Recorremos la lista hasta llegar al ultimo nodo
                //Vemos si su estado es ejecutando
                //El padre shell manda un kill a su hpadre, el hpadre en ese kill hace kill a su hijo
                 
                 nodo_t *ultimonodo=getUltimo(&ListaPID);
                 if(ultimonodo->elem.estado == 1){
					kill(ultimonodo->elem.pid,SIGUSR1);
					waitpid(ultimonodo->elem.pid,&status,0); //Esperamos a que el proceso acabe
					
				 }else if(ultimonodo->elem.estado == 0){
					 fprintf(stdout,"msh: fg : El trabajo ha terminado");
				 }
                 
                
                //y coloca la variable global a uno para los demas hijos que puedan crearse.
                //En ese caso se hace el waitpid del pid del nodo
                
                //En caso contrario escribimos por stdout que el proceso ha finalizado
                //WAITPID RECORDAR
                limpiarLista(&ListaPID,0);
                continue;
            }
			if (line->background){ //proceso en bg
				signal(SIGCHLD,manejador1);
            }
			pid = fork();
			
			if (!esHijo(pid)){ // si es padre
				if(!line->background){ //No bg
					wait(&status); // esperar hijo
					if(WTERMSIG(status)==SIGINT || WTERMSIG(status)==SIGQUIT ){printf("\n");} //print \n si se acaba con el hijo con Ctrl C
				
				}else{
					//Tratar buf
					elem_t *elem = crearElemento(pid,buf);
					insertarFinal(*elem, &ListaPID,1);
				}
                limpiarLista(&ListaPID,0);
				//fprintf(stderr,"Entro por este continue\n");
				//pause();
				continue;
			}else{ // si es hijo
				
				//Redireccionamientos
				
				redirStderr(line->redirect_error); //pasamos la redireccion de error 
				redirStdin(line->redirect_input); //pasamos la redireccion de entrada 
				redirStdout(line->redirect_output); //pasamos la redireccion de salida 
					
			}
         }
        
        
        
        if(line->ncommands == 1){
            pid = fork();
            if(esHijo(pid)){
				if(line->background == 0){ //Si no esta en bg
					signal(SIGQUIT,SIG_DFL);
					signal(SIGINT,SIG_DFL);
				}
                ejecutarComando(0,line);
            }else{
				pidglobal = pid; //guardamos el hijo por si lo necesitamos para fg
				if(line->background){ //Añadimos el mandato en bg a la ListaPID
					//fprintf(stderr,"Creo elemento\n");
					//elem_t *elem = crearElemento(getpid(),buf);
					//insertarFinal(*elem, &ListaPID);
					
					//fprintf(stderr,"Elemento creado\n");
				}	
				
                wait(&status);
                if (WTERMSIG(status)==SIGINT || WTERMSIG(status)==SIGQUIT){
					printf("\n");	
				}
				if(line->background){ //si esta en bg
					//fprintf(stderr,"Detono señal\n");
					//kill(getppid(),SIGUSR1);
					//fprintf(stderr,"Señal detonada\n");
				}
				
				exit(status); //devolvemos el status de su hijo
            }
        } else {
            pipes = malloc((line->ncommands - 1)*sizeof(int*));//inicializamos n-1 pipes
            for(i = 0; i < line->ncommands - 1; i++){
                pipes[i] = malloc(2*sizeof(int)); // para cada pipe inicializamos dos enteros
                pipe(pipes[i]); // para cada pipe inicializamos sus descriptores
            }
            for (i = 0; i < line->ncommands; i++) { // Ejecución de la línea
                pid = fork();
                errorFork(pid);
                if(esHijo(pid)){ // Hijo
                    
					if(!line->background || control){
						signal(SIGQUIT,SIG_DFL);
						signal(SIGINT,SIG_DFL);
					}	
			
                    if (i == 0){ // si es la primera iteración
                        close(pipes[0][0]);
                        dup2(pipes[0][1],STDOUT_FILENO);
                        close(pipes[0][1]);
                    }
                    if (i != 0 && i != (line->ncommands-1)){
                        // si no es ni la primera ni la última iteración
                        
                        close(pipes[i][0]);
                        dup2(pipes[i-1][0], STDIN_FILENO);
                        close(pipes[i-1][0]);
                        dup2(pipes[i][1], STDOUT_FILENO);
                        close(pipes[i][1]);
                    }
                    if (i!= 0 && i == (line-> ncommands - 1)){
                        
                        dup2(pipes[i-1][0],STDIN_FILENO);
                        close(pipes[i-1][0]);
                    }
                    ejecutarComando(i, line);
                } else { // Padre
					pidglobal = pid; //guardamos el hijo por si lo necesitamos para fg
                    if(i != line->ncommands - 1){
                        close(pipes[i][1]); //cerramos el descriptor para que no se bloqueen las lecturas del hijo siguiente
                    }
                    wait(&status); // esperar al i-ésimo hijo
                    if (WTERMSIG(status)==SIGINT || WTERMSIG(status)==SIGQUIT){
						break;
					}
                    
                }
            }
            // después del for, padre cierra descriptores abiertos
            for(i = 0; i < line->ncommands - 1; i++){              
                free(pipes[i]); // para cada pipe inicializamos dos enteros
            }
            free(pipes);
        }
        fflush(stdout);
        if(line->background==0){//si no esta en bg
			exit(0);
		}else{ //si esta en bg
			exit(0);
		}
 

 
 
 
 
 
 
 
 
 
 
 
    }
    
    
    
    return 0;
}
