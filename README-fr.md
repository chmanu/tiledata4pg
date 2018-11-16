Cet outil est une extension postgreSQL permettant de générer des tables de tuilages des données issues de tables de mesures.

Ces tables permettent une génération des heatmaps de manière optimisée.

Ainsi, à partir d'une table essai_healpix contenant des colonnes lat et long respectivement pour la lattitude et la longitude, nous allons construire deux tables de résolution plus faible et agrégeant les données des valeurs var1 et var2 (moyenne, nombre, min, max) pour chaque zone correspondant à des pixels de sphère.

Utilisation:
---
```
\d essai_healpix
                  Table "public.essai_healpix"
        Column         |            Type             | Modifiers
-----------------------+-----------------------------+-----------
 lat                   | double precision            |
 long                  | double precision            |
 var1                  | real                        |
 var2                  | real                        |
 var3                  | real                        |
 var4                  | real                        |


-- création de table de niveau healpix 4 et 6 sur les variables var1 et var2 de la table essai_healpix
select build_tuilage('public', 'essai_healpix', array['lat', 'long'], array[4, 6], array['var1', 'var2']);
                                 build_tuilage
-------------------------------------------------------------
 aucune erreur détectée à la création des tables de tuilages
(1 row)

Time: 225411.747 ms


\d essai_healpix_4
   Table "tuilage_data.essai_healpix_4"
       Column       |  Type   | Modifiers
--------------------+---------+-----------
 healpix            | bigint  |
 var1_avg           | real    |
 var1_max           | real    |
 var1_min           | real    |
 var1_nb            | integer |
 var2_avg           | real    |
 var2_max           | real    |
 var2_min           | real    |
 var2_nb            | integer |



select count(var1), count(*)  from essai_healpix ;
  count   |  count
----------+----------
 19116663 | 24478627
(1 row)

Time: 8754.811 ms



select sum(var1_nb), count(*) from essai_healpix_4;
   sum    | count
----------+-------
 19116663 |  2848
(1 row)

Time: 1.503 ms


```

La différence de temps de réponse est sans commune mesure.


Author : Manuel Pavy - Manuel.Pavy@cnes.fr



