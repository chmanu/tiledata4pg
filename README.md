This tool is a postgresql extension which aims to produce tile tables from measure or geodata tables.

These new tables can be used to generate heatmap with an optimized method.

Example: From an essai_healpix table with lat and long fields corresponding to lattitude and longitude, we will build two tables with less resolution by aggregating var1 and var2 values (average, count, min and max) for each area corresponding to spere pixels.

Use:
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


-- healpix table bulding with level 4 and 6 based on variables var1 and var2 of the essai_healpix table
select build_tuilage('public', 'essai_healpix', array['lat', 'long'], array[4, 6], array['var1', 'var2']);
  build_tuilage
----------------------
No error on build.
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

In term of response time, there is no comparison.

Author : Manuel Pavy - Manuel.Pavy@cnes.fr



