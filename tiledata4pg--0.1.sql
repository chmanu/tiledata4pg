--
--
--  TILEDATA4PG extension
--
--  Description : This postgresql extension is based on healpix algorithm powered by pg_healpix
--		It aims to get pixellized data from geodata table.
-- 
-- Copyright (C)
--
--  Author : Manuel Pavy - Manuel.Pavy@cnes.fr
--
--  Contributors : Manuel Pavy - CNES

create schema tuilage;
create schema tuilage_data;

SELECT set_config('search_path', current_setting('search_path') || ',tuilage, tuilage_data', false);
set local search_path to tuilage, tuilage_data;

-- install pg_healpix (in my schema)
CREATE OR REPLACE FUNCTION healpix_ang2ipix_nest(bigint, double precision, double precision)
        RETURNS bigint
        AS '$libdir/pg_healpix', 'pgheal_ang2ipix_nest'
        LANGUAGE C IMMUTABLE STRICT;
COMMENT ON FUNCTION healpix_ang2ipix_nest (bigint, double precision, double precision)
        IS 'Function converting nside, Ra and Dec to the healpix nested ipix value';

CREATE OR REPLACE FUNCTION healpix_ang2ipix_ring(bigint, double precision, double precision)
        RETURNS bigint
        AS '$libdir/pg_healpix', 'pgheal_ang2ipix_ring'
        LANGUAGE C IMMUTABLE STRICT;
COMMENT ON FUNCTION healpix_ang2ipix_ring (bigint, double precision, double precision)
        IS 'Function converting nside, Ra and Dec to the healpix ring ipix value';

CREATE OR REPLACE FUNCTION healpix_ipix2ang_nest(nside bigint, ipix bigint)
        RETURNS double precision[]
        AS '$libdir/pg_healpix', 'pgheal_ipix2ang_nest'
        LANGUAGE C IMMUTABLE STRICT;
COMMENT ON FUNCTION healpix_ipix2ang_nest(bigint, bigint)
        IS 'Function converting the Healpix nested ipix value to Ra, Dec';

CREATE OR REPLACE FUNCTION healpix_ipix2ang_ring(nside bigint, ipix bigint)
        RETURNS double precision[]
        AS '$libdir/pg_healpix', 'pgheal_ipix2ang_ring'
        LANGUAGE C IMMUTABLE STRICT;
COMMENT ON FUNCTION healpix_ipix2ang_ring(bigint, bigint)
        IS 'Function converting the Healpix ring ipix value to Ra, Dec';



create table tuilage_settings (name varchar(50), setting varchar(200));
insert into tuilage_settings (name, setting) values 
('lang','FR'),
('integrity','1');

create table error_message (errcode varchar(20), lang char(2), errmessage text,
constraint pk_error_message primary key (errcode, lang));
insert into error_message (errcode, lang, errmessage) values 
('levelpos','FR',' : valeur incorrecte : Vous devez choisir un niveau positif.'),
('taillecol','FR',' : valeur incorrecte : La taille du nom de colonne doit être inférieure à 59. '),
('tailletab','FR',' : valeur incorrecte : La taille du nom de table doit être inférieure à 59.'),
('tuilageexiste','FR','Un tuilage existe déjà avec ce nom de table, opération impossible. Essayez select drop_tuilage(NOMTABLE).'),
('coordformat','FR','Vous devez spécifier les colonnes des coordonnées sous la forme d un tableau de 2 dimensions'),
('buildsucces','FR','aucune erreur détectée à la création des tables de tuilages'),
('dropsucces','FR','aucune erreur détectée à la suppression des tables de tuilages'),
('levelpos','EN',' : incorrect value : You must have positive value.'),
('taillecol','EN',' : incorrect value : The column name length must be less than 59 characters. '),
('tailletab','EN',' : incorrect value : The table name length must be less than 59 characters.'),
('tuilageexiste','EN','Data already exists. You should try select drop_tuilage(NOMTABLE).'),
('coordformat','EN','Coordinates must be a array of two column name;'),
('buildsucces','EN','No error on build.'),
('dropsucces','EN','No error on drop');


create or replace function tuilage_message(p_code text)
returns text as $$
begin
return (select  errmessage from error_message where lang = (select setting from tuilage_settings where name='lang') and errcode = p_code);
end
$$
language plpgsql;


create or replace function build_tuilage(sc text, tab text, coord text[], hips_level int[], col text[])
returns text as $build$
declare
t_exequery text='';
lev int=0;
macol text='';
tiles int=0;
tuilage_exist int=0;
p_integrity int = 0;
begin
-- Check prerequesites
select 1 from pg_tables where schemaname = 'tuilage_data' and tablename like '' || tab || '%' into tuilage_exist;
if (tuilage_exist > 0) then return  tuilage_message('tuilageexiste') ; end if;
if char_length(tab) > 59  then return tab || tuilage_message('tailletab') ; end if;
if array_length(coord, 1) <> 2 then return tuilage_message('coordformat'); end if;
<<level_prereq>>
foreach lev in array hips_level loop
    if (lev < 0) then return lev || tuilage_message('levelpos') ; end if;
end loop level_prereq;
<<col_taille_prereq>>
foreach macol in array col loop 
    if char_length(macol) > 59 then return macol || tuilage_message('taillecol'); end if;
end loop col_taille_prereq;

-- create tables
<<level_table>>
foreach lev in array hips_level loop
    tiles = power(2,lev);
    t_exequery =  'create table tuilage_data.' || tab || '_' || lev || ' as select healpix_ang2ipix_nest('|| tiles || ', '||coord[1] || ', ' || coord[2] ||') healpix'; 
    
    <<col_column>>
    foreach macol in array col loop 
    t_exequery = t_exequery || ', avg(' || macol || ')::real ' || macol || '_avg, max(' || macol || ')::real ' || macol || '_max, min(' || macol || ')::real ' || macol || '_min, count(' || macol || ')::int ' || macol || '_nb';
    end loop col_column;
    
    t_exequery = t_exequery || ' from ' || sc || '.' || tab || ' group by healpix_ang2ipix_nest(' || tiles || ', '||coord[1] || ', '||coord[2] || ');';
    
    execute t_exequery;
end loop level_table;


-- create fct trigger
select setting::int into p_integrity from tuilage_settings where name='integrity';
if (p_integrity = 1) then
      t_exequery = 'create or replace function ft_' || tab || ' () ';
      t_exequery = t_exequery || 'returns trigger as $$ ';
      t_exequery = t_exequery || 'begin ';
      t_exequery = t_exequery || 'IF (TG_OP = ''DELETE'') THEN ';
      <<tr_tab_tuil_del>>
      foreach lev in array hips_level loop
            t_exequery = t_exequery || 'update tuilage_data.' || tab || '_' || lev;
            t_exequery = t_exequery || ' set ';
            <<tr_col_del>>                
            foreach macol in array col loop 
                t_exequery = t_exequery || macol || '_avg = case when old.'|| macol || '   > 0 then ('|| macol || '_avg * '|| macol || '_nb - old.'|| macol || ')/('|| macol || '_nb -1) else '|| macol || '_avg end, ';
                t_exequery = t_exequery || macol || '_max = nullif('|| macol || '_max, old.'|| macol || '), ';
                t_exequery = t_exequery || macol || '_min = nullif('|| macol || '_min, old.'|| macol || '), ';
                t_exequery = t_exequery || macol || '_nb = case when old.'|| macol || '   > 0 then '|| macol || '_nb -1 else '|| macol || '_nb  end, ';
            end loop tr_col_del;
            t_exequery = t_exequery || ' healpix = healpix where healpix = healpix_ang2ipix_nest(power(2,'|| lev || ')::int, old.'||coord[1]||', old.'||coord[2]||');';
      end loop tr_tab_tuil_del;
      
      t_exequery = t_exequery || 'ELSIF (TG_OP = ''UPDATE'') THEN ';
      <<tr_tab_tuil_upd>>
      foreach lev in array hips_level loop
            t_exequery = t_exequery || 'update tuilage_data.' || tab || '_' || lev;
            t_exequery = t_exequery || ' set ';
            <<tr_col_upd>>                
            foreach macol in array col loop 
                t_exequery = t_exequery || macol || '_avg = case when old.'|| macol || '   > 0 then ('|| macol || '_avg * '|| macol || '_nb - old.'|| macol || '+ new.'|| macol || ')/('|| macol || '_nb ) else '|| macol || '_avg end, ';
                t_exequery = t_exequery || macol || '_max = case when '|| macol || '_max - old.'|| macol || ' > 0 then greatest('|| macol || '_max, new.'|| macol || ') else  null end, ';
                t_exequery = t_exequery || macol || '_min = case when '|| macol || '_min - old.'|| macol || ' < 0 then least('|| macol || '_min, new.'|| macol || ') else  null end, ';
            end loop tr_col_upd;
            t_exequery = t_exequery || ' healpix = healpix where healpix = healpix_ang2ipix_nest(power(2,'|| lev || ')::int, old.'||coord[1]||', old.'||coord[2]||');';
      end loop tr_tab_tuil_upd;
      
      t_exequery = t_exequery || 'ELSIF (TG_OP = ''INSERT'') THEN ';
      <<tr_tab_tuil_ins>>
      foreach lev in array hips_level loop
            t_exequery = t_exequery || 'update tuilage_data.' || tab || '_' || lev;
            t_exequery = t_exequery || ' set ';
            <<tr_col_ins>>                
            foreach macol in array col loop 
            -- le min et le max peuvent être calculé plus souvent (cas d un non changement) 
                t_exequery = t_exequery || macol || '_avg = case when new.'|| macol || '   > 0 then  (('|| macol || '_avg * '|| macol || '_nb) + new.'|| macol || ')/('|| macol || '_nb + 1) else '|| macol || '_avg end, ';
                t_exequery = t_exequery || macol || '_max = greatest('|| macol || '_max, new.'|| macol || '), ';
                t_exequery = t_exequery || macol || '_min = least('|| macol || '_min, new.'|| macol || '), ';
                t_exequery = t_exequery || macol || '_nb = '|| macol || '_nb +1 , ';
            end loop tr_col_ins;
            t_exequery = t_exequery || ' healpix = healpix where healpix = healpix_ang2ipix_nest(power(2,'|| lev || ')::int, new.'||coord[1]||', new.'||coord[2]||');';
      end loop tr_tab_tuil_ins;      
      t_exequery = t_exequery || ' ';
      t_exequery = t_exequery || 'END IF; ';
      t_exequery = t_exequery || 'return null; ';
      t_exequery = t_exequery || 'end; ';
      t_exequery = t_exequery || '$$ ';
      t_exequery = t_exequery || 'LANGUAGE plpgsql;';
execute t_exequery;
elsif (p_integrity = 2) then
          -- recalcul complet pour chaque valeur healpix trouvé
          null;
end if;


-- create trigger
t_exequery = t_exequery || 'CREATE TRIGGER tr_' || tab || ' ';
t_exequery = t_exequery || 'BEFORE INSERT or update or delete ON ' || tab || ' ';
t_exequery = t_exequery || 'FOR EACH ROW EXECUTE PROCEDURE ft_' || tab || '(); ';

execute t_exequery;

return tuilage_message('buildsucces');
end
$build$
language plpgsql;


create or replace function drop_tuilage(tab text)
returns text as $$
declare
matab text = '';
tab_pct text = tab || '%';
v_cursor cursor(tab text) for select tablename from pg_tables where schemaname = 'tuilage_data' and tablename like tab_pct;
begin
open v_cursor(tab);
loop
      fetch v_cursor into matab;
      exit when not found;
       
      execute 'drop table tuilage_data.' || matab;
end loop;
execute 'drop trigger tr_'|| tab || ' on ' || tab ||';';
execute 'drop function ft_'|| tab || '() ;';
return tuilage_message('dropsucces');
end
$$
language plpgsql;





