Firsofall, you need to clone pg_healpix project into the pg_healpix subdirectory from https://github.com/segasai/pg_healpix .


tiledata4pg--x.x.sql and tiledata4pg.control files should be copied into extension directory :
```
systemctl show postgresql-9.6.service | grep postmaster
```
which give you the binary path, we deduct the extension path :
```
cp tiledata4pg--x.x.sql /usr/pgsql-9.6/share/extension/
cp tiledata4pg.control /usr/pgsql-9.6/share/extension/
```

Build the code (C compilator is required) :
---
```
make
sudo make install
```
Check the library is generated :
```
ls -l /usr/pgsql-9.6/lib/pg_healpix.so
-rwxr-xr-x 1 root root 66144 Oct 12 15:15 /usr/pgsql-9.6/lib/pg_healpix.so

```

Load the postgreSQL extension
---
From a psql session :
```
create extension tiledata4pg;
```


To check the installation, check that functions have been created: 
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




