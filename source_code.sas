/* ================================================================= */
/* ======== Méthode de Box-Jenkins : Identification ================ */
/* ================================================================= */

ODS PDF FILE='IDENTIFICATION.pdf';
OPTIONS PS=66 LS=80 FORMDLIM= '=';

/*  
Supposons que vous disposez de deux fichiers de données:
1. "serie.txt" est un fichier qui contient les données que vous désirez modéliser.
2. "nouvelles.txt" est un fichier qui contient les nouvelles données.
Ainsi, ayant vos données téléchargées d'une base de données, votre 
première étape consiste à créer ces deux fichiers, et les noms des fichiers sont
importants (si vous optez pour des noms différents vous devrez changer le code aux 
endroits pertinents).

Remarque : Le nombre de données tronquées est une information importante.  
Cette quantité doit être inscrite dans PROC ARIMA de SAS lors du calcul des prévisions.  
Voir l'énoncé LEAD.

- Gros merci au professeur de nous fournir le code source .sas pour nous aider à
réaliser ce projet -

STT3220
Devoir 3
Laurence Dupuis
Van Nam Vu


Date : 16/04/2023
*/

/* ================================================================== */
/* ================== Étape 1: Lecture des données ================== */
/* ================================================================== */

/* CANSIM code : V822788*/
data serie;
	infile
	datalines
	delimiter=',';
	input NBOBS Zt ;
datalines;
1,3028902
2,2940449
3,3162394
4,3027540
5,3422424
6,3126154
7,3284505
8,3302910
9,3083988
10,3420906
11,3297762
12,3683202
13,3552006
14,3100387
15,3315101
16,3557330
17,3642369
18,3433083
19,3626265
20,3428671
21,3382530
22,3655119
23,3287426
24,3908253
25,3519596
26,3137699
27,3448666
28,3608360
29,3655949
30,3562929
31,3848854
32,3567509
33,3627997
34,3672637
35,3507070
36,4265132
37,3469038
38,3229818
39,3596050
40,3829463
41,3584214
42,3705365
43,3891378
44,3645197
45,3759912
46,3730701
47,3618637
48,4452427
49,3492731
50,3452616
51,3902058
52,3609021
53,3919293
54,3987984
55,3771700
56,3932328
57,3830459
58,3789798
59,3842424
60,4359879
61,3671982
62,3467989
63,3941868
64,3764921
65,4103763
66,3957227
67,3885702
68,4118790
69,3716802
70,4035983
71,3997331
72,4346528
73,3891413
74,3594478
75,3917480
76,4067836
77,4244208
78,3945555
79,4134504
80,4169484
81,3937805
82,4328547
83,4101363
84,4569995
85,4223347
86,3737103
87,4036856
88,4195334
89,4471413
90,4227515
91,4442020
92,4207102
93,4175538
94,4535040
95,4114500
96,4805043

data nouvelle;
	infile
	datalines
	delimiter=',';
	input NBOBS Zt ;
datalines;
97,4255165
98,3964556
99,4374796
100,4368262
101,4309399
102,4378021
103,4433864
104,4238053
105,4103298
106,4324460
107,4353789
108,5083421

GOPTIONS RESET=ALL GACCESS='sasgastd > fig_serie.pdf'  DEVICE=PDF;
GOPTIONS FTEXT=ZAPF BORDER ROTATE=LANDSCAPE;
SYMBOL1 V=DOT H=.1 C=BLACK I=JOIN L=1; 
AXIS1 LABEL=('Temps');
AXIS2 LABEL=(a=90 'Serie');
PROC GPLOT DATA=serie;
  PLOT Zt*NBOBS=1 / HAXIS=axis1 HMINOR=0 VAXIS=axis2 VMINOR=0;
TITLE "SERIE ORIGINALE";
RUN; 

/* ================================================================== */
/* ========== Étape 2: Besoin de transformer les données? =========== */
/* ================================================================== */

/*
On peut utiliser comme analyse préliminaire les transformations de type racine,
inverse ou logarithmique afin de constater si la série semble posséder une variance
plus ou moins constante.
*/
DATA transfo;
  SET serie;
  ZtINV = 1/Zt;
  ZtSQRT = SQRT(Zt);
  logZt = LOG(Zt);
RUN;

GOPTIONS RESET=ALL GACCESS='sasgastd > fig_inv.pdf'  DEVICE=PDF;
GOPTIONS FTEXT=ZAPF BORDER ROTATE=LANDSCAPE;
SYMBOL1 V=DOT H=.1 C=BLACK I=JOIN L=1; 
AXIS1 LABEL=('Temps');
AXIS2 LABEL=(a=90 'Serie');
PROC GPLOT DATA=transfo;
  PLOT ZtINV*NBOBS=1 / haxis=axis1 hminor=0 vaxis=axis2 vminor=0;
TITLE "TRANSFORMATION INVERSE";
run; 

GOPTIONS RESET=ALL GACCESS='sasgastd > fig_sqrt.pdf'  DEVICE=PDF;
GOPTIONS FTEXT=ZAPF BORDER ROTATE=LANDSCAPE;
SYMBOL1 V=DOT H=.1 C=BLACK I=JOIN L=1; 
AXIS1 LABEL=('Temps');
AXIS2 LABEL=(a=90 'Serie');
PROC GPLOT DATA=transfo;
  PLOT ZtSQRT*NBOBS=1 / haxis=axis1 hminor=0 vaxis=axis2 vminor=0;
TITLE "TRANSFORMATION RACINE";
run; 

GOPTIONS RESET=ALL GACCESS='sasgastd > fig_log.pdf'  DEVICE=PDF;
GOPTIONS FTEXT=ZAPF BORDER ROTATE=LANDSCAPE;
SYMBOL1 V=DOT H=.1 C=BLACK I=JOIN L=1; 
AXIS1 LABEL=('Temps');
AXIS2 LABEL=(a=90 'Serie');
PROC GPLOT DATA=transfo;
  PLOT logZt*NBOBS=1 / haxis=axis1 hminor=0 vaxis=axis2 vminor=0;
TITLE "TRANSFORMATION LOG";
run; 

/* 
Remarques:
1.  En principe, à moins de bizarreries extraordinaires, vous devriez décider de:
    i)  Ne pas transformer.
    ii) Prendre l'une des trois transformations populaires: racine, inverse ou log.

2.  La méthode de Box-Cox offre l'avantage d'être plus objective.  Elle repose sur
    une approximation par un AR(p).  Puisqu'on soupçonne que les données sont saisonnières
    et avec une composante saisonnière, il est avantageux de prendre un p assez grand 
    (p=5 et même plus grand, par exemple p=20, tout dépendant de la taille de la série).  
*/

/* =============== Definition d'un nouveau jeu de données =============== */
DATA serie2;
  SET serie;
  Zttrans = Zt;
RUN;
/*
Remarque: Vous remarquerez que par défaut, Zttrans est définie comme la série originale.  Si vous
          décidez de transformer, vous devez l'indiquer dans le jeu de données ci-dessus.  Ceci a
          des implications lors du calcul des prévisions, puisque transformer implique
          un changement d'échelle.  Par exemple, si vous décider de transformer avec logarithmique, vous
          devez prendre l'exponentielle pour revenir dans l'échelle originale.
*/

/* ================================================================= */
/* ======== Étape 3: Retrait d'une composante saisonnière? ========= */
/* ================================================================= */
PROC ARIMA DATA=serie2;
  IDENTIFY VAR=Zttrans  NLAG=36;
	title "Transformation stationnaire?";
RUN;
/*  
La plupart des séries sur CANSIM/CANSIMII affichent une forte composante saisonnière, et il
est habituellement souhaitable de considérer la composante 1-B**12.  Vous devriez considérer
sérieusement cette possibilité.  On considère un nombre de délais élevés afin de regarder ce 
qui se passe autour des délais saisonniers 12, 24, 36,...
*/




/* ================================================================= */
/* ============ Etape 4:  Étude de la stationnarite? =============== */
/* ================================================================= */
/*
L'objectif de cette section est de cerner la question de la stationnarité.
Ainsi, minimalement. est-ce que la série choisie semble stationnaire par rapport à la moyenne?
Si ce n'est pas le cas, il est recommendé de prendre une première différence.  Dans PROC ARIMA,
ceci implique la modélisation de la variable Zttrans(12) = (1-B**12)Zttrans.

L'argumentation se fonde sur un résultat théorique: comme fonction de la taille échantillonnale n, 
c'est-a-dire a mesure que n augmente, pour un délai k fixé, si vous remarquez que les r(k) tendent
dangereusement vers un, vous avez un doute de la stationnarité.  Si vous doutez de la stationnarite, 
vous pouvez considérer de prendre une première différence dite régulière: Zttrans(1) = (1-B)Zttrans.
*/

DATA split1;
  TAILLE = 96;    /* Taille de la s�rie chronologiques */
  SET serie2;
  IF NBOBS < TAILLE/3;
RUN;

DATA split2;
  TAILLE = 96;    /* Taille de la s�rie chronologiques */
  SET serie2;
  IF NBOBS < 2*TAILLE/3;
RUN;

PROC ARIMA DATA=split1;
  IDENTIFY VAR=Zttrans(1)  NLAG=36;
	title "Transformation avec d = 1";
RUN;
PROC ARIMA DATA=split2;
  IDENTIFY VAR=Zttrans(1)  NLAG=36;
	title "Transformation avec d = 1";
RUN;
PROC ARIMA DATA=serie2;
  IDENTIFY VAR=Zttrans(1)  NLAG=36;
	title "Transformation avec d = 1";
RUN;

/*
  Vous pouvez repeter la petite analyse de cette section avec (1-B**12)Zttrans.
*/

PROC ARIMA DATA=split1;
  IDENTIFY VAR=Zttrans(12)  NLAG=36;
	title "Transformation avec d = 12";
RUN;
PROC ARIMA DATA=split2;
  IDENTIFY VAR=Zttrans(12)  NLAG=36;
	title "Transformation avec d = 12";
RUN;
PROC ARIMA DATA=serie2;
  IDENTIFY VAR=Zttrans(12)  NLAG=36;
	title "Transformation avec d = 12";
RUN;


/* ================================================================= */
/* ============= Conclusion de l'étape d'identification ============ */
/* ================================================================= */
/*
  À ce stade, vous pensez disposer d'une certaine serie
  stationnaire, et il est temps d'utiliser PROC ARIMA de SAS.  
  Si vous decidez par exemple de considerer (l-B)(1-B^12), alors
  vous devrez en tenir compte dans l'énoncé IDENTIFY de PROC ARIMA.  
  Si une première différence régulière et une première différence saisonnière
  sont requises, alors dans PROC ARIMA vous devrez spécifier Zttrans(1,12).
  Remarque: si deux différences régulières sont requises, vous devez spécifier
            Zttrans(1,1) = (1-B)**2 Zttrans.  Si vous spécifier Zttrans(2), vous obtiendrez
            la différentiation (1-B**2) Zttransf qui n'est pas équivalente à 
            Zttrans(1,1) = (1-B)**2 Zttrans = (1- 2*B + B**2) Zttrans.
*/

PROC ARIMA DATA=serie;
	title 'Estimation and prediction - d = 12 p =(3) q = (1,12)';
  /*===== ETAPE 1: IDENTIFICATION =====*/
  IDENTIFY VAR=Zt(12) NLAG=24;             /* Etape d'identification */

 /*=====Les modeles=====*/
 /* 
   IDENTIFY VAR=Ztt(1);       (1-B)Zt 
   ESTIMATE p=(12) q=(12) METHOD=ULS PLOT PRINTALL;  (1-phi12B**12)Zt = (1-theta12B**12)at;

   IDENTIFY VAR=Ztt(12);       (1-B**12)Zt 
   ESTIMATE p=(3) q=(1)(12) METHOD=uls PLOT PRINTALL ;  (1- phi3*B**3)Zt = (1-theta1* B)(1-theta12* B**12)at;
   ESTIMATE p=(3) q=(1,12) METHOD=ULS PLOT PRINTALL;  (1-phi3*B**3)Zt = (1-theta1B-theta12B**12)at;
*/

 /*===== ETAPE 2: ESTIMATION  =====*/
   ESTIMATE p=(3) q=(1)(12)  METHOD=uls PLOT PRINTALL;  /*  Etape d'estimation par
                                              la m�thode de moindres carr�s inconditionnelse */
 /*  D'autres m�thodes: CLS (moindres carr�s conditionnels);
                        mls (moindres carr�s inconditionnels);
 */

/*=====CALCUL DES PREVISIONS=====*/
   FORECAST OUT=out BACK=0 LEAD=12 ID=NBOBS; 	/* Exemple de prevision; Les resultats vont dans le DATA out */
	
/* 
  Remarque: le nombre associ� � l'�nonc� LEAD doit etre �gal au nombre de donn�es dans
	      le fichier nouvelles.dat.  Ici cette valeur vaut 5.  Si vous tronquez une
            ann�e enti�re de donn�es mensuelles cela pourrait valoir 12.
*/

RUN;

DATA combiner;
	MERGE serie out;
RUN;

/* =========================================================== */
/* ============= Etape 7: Premier graphique  ================= */
/* =========================================================== */
DATA retrans;
  SET combiner;
  L95orig = L95;
  U95orig = U95;
  PREVorig = forecast;
RUN;

/*
 Remarque: Si vous avez transforme les donnees, les commandes du bloc precedent
           sont inexactes.
 Exemple d'utilisation: Si Zttrans = log(serie), alors:
                        L95orig = EXP(L95);
                        U95orig = EXP(U95);
                        PREVorig = EXP(forecast);
*/


DATA prevout;
  SET retrans;
  IF NBOBS <= 96;  /*  Cette valeur est le nombre d'observations de la serie originale */
RUN;

GOPTIONS RESET=ALL GACCESS='sasgastd > bandes_prev.pdf'  DEVICE=PDF;
GOPTIONS FTEXT=ZAPF BORDER ROTATE=LANDSCAPE;
SYMBOL1 V=DOT H=.1 C=BLACK I=JOIN L=1; 
SYMBOL2 V=DOT H=.1 C=BLACK I=JOIN L=3;
AXIS1 LABEL=('Temps');
AXIS2 LABEL=(a=90 'Serie');
PROC GPLOT DATA=prevout;
  PLOT Zt*NBOBS=1 l95orig*NBOBS=2 u95orig*NBOBS=2 
       /overlay haxis=axis1 hminor=0 vaxis=axis2 vminor=0;
TITLE "SERIE ET BANDES DE PREVISIONS (ECHELLE ORIGINALE)";
run; 

/* =========================================================== */
/* ============= Etape 8: Second graphique  ================== */
/* =========================================================== */
DATA perfout;
  SET retrans;
  IF NBOBS >= 97; /*  Cette valeur devrait etre n+1 ou n est le nombre d'observations de la serie originale */
RUN;

DATA perfout2;
  MERGE nouvelle perfout (DROP= NBOBS Zt L95 U95 FORECAST); 
RUN;

GOPTIONS RESET=ALL GACCESS='sasgastd > prev_obsfutures.pdf'  DEVICE=PDF;
GOPTIONS FTEXT=ZAPF BORDER ROTATE=LANDSCAPE;
SYMBOL1 V='P' H=1 C=RED I=JOIN; 
SYMBOL2 V='R' H=1 C=BLACK I=JOIN;
SYMBOL3 V=DOT H=0.1 C=BLACK I=JOIN L=3;
AXIS1 LABEL=('Temps');
AXIS2 LABEL=(a=90 'Serie');
PROC GPLOT DATA=perfout2;
  PLOT prevorig*NBOBS=1 Zt*NBOBS=2 l95orig*NBOBS=3 u95orig*NBOBS=3 
       /overlay haxis=axis1 hminor=0 vaxis=axis2 vminor=0;
TITLE "PREVISIONS ET BANDES DE PREVISIONS (ECHELLE ORIGINALE)";
run; 

/* ============================================================ */
/* ========= Etape 9: Performance pr�visionnelle  ============= */
/* ============================================================ */
data performance;
	set perfout2;
	sqrt_err = (Zt - PREVorig)**2;
run;
/*
PROC PRINT DATA=perfout2;
RUN;
*/
PROC PRINT DATA=performance;
RUN;

/* Calculer MSE des previsions */
proc sql;
    select sum(sqrt_err)/12 as MSE
    from performance;
quit;

ODS PDF CLOSE;