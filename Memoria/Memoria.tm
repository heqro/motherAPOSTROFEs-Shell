<TeXmacs|1.99.14>

<style|<tuple|generic|spanish>>

<\body>
  <\hide-preamble>
    \;

    <assign|chapter-post-sep|<macro|<sectional-post-sep>>>
  </hide-preamble>

  <doc-data|<doc-title|Pr�ctica 1 - Minishell>|<doc-author|<author-data|<author-name|H�ctor
  Rodrigo Iglesias Goldaracena>>>|<doc-author|<author-data|<author-name|Y>>>|<doc-author|<author-data|<author-name|Juan
  Montes Cano>>>>

  <section|�ndice de contenidos>

  <section|Descripci�n del c�digo>

  <subsection|Funcionalidad implementada>

  El programa es capaz de cumplir los objetivos que se proponen en el
  enunciado de la pr�ctica. En efecto, es capaz de:

  <\itemize>
    <item>reconocer y ejecutar tanto en <em|foreground> como en
    <em|background> l�neas con un mandato con sus respectivos argumentos,

    <item>reconocer y ejecutar tanto en <em|foreground> como en
    <em|background> l�neas con dos o m�s mandatos con sus respectivos
    argumentos, enlazados por medio de \S<math|<around*|\|||\<nobracket\>>>\T,

    <item>reconocer y aplicar redirecci�n de entrada est�ndar desde archivo,
    y redirecci�n de salida est�ndar y de salida de error a un archivo,

    <item>ejecutar los mandatos internos <verbatim|cd>, <verbatim|fg> y
    <verbatim|jobs>,

    <item>y evita que tanto los comandos en <em|background>, as� como el
    Minishell, finalicen al enviar por teclado las se�ales <verbatim|SIGINT>
    y <verbatim|SIGQUIT>, mientras que permite que los procesos lanzados en
    <em|foreground> respondan ante ambas se�ales.
  </itemize>

  <subsection|Pseudoc�digo y planteamiento del programa>

  <subsubsection|Planteamiento del programa>

  En primer lugar, el programa consta de un proceso principal,
  <verbatim|PShell>, que cuenta con las siguientes caracter�sticas:

  <\itemize>
    <item>nunca muere, a no ser que se lance <verbatim|EOF>
    (<verbatim|Ctrl+D>) en el caso de que nos encontremos en el
    <verbatim|fgets> que se encuentra a la cabeza del bucle principal,

    <item>nunca ejecuta ninguna instrucci�n, salvo aquellas implementadas por
    nuestro propio c�digo (<verbatim|cd>, <verbatim|fg>, <verbatim|jobs>),

    <item>y cuenta con un manejador para <verbatim|SIGCHLD>.
  </itemize>

  Como consecuecuencia de estas dos propiedades, <verbatim|PShell> puede
  gestionar una lista de procesos en <em|background>, lo que nos permite
  marcarlos como acabados o en ejecuci�n en funci�n de en qu� estado se
  encuentren.

  En caso de que se pida un mandato distinto a los tres de los que ofrecemos
  la implementaci�n, se crea un hijo, <verbatim|PMandato> (al que
  <verbatim|PShell> esperar�, si el mandato no se ejecuta en
  <em|background>), que ser� el encargado de supervisar la ejecuci�n del
  mandato que se haya pedido, independientemente de que se est� ejecutando o
  no en <em|background>. Para ello, aplicar� las redirecciones oportunas, que
  ir�n hered�ndose a cada uno de los procesos hijo que vaya originando.

  <verbatim|PMandato> crear�, entonces, tantos hijos como mandatos haya en la
  l�nea cuya ejecuci�n tenga que supervisar (de uno en uno, solo existir� un
  hijo en un instante de tiempo dado).

  Si <verbatim|PMandato> recibe una l�nea que se tenga que ejecutar en
  <em|background>, <verbatim|PShell> registra el <verbatim|pid> de
  <verbatim|PMandato> en una lista que constar� de procesos en
  <em|background>, y continuar� su ejecuci�n sin esperar a la finalizaci�n de
  <verbatim|PMandato>, quien supervisar� con normalidad el mandato que le
  hayan asignado. Adem�s, <verbatim|PMandato> y sus hijos ignorar�n las
  se�ales de <verbatim|SIGINT> y de <verbatim|SIGQUIT> de haberse lanzado en
  <em|background>.

  En cualquier caso, al finalizar <verbatim|PMandato>, se acciona la se�al
  <verbatim|SIGCHLD>, de manera que <verbatim|PShell> actualiza la lista,
  marcando el nodo de su lista cuyo <verbatim|pid> corresponda con
  <verbatim|PMandato> como \SHecho\T.

  Independientemente de la l�nea insertada, antes de volverse a mostrar el
  <verbatim|prompt> y solicitarse una entrada de teclado nueva,
  <verbatim|PShell> limpiar� la lista de procesos, mostrando por pantalla
  aquellos que hayan sido completados de forma an�loga a como realiza Bash.

  En la secci�n de pseudoc�digo se procede a explicar m�s concretamente c�mo
  implemetnamos la comunicaci�n de <verbatim|PMandato> con sus hijos.

  <subsubsection|Pseudoc�digo>

  \;

  <subsection|Descripci�n de las principales funciones implementadas>

  <subsubsection|<verbatim|int escribirPrompt()>>

  Esta funci�n se encarga de escribir un <em|prompt> personalizado teniendo
  en cuenta el directorio de trabajo actual. Devuelve 1, a no ser que no
  exista la variable de entorno <verbatim|HOME>, en cuyo caso devuelve
  <math|0>. Como consecuencia, abandona el bucle principal y finaliza nuestro
  minishell.

  <subsubsection|<verbatim|static void handler(int sig, siginfo_t* siginfo,
  void* context)>>

  Previamente, en la funci�n <verbatim|main> se ha definido un
  <verbatim|struct sigaction>, con flags <verbatim|SA_SIGINFO> y
  <verbatim|SA_RESTART>, lo que nos permite obtener, respectivamente, mayor
  informaci�n y evitar la muerte del proceso receptor de la se�al una vez
  ejecutado su manejador.

  Dentro de la funci�n <verbatim|handler>, comprobamos que <verbatim|sig> se
  corresponda con la se�al <verbatim|SIGCHLD>, lo cual nos indicar�a la
  finalizaci�n de un hijo. Tras comprobar que el proceso que acciona la se�al
  es el que comienza el tratamiento del mandato, su padre se encargar�a de
  marcar a dicho proceso como hecho en su lista de procesos en
  <em|background>.

  <subsubsection|redirecciones (<verbatim|redirStdin>,
  <verbatim|redirStdout>, <verbatim|redirStderr>)>

  Son funciones que se encargan de gestionar los descriptores de fichero de
  aquellos procesos destinados a realizar mandatos. Esto es, el proceso ra�z
  no aplica redirecci�n alguna.

  <subsubsection|<verbatim|ejecutarComando(int i, tline* line)>>

  Esta funci�n se encarga de lanzar el mandato especificado por
  <verbatim|tline>.

  <subsubsection|Funciones de control de lista de procesos>

  Para la correcta gesti�n de procesos en <em|background>, hemos ideado una
  lista de procesos, que se implementa como una lista con puntero al inicio y
  al final para lograr la mayor eficiencia posible de inserci�n de procesos,
  as� como una r�pida extracci�n de los mismos por medio del mandato
  implementado <verbatim|fg>.

  Las m�s relevantes, que escapan de la habitual implementaci�n de una lista
  de estas caracter�sticas, son las siguientes:

  <\itemize>
    <item><verbatim|int limpiarLista(listaPIDInsercionFinal_t* L, int
    clasificar)>

    Esta funci�n se encarga de eliminar mandatos en <em|background> que
    estuvieran marcados como hechos. Cuenta con un flag,
    <verbatim|clasificar>, cuya funci�n nos permite diferenciar entre lo que
    se mostrar�a una vez acabado un mandato \Shabitual\T (una l�nea que
    muestra el mandato como realizado) y lo que se mostrar�a tras ejecutar
    <verbatim|jobs> (toda la lista de mandatos en <em|background>, est�n
    realizados o no, en el orden en que fueron insertados en la lista).

    <item><verbatim|void borrarElementoPID(pid_t pid,
    listaPIDInsercionFinal_t* L)>

    Como los <verbatim|pid> de los procesos son �nicos, nos podemos permitir,
    a la hora de eliminar un nodo de nuestra lista, comparar �nicamente los
    <verbatim|pid>s, y eliminar el nodo correspondiente.

    <item><verbatim|void terminarElem(elem_t* elem)>

    Marcar el elemento dado como hecho (es decir, poner su flag de estado a
    cero).
  </itemize>

  <section|Comentarios personales>

  <subsection|Problemas encontrados>

  <\itemize>
    <item>En el segundo algoritmo que probamos antes de realizar este
    programa, intentamos utilizar exclusivamente dos <verbatim|pipe>s para
    intercomunicar un proceso hijo y un proceso padre. Llegados a cierto
    n�mero de <verbatim|pipe>s, estas quedaban bloqueadas para lectura e
    imped�an la ejecuci�n del resto de mandatos, que se quedaban esperando a
    recibir entrada con la que trabajar.

    <item>Otro problema importante que hemos tenido ha sido el llamar, por
    medio de <verbatim|fg>, a un proceso en <em|background>. Hemos tenido
    problemas para acceder al <verbatim|pid> de un proceso que se encontraba
    en ejecuci�n, dado que en nuestra lista de <verbatim|pid>s cont�bamos
    exclusivamente con aquellos de los procesos que se derivaban de forma
    directa del proceso principal.

    <item>Dentro de nuestros planteamientos en papel del minishell,
    necesit�bamos conocer la se�al del proceso que enviaba la se�al al
    receptor, lo cual nos oblig� a utilizar <verbatim|sigaction> en
    detrimento de <verbatim|signal>.

    <item>Modificar, desde el proceso ra�z, la forma de actuar ante una se�al
    por parte de un proceso que se encuentra ejecutando un mandato. Aunque,
    en papel, de nuevo, �ramos capaces de solucionar el problema, se suced�an
    situaciones inesperadas y ante las que no encontramos respuesta; por
    ejemplo, dicho proceso mor�a inmediatamente tras mandarle una se�al \Vpor
    ejemplo, <verbatim|SIGUSR1>\V, con un manejador distinto al por defecto.
  </itemize>

  En resumen, todos los problemas encontrados se derivan de una misma causa:
  habiendo dise�ado y planteado en pseudoc�digo el programa, siempre
  encontr�bamos dificultades en la implementaci�n. No obstante, la mayor�a de
  estas dificultades las pudimos solventar, bien replanteando el c�digo, bien
  utilizando soluciones alternativas.

  <subsection|Cr�ticas constructivas y propuestas de mejora>

  <\itemize>
    <item>Estar�a bien que, con el fin de aligerar la cantidad de texto en el
    c�digo, y con fines puramente organizativos, pudi�semos implementar por
    nuestra cuenta archivos auxiliares (<verbatim|.h>, <verbatim|.c>), con
    los que, entre otras cosas, poder gestionar los tipos de datos m�s
    c�modamente, as� como poder realizar pruebas aparte sin tener que
    comprometer con ello todo el c�digo que hab�a previamente.

    <item>Creemos que podr�amos haber solucionado mucho antes algunos de los
    problemas que hemos tenido si hubi�semos conocido, de entrada, la
    existencia de herramientas como <verbatim|sigaction>, alternativas a
    <verbatim|signal> y que nos permit�an mayor maniobrabilidad a la hora de
    solucionar problemas.

    <item>Una vez acabada nuestra pr�ctica, nos dimos cuenta de que exist�an
    unas herramientas (<verbatim|tcsetpgrp>, <verbatim|setpgid>) que nos
    permit�an gestionar todos los procesos c�modamente. Nuevamente, habr�a
    sido bueno que se nos indicase su existencia para acelerar el desarrollo
    de la pr�ctica y poder hacerla lo mejor posible de entrada.

    <item>Un \Sjuez electr�nico\T (como los de los concursos de programaci�n)
    que eval�e la pr�ctica para saber antes de entregar qu� problemas tiene,
    y as� poder asegurarnos la m�xima nota sabiendo qu� errores corregir
    antes de la correcci�n por parte de los profesores.
  </itemize>

  <subsection|Evaluaci�n del tiempo dedicado>

  Pensamos que hemos invertido m�s tiempo del que nos gustar�a, causado por
  problemas m�s de implementaci�n (como los sucesos inesperados ya
  mencionados) que de dise�o, lo que nos llevar�a a replantear nuestro
  algoritmo en varias ocasiones.

  Nuevamente, tambi�n parte de este tiempo lo invertimos en investigar
  soluciones alternativas a los problemas que nos causaban las herramientas
  con las que cont�bamos de entrada. No obstante, esto nos ha permitido crear
  un mejor programa.

  <strong|Pseudoc�digo>

  <\itemize>
    <item>Inicializaci�n:

    <\itemize>
      \;

      <item>indicar al proceso que debe ignorar las se�ales
      <verbatim|SIGQUIT> y <verbatim|SIGINT>.
    </itemize>

    <item>Si recibimos una l�nea no vac�a, distinguimos casos:

    <\itemize>
      <item>si la l�nea consta de un solo mandato, ejecutamos
      <verbatim|fork()>

      <\itemize>
        <item>el hijo pasa a atender por defecto a <verbatim|SIGQUIT> y
        <verbatim|SIGINT> y ejecuta el mandato pedido.
      </itemize>

      <\itemize>
        <item>El padre espera al hijo y devuelve su c�digo de error.
      </itemize>
    </itemize>

    <\itemize>
      <item>si la l�nea consta de m�s de un comando
    </itemize>

    <item>Formar <verbatim|pipes>

    <\itemize>
      <item><verbatim|malloc()> para \Sinicializar\T puntero de
      <verbatim|pipe>s

      <item><verbatim|malloc()> para \Sinicializar\T tantos <verbatim|pipe>s
      como mandatos haya
    </itemize>

    <item>Bucle <verbatim|exec()>: tantas iteraciones como n�mero de mandatos
    haya

    <\enumerate-roman>
      <item><verbatim|fork()>

      <\itemize>
        <item>Hijo: distinguimos casos

        <\enumerate-alpha>
          <item>si es la primera iteraci�n:

          <\itemize>
            <item>cerrar <verbatim|pipe[iteraci�n][0]>, ya que no lo vamos a
            utilizar

            <item>duplicar <verbatim|pipe[iteraci�n][1]> en <verbatim|stdout>

            <item>cerrar <verbatim|pipe[iteraci�n][1]>, que ha quedado
            abierto tras la duplicaci�n

            <item><verbatim|exec()>
          </itemize>

          <item>si no es ni la primera ni la �ltima iteraci�n:

          <\itemize>
            <item>cerrar <verbatim|pipe[iteraci�n-1][1]>, ya que no lo vamos
            a utilizar

            <item>cerrar <verbatim|pipe[iteraci�n][0]>, ya que no lo vamos a
            utilizar

            <item>duplicar <verbatim|pipe[iteraci�n-1][0]> en
            <verbatim|stdin>

            <item>cerrar <verbatim|pipe[iteraci�n-1][0]>, ya que no lo vamos
            a utilizar

            <item>duplicar <verbatim|pipe[iteraci�n][1]> en <verbatim|stdout>

            <item>cerrar <verbatim|pipe[iteraci�n][1]> ya que no lo vamos a
            utilizar

            <item><verbatim|exec()>
          </itemize>

          <item>si es la �ltima iteraci�n:

          <\itemize>
            <item>cerrar <verbatim|pipe[iteraci�n-1][1]>, ya que no lo vamos
            a utilizar

            <item>cerrar <verbatim|pipe[iteraci�n][0]>, ya que no lo vamos a
            utilizar (esto no existe)

            <item>duplicar <verbatim|pipe[iteraci�n-1][0]> en
            <verbatim|stdin>

            <item>cerrar <verbatim|pipe[iteraci�n-1][0]>, ya que no lo vamos
            a utilizar

            <item><verbatim|exec()>

            Nota: no tenemos que modificar <verbatim|stdout> para que la
            �ltima iteraci�n funcione correctamente, dado que ha heredado los
            descriptores de fichero del padre, que indicaban que
            <verbatim|stdout> estaba redirigido (o no) previamente a un
            fichero.
          </itemize>
        </enumerate-alpha>
      </itemize>
    </enumerate-roman>
  </itemize>

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;
</body>

<\initial>
  <\collection>
    <associate|page-breaking|professional>
    <associate|page-crop-marks|a4>
    <associate|page-medium|paper>
  </collection>
</initial>

<\references>
  <\collection>
    <associate|auto-1|<tuple|1|1>>
    <associate|auto-10|<tuple|2.3.3|1>>
    <associate|auto-11|<tuple|2.3.4|?>>
    <associate|auto-12|<tuple|2.3.5|?>>
    <associate|auto-13|<tuple|3|?>>
    <associate|auto-14|<tuple|3.1|?>>
    <associate|auto-15|<tuple|3.2|?>>
    <associate|auto-16|<tuple|3.3|?>>
    <associate|auto-2|<tuple|2|1>>
    <associate|auto-3|<tuple|2.1|1>>
    <associate|auto-4|<tuple|2.2|1>>
    <associate|auto-5|<tuple|2.2.1|1>>
    <associate|auto-6|<tuple|2.2.2|1>>
    <associate|auto-7|<tuple|2.3|1>>
    <associate|auto-8|<tuple|2.3.1|1>>
    <associate|auto-9|<tuple|2.3.2|1>>
  </collection>
</references>

<\auxiliary>
  <\collection>
    <\associate|toc>
      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|1<space|2spc>�ndice
      de contenidos> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-1><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|2<space|2spc>Descripci�n
      del c�digo> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-2><vspace|0.5fn>

      <with|par-left|<quote|1tab>|2.1<space|2spc>Funcionalidad implementada
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-3>>

      <with|par-left|<quote|1tab>|2.2<space|2spc>Pseudoc�digo y planteamiento
      del programa <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-4>>

      <with|par-left|<quote|1tab>|2.3<space|2spc>Descripci�n de las
      principales funciones implementadas
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-5>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|3<space|2spc>Comentarios
      personales> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-6><vspace|0.5fn>

      <with|par-left|<quote|1tab>|3.1<space|2spc>Problemas encontrados
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-7>>

      <with|par-left|<quote|1tab>|3.2<space|2spc>Cr�ticas constructivas
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-8>>

      <with|par-left|<quote|1tab>|3.3<space|2spc>Propuesta de mejoras
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-9>>

      <with|par-left|<quote|1tab>|3.4<space|2spc>Evaluaci�n del tiempo
      dedicado <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-10>>
    </associate>
  </collection>
</auxiliary>