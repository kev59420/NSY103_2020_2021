#!/bin/bash

#fonction consultation de l'api de l'equipe avec en paramètre $1=championnat $2=saison $3=journnee

consultation ()

{
	adresse_json="https://iphdata.lequipe.fr/iPhoneDatas/EFR/STD/ALL/V1/Football/CalendarList/CompetitionPhase/$1/$2/$3-journee.json"

	#recupération du json sur le site l'equipe

	current_json=$(curl -s $adresse_json > current.json)

	#mise en place d'une nouvelle structure json

	echo "{\n \"match\":[" > match.json

	#calcul du nombre d'items coresspondant au nombre de jours de match

	iteration_un=$( jq '.items | length' < current.json)
	iteration_un=$(( $iteration_un - 1))

	# parcours de chaque match

	for i in `seq 0 $iteration_un`
	do

		#calcul du nombre d'items coresspondant au nombre de match par journée

		iteration_deux=$( jq ".items[$i].items | length" < current.json)
		iteration_deux=$(( $iteration_deux - 1))

		for j in `seq 0 $iteration_deux`
		do

			#parcours des matchs de la journée et récupérations des données dans le fichier match.json

			if [ $i != 0 ] || [ $j != 0 ]
			then
				echo "," >> match.json
			fi

			#possible de parse les scores en string via number to pipe | tonumber
			
			$( jq "{\"domicile\":.items[$i].items[$j].event.specifics.domicile.equipe.nom, 
				\"exterieur\":.items[$i].items[$j].event.specifics.exterieur.equipe.nom,
				\"score_dom\":.items[$i].items[$j].event.specifics.score.domicile,
				\"score_ext\":.items[$i].items[$j].event.specifics.score.exterieur,
				\"date_evenement\":.items[$i].items[$j].event.date | split(\"T\") ,
				\"id\":.items[$i].items[$j].event.lien_web | capture(\"(?<id>[0-9]{6})\") }" < current.json >> match.json)
		done
		
	done

	echo "]}" >> match.json

	#Affichage des résultats

	#Parcours des matchs

	iteration_trois=$( jq ".match | length" < match.json)
	iteration_trois=$(( $iteration_trois - 1))

	echo "
			Championnat : $championnat
			Journee : $journee

			"
	for i in `seq 0 $iteration_trois`
		do
			echo "
			$( jq ".match[$i].domicile" < match.json) $( jq ".match[$i].score_dom" < match.json)-$( jq ".match[$i].score_ext" < match.json) $( jq ".match[$i].exterieur" < match.json)"

	done

}

#fonction consultation de la base de donnée match

consultationBDD ()

{		
		read -p "

		Lancer une requête SQL sur la table match avec comme argument : 

		domicile, score_dom, score_ext, exterieur, date
			
			" requete

		psql -c " $requete "

}

#fonction enregistrement dans la base de donnée

enregistrementBDD ()

{

	iteration=$( jq ".match | length" < match.json)
	iteration=$(( $iteration - 1))

	for i in `seq 0 $iteration`
	do

	psql -c " INSERT INTO match (domicile, score_dom, score_ext,exterieur,date_evenement) 
		VALUES ( '$( jq -r ".match[$i].domicile" < match.json)',
			'$( jq -r ".match[$i].score_dom" < match.json)',
			'$( jq -r ".match[$i].score_ext" < match.json)',
			'$( jq -r ".match[$i].exterieur" < match.json)',
			'$( jq -r ".match[$i].date_evenement[0]" < match.json)'
		);"

	done

}

#Debut du programme

restart="oui"

while [ $restart = "oui" ]
do

	#initialisation des variables


	choix=0
	saison="current"
	championnat=""
	journee=""
	enregistrement=0

	#Tant que l'utilisateur n'affecte pas la bonne valeur à la variable on recommence

	while [ -z $choix ] || [ $choix -lt 1 ] || [ $choix -gt 6 ]
		do

		read -p "

		Choissisez parmis les choix suivant

			1.Ligue 1
			2.Première league
			3.Serie A
			4.Bundesligua
			5.ligua 
			6.Consulter la Base de données
			7.Quitter
			
			" choix


		case "$choix" in
		            1 ) championnat="ligue-1"
					;;
		            2 ) championnat="championnat-d-angleterre"
		            ;;
		            3 ) championnat="championnat-d-italie"
					;;
		            4 ) championnat="championnat-d-allemagne"
					;;
					5 ) championnat="championnat-d-espagne"
					;;
					6 ) consultationBDD

						# on initialise la variable à 0 lors de la consultation pour revenir au menu

						choix=0
					;;
					7 ) exit
					;;
		            * ) echo " veuillez choisir entre l'un des 7 choix ??"
					;;
		esac

	done

	#reinitialisation de la variable choix

	choix=0

	#tant que l'utilisateur n'affecte pas la bonne valeur à la variable on recommence

	while [ -z $choix ] || [ $choix -lt 1 ] || [ $choix -gt 40 ]
		do

			read -p "

			Choissisez une journée de championnat
			
			" choix

			if [ $choix = 1 ]
				then
					journee="1re"
				else
					journee="${choix}e"
			fi
			
	done

	consultation $championnat $saison $journee

	#Enregistrement dans la base de donnée

	while [ $enregistrement != "oui" ] && [ $enregistrement != "non" ] || [ -z $enregistrement ]
		do

		read -p "

				Souhaitez vous enregistrer les informations dans la base de données ?
				
				-	oui
				-	non

				" enregistrement

		case "$enregistrement" in

					"oui" ) enregistrementBDD
					;;
					"non" )
					;;
		            * ) echo "veuillez choisir oui ou non ??"
					;;
		esac

	done


	#Demande si volonté de vouloir reconsulté de nouveaux match

	restart=0



	while [ $restart != "oui" ] && [ $restart != "non" ] || [ -z $restart ]
		do

		read -p "

				Souhaitez vous consulter d'autre score ?
				
				-	oui
				-	non

				" restart
			
		if [ $restart != "oui" ] && [ $restart != "non" ]

			then
				echo " veuillez enrez soit oui soit non "
		fi
	done

done