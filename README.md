# NSY103_2020_2021
sujet examen KEVIN DEBONNET NSY103_2020_2021

Descriptif : Le programme permet de consulter les scores des grands championnat de foot directement via l'invité de commande et propose d'enregistrer les resultats dans une base de donnée.



Afin que le programme soit fonctionnel il est impératif de posséder une base de donnée, ici j'utilise postgreSQL téléchargeable : https://www.postgresql.org/download/

de plus il faut creer une table match, ci joint le code SQL : 

CREATE TABLE match ( domicile varchar(80), score_dom int, score_ext int, exterieur varchar(80), date_evenement date)
