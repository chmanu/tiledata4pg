
En premier lieu, il vous faut cloner le projet pg_healpix dans le sous répertoire correspondant (pg_healpix) à partir de https://github.com/segasai/pg_healpix .

Les fichiers tiledata4pg--x.x.sql et tiledata4pg.control doivent être copiés dans le répertoire des extensions :
```
systemctl show postgresql-9.6.service | grep postmaster
```
donne le chemin des binaires, on en déduit le répertoire des extensions:
```
cp tiledata4pg--x.x.sql /usr/pgsql-9.6/share/extension/
cp tiledata4pg.control /usr/pgsql-9.6/share/extension/
```


Compiler le code (un compilateur C est requis) :
---
```
make
sudo make install
```
Vérifier que la librairie est bien générée :
```
ls -l /usr/pgsql-9.6/lib/pg_healpix.so
-rwxr-xr-x 1 root root 66144 Oct 12 15:15 /usr/pgsql-9.6/lib/pg_healpix.so

```

Charger l'extension postgresql
---
Depuis une session psql interactive :
```
create extension tiledata4pg;
```


Pour vérifier la bonne installation, vérifier la création des fonctions dans le schéma tuilage:
```
\df
                                                         List of functions
 Schema  |         Name          |  Result data type  |                        Argument data types                        |  Type
---------+-----------------------+--------------------+-------------------------------------------------------------------+--------
 tuilage | build_tuilage         | text               | sc text, tab text, coord text[], hips_level integer[], col text[] | normal
 tuilage | drop_tuilage          | text               | tab text                                                          | normal
 tuilage | healpix_ang2ipix_nest | bigint             | bigint, double precision, double precision                        | normal
 tuilage | healpix_ang2ipix_ring | bigint             | bigint, double precision, double precision                        | normal
 tuilage | healpix_ipix2ang_nest | double precision[] | nside bigint, ipix bigint                                         | normal
 tuilage | healpix_ipix2ang_ring | double precision[] | nside bigint, ipix bigint                                         | normal
 tuilage | tuilage_message       | text               | p_code text                                                       | normal
(7 rows)
```




