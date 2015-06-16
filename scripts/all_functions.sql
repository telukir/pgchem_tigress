-- Function: add_hydrogens(molecule, boolean, boolean)

-- DROP FUNCTION add_hydrogens(molecule, boolean, boolean);

CREATE OR REPLACE FUNCTION add_hydrogens(molecule, boolean, boolean)
  RETURNS molecule AS
'libpgchem', 'pgchem_add_hydrogens'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION add_hydrogens(molecule, boolean, boolean) OWNER TO postgres;

-- Function: canonical_smiles(molecule, boolean)

-- DROP FUNCTION canonical_smiles(molecule, boolean);

CREATE OR REPLACE FUNCTION canonical_smiles(molecule, boolean)
  RETURNS text AS
'libpgchem', 'pgchem_molecule_to_canonical_smiles'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION canonical_smiles(molecule, boolean) OWNER TO postgres;

-- Function: check_fingerprint_optimization(text, text, text)

-- DROP FUNCTION check_fingerprint_optimization(text, text, text);

CREATE OR REPLACE FUNCTION check_fingerprint_optimization(t_schema text, t_name text, s_column text)
  RETURNS double precision AS
$BODY$
DECLARE i float8;
DECLARE tablesize integer;
DECLARE t_q_name text;
DECLARE t_b_name text;
BEGIN

t_q_name := t_schema || '.q_c_' || t_name;
t_b_name := t_schema || '.' || t_name;

EXECUTE 'DROP TABLE IF EXISTS '||t_q_name;

EXECUTE 'CREATE TABLE ' || t_q_name || ' AS SELECT ' || s_column || ' FROM ' || t_b_name || ' WHERE fp2string('||s_column||') IN (SELECT fp2string('||s_column||') FROM ' || t_b_name || ' GROUP BY fp2string('||s_column||') HAVING (COUNT(fp2string('||s_column||'))>1))';

EXECUTE 'UPDATE '||t_q_name||' SET structure=mutabor('||s_column||')';

EXECUTE 'SELECT COUNT(1) FROM (SELECT count(fpstring('||s_column||')) as count FROM '||t_q_name||' GROUP BY fpstring('||s_column||')) as t WHERE t.count = 1' into i;

EXECUTE 'SELECT COUNT(1) FROM '||t_q_name into tablesize;

EXECUTE 'DROP TABLE IF EXISTS '||t_q_name;

RETURN i/tablesize;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION check_fingerprint_optimization(text, text, text) OWNER TO postgres;

-- Function: create_random_sample_q_table(text, text, text)

-- DROP FUNCTION create_random_sample_q_table(text, text, text);

CREATE OR REPLACE FUNCTION create_random_sample_q_table(t_schema text, t_name text, s_column text)
  RETURNS void AS
$BODY$
DECLARE n numeric;
DECLARE i integer;
DECLARE largeN integer;
DECLARE ts_size integer;
DECLARE t numeric;
DECLARE p numeric;
DECLARE q numeric;
DECLARE d numeric;
DECLARE numerator numeric;
DECLARE denominator numeric;
DECLARE t_q_name text;
DECLARE t_s_q_name text;
BEGIN

t:=1.96;
p:=0.5;
q:=0.5;
d:=0.05;

t_q_name := t_schema || '.q_' || t_name; 
t_s_q_name := t_schema || '.s_q_' || t_name; 

EXECUTE 'DROP TABLE IF EXISTS '||t_s_q_name;

EXECUTE 'CREATE TABLE '||t_s_q_name||' ('||s_column||' molecule) WITH (OIDS=FALSE)';

EXECUTE 'SELECT count(1) from '||t_q_name into largeN;

numerator:=t^2*(p*q);

denominator:=d^2;

n:=round((numerator/denominator),0);

--raise info 'n=%',n;

IF (n/largeN >= 0.05) THEN
n := round(((numerator/denominator)/((((numerator/denominator)-1.0)/largeN)+1.0))::numeric,0);
END IF;

--raise info 'n=%',n;

FOR i IN 1..n LOOP

EXECUTE 'INSERT INTO '||t_s_q_name||' (SELECT structure from '||t_q_name||' WHERE fp2string('||s_column||')=(SELECT fp2string('||s_column||') FROM '||t_q_name||' ORDER BY RANDOM() LIMIT 1))';

END LOOP;

EXECUTE 'SELECT count(1) from '||t_s_q_name into ts_size;

--raise info 'ts_size=%',ts_size;

IF (ts_size>=largeN) THEN
BEGIN
RAISE INFO 'Sampling has no effect. Retaining original table.';
EXECUTE 'DROP TABLE IF EXISTS '||t_s_q_name;
END;
ELSE
BEGIN
EXECUTE 'DROP TABLE IF EXISTS '||t_q_name;
EXECUTE 'ALTER TABLE '||t_s_q_name||' RENAME TO q_' || t_name;
END;
END IF;

RETURN;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION create_random_sample_q_table(text, text, text) OWNER TO postgres;

-- Function: delebor(molecule)

-- DROP FUNCTION delebor(molecule);

CREATE OR REPLACE FUNCTION delebor(molecule)
  RETURNS molecule AS
'libpgchem', 'pgchem_blank_fp'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION delebor(molecule) OWNER TO postgres;

-- Function: disconnected(molecule)

-- DROP FUNCTION disconnected(molecule);

CREATE OR REPLACE FUNCTION disconnected(molecule)
  RETURNS boolean AS
'libpgchem', 'pgchem_disconnected'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION disconnected(molecule) OWNER TO postgres;

-- Function: exactmass(molecule)

-- DROP FUNCTION exactmass(molecule);

CREATE OR REPLACE FUNCTION exactmass(molecule)
  RETURNS double precision AS
'libpgchem', 'pgchem_exactmass'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION exactmass(molecule) OWNER TO postgres;

-- Function: fgroup_codes(molecule)

-- DROP FUNCTION fgroup_codes(molecule);

CREATE OR REPLACE FUNCTION fgroup_codes(molecule)
  RETURNS text AS
'libpgchem', 'pgchem_fgroup_codes_a'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION fgroup_codes(molecule) OWNER TO postgres;

-- Function: fp2string(molecule)

-- DROP FUNCTION fp2string(molecule);

CREATE OR REPLACE FUNCTION fp2string(struct molecule)
  RETURNS bit varying AS
$BODY$
DECLARE fp bit varying;
BEGIN
fp := substring(fpstring(struct) for 1024);
RETURN fp;
END;
$BODY$
  LANGUAGE 'plpgsql' IMMUTABLE STRICT
  COST 100;
ALTER FUNCTION fp2string(molecule) OWNER TO postgres;

-- Function: fp3string(molecule)

-- DROP FUNCTION fp3string(molecule);

CREATE OR REPLACE FUNCTION fp3string(struct molecule)
  RETURNS bit varying AS
$BODY$
DECLARE fp bit varying;
BEGIN
fp := substring(fpstring(struct) from 1025);
RETURN fp;
END;
$BODY$
  LANGUAGE 'plpgsql' IMMUTABLE STRICT
  COST 100;
ALTER FUNCTION fp3string(molecule) OWNER TO postgres;

-- Function: fpstring(reaction)

-- DROP FUNCTION fpstring(reaction);

CREATE OR REPLACE FUNCTION fpstring(reaction)
  RETURNS bit varying AS
'libpgchem', 'pgchem_r_fp_out'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION fpstring(reaction) OWNER TO postgres;

-- Function: fpstring(molecule)

-- DROP FUNCTION fpstring(molecule);

CREATE OR REPLACE FUNCTION fpstring(molecule)
  RETURNS bit varying AS
'libpgchem', 'pgchem_fp_out'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION fpstring(molecule) OWNER TO postgres;

-- Function: inchi(molecule)

-- DROP FUNCTION inchi(molecule);

CREATE OR REPLACE FUNCTION inchi(molecule)
  RETURNS text AS
'libpgchem', 'pgchem_molecule_to_inchi'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION inchi(molecule) OWNER TO postgres;

-- Function: inchikey(molecule)

-- DROP FUNCTION inchikey(molecule);

CREATE OR REPLACE FUNCTION inchikey(molecule)
  RETURNS text AS
'libpgchem', 'pgchem_molecule_to_inchikey'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION inchikey(molecule) OWNER TO postgres;

-- Function: is_2d(molecule)

-- DROP FUNCTION is_2d(molecule);

CREATE OR REPLACE FUNCTION is_2d(molecule)
  RETURNS boolean AS
'libpgchem', 'pgchem_2D'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION is_2d(molecule) OWNER TO postgres;

-- Function: is_3d(molecule)

-- DROP FUNCTION is_3d(molecule);

CREATE OR REPLACE FUNCTION is_3d(molecule)
  RETURNS boolean AS
'libpgchem', 'pgchem_3D'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION is_3d(molecule) OWNER TO postgres;

-- Function: is_chiral(molecule)

-- DROP FUNCTION is_chiral(molecule);

CREATE OR REPLACE FUNCTION is_chiral(molecule)
  RETURNS boolean AS
'libpgchem', 'pgchem_is_chiral'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION is_chiral(molecule) OWNER TO postgres;

-- Function: is_nostruct(molecule)

-- DROP FUNCTION is_nostruct(molecule);

CREATE OR REPLACE FUNCTION is_nostruct(molecule)
  RETURNS boolean AS
'libpgchem', 'pgchem_is_nostruct'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION is_nostruct(molecule) OWNER TO postgres;

-- Function: lipinsky(molecule)

-- DROP FUNCTION lipinsky(molecule);

CREATE OR REPLACE FUNCTION lipinsky(mol molecule)
  RETURNS text AS
$BODY$
DECLARE parameters text;
BEGIN
parameters := '';

IF number_of_H_donors(mol) > 5 THEN
parameters := parameters || 'A';
END IF;
IF molweight(mol) > 500 THEN
parameters := parameters || 'B';
END IF;
IF logP(mol) > 5.0 THEN
parameters := parameters || 'C';
END IF;
IF number_of_H_acceptors(mol) > 10 THEN
parameters := parameters || 'D';
END IF;

RETURN parameters;
END;
$BODY$
  LANGUAGE 'plpgsql' IMMUTABLE STRICT
  COST 100;
ALTER FUNCTION lipinsky(molecule) OWNER TO postgres;

-- Function: logp(molecule)

-- DROP FUNCTION logp(molecule);

CREATE OR REPLACE FUNCTION logp(molecule)
  RETURNS double precision AS
'libpgchem', 'pgchem_logP'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION logp(molecule) OWNER TO postgres;

-- Function: molecule_contained_in(molecule, molecule)

-- DROP FUNCTION molecule_contained_in(molecule, molecule);

CREATE OR REPLACE FUNCTION molecule_contained_in(molecule, molecule)
  RETURNS boolean AS
'libpgchem', 'molecule_contained_in'
  LANGUAGE 'c' VOLATILE STRICT
  COST 1;
ALTER FUNCTION molecule_contained_in(molecule, molecule) OWNER TO postgres;

-- Function: molecule_contains(molecule, molecule)

-- DROP FUNCTION molecule_contains(molecule, molecule);

CREATE OR REPLACE FUNCTION molecule_contains(molecule, molecule)
  RETURNS boolean AS
'libpgchem', 'molecule_contains'
  LANGUAGE 'c' VOLATILE STRICT
  COST 1;
ALTER FUNCTION molecule_contains(molecule, molecule) OWNER TO postgres;

-- Function: molecule_equals(molecule, molecule)

-- DROP FUNCTION molecule_equals(molecule, molecule);

CREATE OR REPLACE FUNCTION molecule_equals(molecule, molecule)
  RETURNS boolean AS
'libpgchem', 'molecule_equals'
  LANGUAGE 'c' VOLATILE STRICT
  COST 1;
ALTER FUNCTION molecule_equals(molecule, molecule) OWNER TO postgres;

-- Function: molecule_in(bytea)

-- DROP FUNCTION molecule_in(bytea);

CREATE OR REPLACE FUNCTION molecule_in(bytea)
  RETURNS molecule AS
'libpgchem', 'molecule_in_bytea'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION molecule_in(bytea) OWNER TO postgres;

-- Function: molecule_in(character varying)

-- DROP FUNCTION molecule_in(character varying);

CREATE OR REPLACE FUNCTION molecule_in(character varying)
  RETURNS molecule AS
'libpgchem', 'molecule_in_varchar'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION molecule_in(character varying) OWNER TO postgres;

-- Function: molecule_in(text)

-- DROP FUNCTION molecule_in(text);

CREATE OR REPLACE FUNCTION molecule_in(text)
  RETURNS molecule AS
'libpgchem', 'molecule_in_text'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION molecule_in(text) OWNER TO postgres;

-- Function: molecule_in(cstring)

-- DROP FUNCTION molecule_in(cstring);

CREATE OR REPLACE FUNCTION molecule_in(cstring)
  RETURNS molecule AS
'libpgchem', 'molecule_in'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION molecule_in(cstring) OWNER TO postgres;

-- Function: molecule_out(molecule)

-- DROP FUNCTION molecule_out(molecule);

CREATE OR REPLACE FUNCTION molecule_out(molecule)
  RETURNS cstring AS
'libpgchem', 'molecule_out'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION molecule_out(molecule) OWNER TO postgres;

-- Function: molecule_recv(internal)

-- DROP FUNCTION molecule_recv(internal);

CREATE OR REPLACE FUNCTION molecule_recv(internal)
  RETURNS molecule AS
'libpgchem', 'molecule_recv'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION molecule_recv(internal) OWNER TO postgres;

-- Function: molecule_send(molecule)

-- DROP FUNCTION molecule_send(molecule);

CREATE OR REPLACE FUNCTION molecule_send(molecule)
  RETURNS bytea AS
'libpgchem', 'molecule_send'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION molecule_send(molecule) OWNER TO postgres;

-- Function: molecule_similarity(molecule, molecule)

-- DROP FUNCTION molecule_similarity(molecule, molecule);

CREATE OR REPLACE FUNCTION molecule_similarity(molecule, molecule)
  RETURNS double precision AS
'libpgchem', 'molecule_similarity'
  LANGUAGE 'c' VOLATILE STRICT
  COST 1;
ALTER FUNCTION molecule_similarity(molecule, molecule) OWNER TO postgres;

-- Function: molfile(molecule)

-- DROP FUNCTION molfile(molecule);

CREATE OR REPLACE FUNCTION molfile(molecule)
  RETURNS text AS
'libpgchem', 'pgchem_molecule_to_molfile'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION molfile(molecule) OWNER TO postgres;

-- Function: molformula(molecule)

-- DROP FUNCTION molformula(molecule);

CREATE OR REPLACE FUNCTION molformula(molecule)
  RETURNS text AS
'libpgchem', 'pgchem_hillformula'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION molformula(molecule) OWNER TO postgres;

-- Function: molfp_compress(internal)

-- DROP FUNCTION molfp_compress(internal);

CREATE OR REPLACE FUNCTION molfp_compress(internal)
  RETURNS internal AS
'libpgchem', 'molfp_compress'
  LANGUAGE 'c' VOLATILE
  COST 1;
ALTER FUNCTION molfp_compress(internal) OWNER TO postgres;

-- Function: molfp_consistent(internal, internal, integer)

-- DROP FUNCTION molfp_consistent(internal, internal, integer);

CREATE OR REPLACE FUNCTION molfp_consistent(internal, internal, integer)
  RETURNS boolean AS
'libpgchem', 'molfp_consistent'
  LANGUAGE 'c' VOLATILE
  COST 1;
ALTER FUNCTION molfp_consistent(internal, internal, integer) OWNER TO postgres;

-- Function: molfp_decompress(internal)

-- DROP FUNCTION molfp_decompress(internal);

CREATE OR REPLACE FUNCTION molfp_decompress(internal)
  RETURNS internal AS
'libpgchem', 'molfp_decompress'
  LANGUAGE 'c' VOLATILE
  COST 1;
ALTER FUNCTION molfp_decompress(internal) OWNER TO postgres;

-- Function: molfp_in(cstring)

-- DROP FUNCTION molfp_in(cstring);

CREATE OR REPLACE FUNCTION molfp_in(cstring)
  RETURNS molfp AS
'libpgchem', 'molfp_in'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION molfp_in(cstring) OWNER TO postgres;

-- Function: molfp_out(molfp)

-- DROP FUNCTION molfp_out(molfp);

CREATE OR REPLACE FUNCTION molfp_out(molfp)
  RETURNS cstring AS
'libpgchem', 'molfp_out'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION molfp_out(molfp) OWNER TO postgres;

-- Function: molfp_penalty(internal, internal, internal)

-- DROP FUNCTION molfp_penalty(internal, internal, internal);

CREATE OR REPLACE FUNCTION molfp_penalty(internal, internal, internal)
  RETURNS internal AS
'libpgchem', 'molfp_penalty'
  LANGUAGE 'c' VOLATILE STRICT
  COST 1;
ALTER FUNCTION molfp_penalty(internal, internal, internal) OWNER TO postgres;

-- Function: molfp_picksplit(internal, internal)

-- DROP FUNCTION molfp_picksplit(internal, internal);

CREATE OR REPLACE FUNCTION molfp_picksplit(internal, internal)
  RETURNS internal AS
'libpgchem', 'molfp_picksplit'
  LANGUAGE 'c' VOLATILE STRICT
  COST 1;
ALTER FUNCTION molfp_picksplit(internal, internal) OWNER TO postgres;

-- Function: molfp_same(internal, internal, internal)

-- DROP FUNCTION molfp_same(internal, internal, internal);

CREATE OR REPLACE FUNCTION molfp_same(internal, internal, internal)
  RETURNS internal AS
'libpgchem', 'molfp_same'
  LANGUAGE 'c' VOLATILE
  COST 1;
ALTER FUNCTION molfp_same(internal, internal, internal) OWNER TO postgres;

-- Function: molfp_union(internal, internal)

-- DROP FUNCTION molfp_union(internal, internal);

CREATE OR REPLACE FUNCTION molfp_union(internal, internal)
  RETURNS internal AS
'libpgchem', 'molfp_union'
  LANGUAGE 'c' VOLATILE
  COST 1;
ALTER FUNCTION molfp_union(internal, internal) OWNER TO postgres;

-- Function: molkeys_long(molecule, boolean, boolean, boolean)

-- DROP FUNCTION molkeys_long(molecule, boolean, boolean, boolean);

CREATE OR REPLACE FUNCTION molkeys_long(molecule, boolean, boolean, boolean)
  RETURNS text AS
'libpgchem', 'pgchem_ms_fingerprint_long_a'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION molkeys_long(molecule, boolean, boolean, boolean) OWNER TO postgres;

-- Function: molkeys_long(molecule)

-- DROP FUNCTION molkeys_long(molecule);

CREATE OR REPLACE FUNCTION molkeys_long(molecule)
  RETURNS text AS
$BODY$
BEGIN
RETURN molkeys_long($1,false,false,false);
END;
$BODY$
  LANGUAGE 'plpgsql' IMMUTABLE STRICT
  COST 100;
ALTER FUNCTION molkeys_long(molecule) OWNER TO postgres;

-- Function: molkeys_short(molecule)

-- DROP FUNCTION molkeys_short(molecule);

CREATE OR REPLACE FUNCTION molkeys_short(molecule)
  RETURNS text AS
'libpgchem', 'pgchem_ms_fingerprint_short_a'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION molkeys_short(molecule) OWNER TO postgres;

-- Function: molweight(molecule)

-- DROP FUNCTION molweight(molecule);

CREATE OR REPLACE FUNCTION molweight(molecule)
  RETURNS double precision AS
'libpgchem', 'pgchem_molweight'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION molweight(molecule) OWNER TO postgres;

-- Function: mr(molecule)

-- DROP FUNCTION mr(molecule);

CREATE OR REPLACE FUNCTION mr(molecule)
  RETURNS double precision AS
'libpgchem', 'pgchem_MR'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION mr(molecule) OWNER TO postgres;

-- Function: mutabor(molecule)

-- DROP FUNCTION mutabor(molecule);

CREATE OR REPLACE FUNCTION mutabor(molecule)
  RETURNS molecule AS
'libpgchem', 'pgchem_mutate_fp'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION mutabor(molecule) OWNER TO postgres;

-- Function: nbits_set(bit varying)

-- DROP FUNCTION nbits_set(bit varying);

CREATE OR REPLACE FUNCTION nbits_set(bit varying)
  RETURNS integer AS
'libpgchem', 'pgchem_nbits_set'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION nbits_set(bit varying) OWNER TO postgres;

-- Function: number_of_atoms(molecule)

-- DROP FUNCTION number_of_atoms(molecule);

CREATE OR REPLACE FUNCTION number_of_atoms(molecule)
  RETURNS integer AS
'libpgchem', 'pgchem_num_atoms'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION number_of_atoms(molecule) OWNER TO postgres;

-- Function: number_of_bonds(molecule)

-- DROP FUNCTION number_of_bonds(molecule);

CREATE OR REPLACE FUNCTION number_of_bonds(molecule)
  RETURNS integer AS
'libpgchem', 'pgchem_num_bonds'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION number_of_bonds(molecule) OWNER TO postgres;

-- Function: number_of_h_acceptors(molecule)

-- DROP FUNCTION number_of_h_acceptors(molecule);

CREATE OR REPLACE FUNCTION number_of_h_acceptors(molecule)
  RETURNS integer AS
'libpgchem', 'pgchem_num_H_acceptors'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION number_of_h_acceptors(molecule) OWNER TO postgres;

-- Function: number_of_h_donors(molecule)

-- DROP FUNCTION number_of_h_donors(molecule);

CREATE OR REPLACE FUNCTION number_of_h_donors(molecule)
  RETURNS integer AS
'libpgchem', 'pgchem_num_H_donors'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION number_of_h_donors(molecule) OWNER TO postgres;

-- Function: number_of_heavy_atoms(molecule)

-- DROP FUNCTION number_of_heavy_atoms(molecule);

CREATE OR REPLACE FUNCTION number_of_heavy_atoms(molecule)
  RETURNS integer AS
'libpgchem', 'pgchem_num_heavy_atoms'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION number_of_heavy_atoms(molecule) OWNER TO postgres;

-- Function: number_of_products(reaction)

-- DROP FUNCTION number_of_products(reaction);

CREATE OR REPLACE FUNCTION number_of_products(reaction)
  RETURNS integer AS
'libpgchem', 'pgchem_r_num_products'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION number_of_products(reaction) OWNER TO postgres;

-- Function: number_of_reactants(reaction)

-- DROP FUNCTION number_of_reactants(reaction);

CREATE OR REPLACE FUNCTION number_of_reactants(reaction)
  RETURNS integer AS
'libpgchem', 'pgchem_r_num_reactants'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION number_of_reactants(reaction) OWNER TO postgres;

-- Function: number_of_rotatable_bonds(molecule)

-- DROP FUNCTION number_of_rotatable_bonds(molecule);

CREATE OR REPLACE FUNCTION number_of_rotatable_bonds(molecule)
  RETURNS integer AS
'libpgchem', 'pgchem_num_rotatable_bonds'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION number_of_rotatable_bonds(molecule) OWNER TO postgres;

-- Function: optimize_fingerprint(text, text, text, text, boolean, text, integer)

-- DROP FUNCTION optimize_fingerprint(text, text, text, text, boolean, text, integer);

CREATE OR REPLACE FUNCTION optimize_fingerprint(t_schema text, t_name text, s_column text, algorithm text, use_sampling boolean, basedict text, p_limit integer)
  RETURNS double precision AS
$BODY$
BEGIN

IF (algorithm='LP') THEN 
BEGIN
PERFORM optimize_fingerprint_step_one(t_schema, t_name, s_column, use_sampling , basedict ,p_limit);
RETURN optimize_fingerprint_step_two(t_schema, t_name, s_column);
END;
ELSIF (algorithm='GA') THEN
RAISE EXCEPTION 'Genetic optimization only externally supported'; 
ELSE RAISE EXCEPTION 'Algorithm % not supported',algorithm; 
END IF;

RAISE INFO 'Optimization on % complete. Achieved rate %',t_schema||'.'||t_name, rate;

RETURN 0.0;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION optimize_fingerprint(text, text, text, text, boolean, text, integer) OWNER TO postgres;

-- Function: optimize_fingerprint_step_one(text, text, text, boolean, text, integer)

-- DROP FUNCTION optimize_fingerprint_step_one(text, text, text, boolean, text, integer);

CREATE OR REPLACE FUNCTION optimize_fingerprint_step_one(t_schema text, t_name text, s_column text, use_sampling boolean, basedict text, p_limit integer)
  RETURNS void AS
$BODY$
DECLARE expansionarray smallint[9];
DECLARE curr_row record;
DECLARE curr_row_i record;
DECLARE tablesize integer;
DECLARE hitcount integer;
DECLARE matchcount integer;
DECLARE expcount integer;
DECLARE j integer;
DECLARE e float8;
DECLARE x float8;
DECLARE t_dict_tmp_name text;
DECLARE t_dict_name text;
DECLARE t_sel_name text;
DECLARE t_q_name text;
DECLARE t_b_name text;
DECLARE t_h_name text;
DECLARE arraytext text;
BEGIN

t_dict_tmp_name := t_schema || '.' || t_name || '_dictionary_tmp';
t_dict_name := t_schema || '.' || t_name || '_dictionary';
t_sel_name := t_schema || '.' || t_name || '_selectivity';
t_q_name := t_schema || '.q_' || t_name; 
t_b_name := t_schema || '.' || t_name; 
t_h_name := t_schema || '.' || t_name || '_helper'; 

EXECUTE 'DROP TABLE IF EXISTS ' || t_dict_tmp_name;

EXECUTE 'DROP TABLE IF EXISTS ' || t_dict_name;

EXECUTE 'DROP TABLE IF EXISTS ' || t_sel_name;

EXECUTE 'CREATE TABLE ' || t_dict_tmp_name || ' (id serial NOT NULL, "SMARTS" text NOT NULL) WITH (OIDS=FALSE)';

EXECUTE 'COPY ' || t_dict_tmp_name || ' ("SMARTS") FROM ' ||  quote_literal(basedict);

EXECUTE 'CREATE TABLE ' || t_dict_name || ' (id serial NOT NULL, "SMARTS" text NOT NULL) WITH (OIDS=FALSE)';

EXECUTE 'INSERT INTO ' || t_dict_name ||  ' ("SMARTS") (SELECT distinct("SMARTS") FROM ' || t_dict_tmp_name || ')';

EXECUTE 'DROP TABLE IF EXISTS ' || t_dict_tmp_name;

EXECUTE 'CREATE TABLE ' || t_sel_name || '(pattern_id integer NOT NULL,expansion smallint NOT NULL DEFAULT 0,coverage double precision NOT NULL DEFAULT 0.0,weight double precision,exparray integer[],_e double precision,_x double precision,CONSTRAINT pattern_id_unique UNIQUE (pattern_id)) WITH (OIDS=FALSE)';

EXECUTE 'DROP TABLE IF EXISTS ' || t_q_name;

EXECUTE 'CREATE TABLE ' || t_q_name || ' AS SELECT ' || s_column || ' FROM ' || t_b_name || ' WHERE fp2string('||s_column||') IN (SELECT fp2string('||s_column||') FROM ' || t_b_name || ' GROUP BY fp2string('||s_column||') HAVING (COUNT(fp2string('||s_column||'))>1))';

IF (use_sampling) THEN
	PERFORM create_random_sample_q_table(t_schema, t_name, s_column);
END IF;

EXECUTE 'DELETE FROM '|| t_q_name ||' WHERE inchikey(' || s_column || ') IN ((SELECT inchikey(' || s_column || ') FROM '|| t_q_name ||' GROUP BY inchikey(' || s_column || ') HAVING (COUNT(inchikey(' || s_column || '))>1)))';

EXECUTE 'SELECT count(1) FROM '|| t_q_name into tablesize;

e := tablesize / 9;

FOR curr_row IN EXECUTE 'SELECT id, "SMARTS" FROM ' || t_dict_name LOOP

x := 0.0;

expansionarray := '{0,0,0,0,0,0,0,0,0}';

hitcount := 0;

expcount := 0;

FOR curr_row_i IN EXECUTE 'SELECT smartsmatch_count('||quote_literal(curr_row."SMARTS")||', ' || s_column || ') as mc FROM '|| t_q_name ||' WHERE smartsmatch_count('||quote_literal(curr_row."SMARTS")||', ' || s_column || ')>0' LOOP

	hitcount:=hitcount+1;

	matchcount := curr_row_i.mc;

	IF (matchcount > 8) THEN matchcount := 8; END IF;

	expansionarray[matchcount+1] := expansionarray[matchcount+1] + 1;

END LOOP;

IF (hitcount > 0) THEN

expansionarray[1] = tablesize - hitcount;

FOR i IN 1..9 LOOP

	IF (expansionarray[i] > 0) THEN 
		BEGIN
		expcount := expcount + 1;
		x := x+(power(expansionarray[i] - e,2)/e);
		END;
	END IF;

END LOOP;

arraytext :='{';

FOR i IN 1..9 LOOP
	arraytext := arraytext || expansionarray[i] || ',';
END LOOP;

arraytext := substring(arraytext FROM 1 for length(arraytext)-1) || '}';

EXECUTE 'INSERT INTO '||t_sel_name||' (pattern_id, expansion, coverage,exparray,_e,_x) VALUES ('||curr_row.id||','||expcount||','||hitcount/tablesize::float8||','||quote_literal(arraytext)||','||e||','||x||')';

END IF;

END LOOP;

EXECUTE 'UPDATE '||t_sel_name||' SET weight = _x';

EXECUTE 'CREATE TABLE '||t_h_name||' AS SELECT "SMARTS", expansion from '||t_sel_name||','|| t_dict_name||'  where id=pattern_id and pattern_id IN (SELECT pattern_id FROM '||t_sel_name||' ORDER BY weight ASC LIMIT '||p_limit||')' ;

EXECUTE 'COPY (SELECT ''#Comments after SMARTS'' UNION SELECT * from (SELECT "SMARTS" FROM '||t_h_name||') t) TO '||quote_literal('c:/tigress/obdata/dictionary.txt');

EXECUTE 'DROP TABLE IF EXISTS '||t_h_name;

EXECUTE 'DROP TABLE IF EXISTS '||t_dict_name;

EXECUTE 'DROP TABLE IF EXISTS '||t_sel_name;

END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION optimize_fingerprint_step_one(text, text, text, boolean, text, integer) OWNER TO postgres;

-- Function: optimize_fingerprint_step_two(text, text, text)

-- DROP FUNCTION optimize_fingerprint_step_two(text, text, text);

CREATE OR REPLACE FUNCTION optimize_fingerprint_step_two(t_schema text, t_name text, s_column text)
  RETURNS double precision AS
$BODY$
DECLARE i float8;
DECLARE tablesize integer;
DECLARE t_q_name text;
BEGIN

t_q_name := t_schema || '.q_' || t_name; 

EXECUTE 'UPDATE '||t_q_name||' SET structure=mutabor('||s_column||')';

EXECUTE 'SELECT COUNT(1) FROM (SELECT count(fpstring('||s_column||')) as count FROM '||t_q_name||' GROUP BY fpstring('||s_column||')) as t WHERE t.count = 1' into i;

EXECUTE 'SELECT COUNT(1) FROM '||t_q_name into tablesize;

EXECUTE 'DROP TABLE IF EXISTS '||t_q_name;

RETURN i/tablesize;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION optimize_fingerprint_step_two(text, text, text) OWNER TO postgres;

-- Function: pgchem_barsoi_version()

-- DROP FUNCTION pgchem_barsoi_version();

CREATE OR REPLACE FUNCTION pgchem_barsoi_version()
  RETURNS cstring AS
'libpgchem', 'pgchem_barsoi_version'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION pgchem_barsoi_version() OWNER TO postgres;

-- Function: pgchem_version()

-- DROP FUNCTION pgchem_version();

CREATE OR REPLACE FUNCTION pgchem_version()
  RETURNS cstring AS
'libpgchem', 'pgchem_version'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION pgchem_version() OWNER TO postgres;

-- Function: product(reaction, integer)

-- DROP FUNCTION product(reaction, integer);

CREATE OR REPLACE FUNCTION product(rxn reaction, pos integer)
  RETURNS molecule AS
$BODY$
BEGIN
IF (pos<1 OR pos>number_of_products(rxn)) THEN
	RAISE EXCEPTION 'Product index out of bounds: %', pos;
END IF;
RETURN reaction_molecule(rxn,pos+number_of_reactants(rxn));
END;
$BODY$
  LANGUAGE 'plpgsql' IMMUTABLE STRICT
  COST 100;
ALTER FUNCTION product(reaction, integer) OWNER TO postgres;

-- Function: psa(molecule)

-- DROP FUNCTION psa(molecule);

CREATE OR REPLACE FUNCTION psa(molecule)
  RETURNS double precision AS
'libpgchem', 'pgchem_PSA'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION psa(molecule) OWNER TO postgres;

-- Function: reactant(reaction, integer)

-- DROP FUNCTION reactant(reaction, integer);

CREATE OR REPLACE FUNCTION reactant(rxn reaction, pos integer)
  RETURNS molecule AS
$BODY$
BEGIN
IF (pos <1 OR pos>number_of_reactants(rxn)) THEN
	RAISE EXCEPTION 'Reactant index out of bounds: %', pos;
END IF;
RETURN reaction_molecule(rxn,pos);
END;
$BODY$
  LANGUAGE 'plpgsql' IMMUTABLE STRICT
  COST 100;
ALTER FUNCTION reactant(reaction, integer) OWNER TO postgres;

-- Function: reaction_contained_in(reaction, reaction)

-- DROP FUNCTION reaction_contained_in(reaction, reaction);

CREATE OR REPLACE FUNCTION reaction_contained_in(reaction, reaction)
  RETURNS boolean AS
'libpgchem', 'reaction_contained_in'
  LANGUAGE 'c' VOLATILE STRICT
  COST 1;
ALTER FUNCTION reaction_contained_in(reaction, reaction) OWNER TO postgres;

-- Function: reaction_contains(reaction, reaction)

-- DROP FUNCTION reaction_contains(reaction, reaction);

CREATE OR REPLACE FUNCTION reaction_contains(reaction, reaction)
  RETURNS boolean AS
'libpgchem', 'reaction_contains'
  LANGUAGE 'c' VOLATILE STRICT
  COST 1;
ALTER FUNCTION reaction_contains(reaction, reaction) OWNER TO postgres;

-- Function: reaction_equals(reaction, reaction)

-- DROP FUNCTION reaction_equals(reaction, reaction);

CREATE OR REPLACE FUNCTION reaction_equals(reaction, reaction)
  RETURNS boolean AS
'libpgchem', 'reaction_equals'
  LANGUAGE 'c' VOLATILE STRICT
  COST 1;
ALTER FUNCTION reaction_equals(reaction, reaction) OWNER TO postgres;

-- Function: reaction_equals_exact(reaction, reaction)

-- DROP FUNCTION reaction_equals_exact(reaction, reaction);

CREATE OR REPLACE FUNCTION reaction_equals_exact(reaction, reaction)
  RETURNS boolean AS
'libpgchem', 'reaction_equals_exact'
  LANGUAGE 'c' VOLATILE STRICT
  COST 1;
ALTER FUNCTION reaction_equals_exact(reaction, reaction) OWNER TO postgres;

-- Function: reaction_equals_products_exact(reaction, reaction)

-- DROP FUNCTION reaction_equals_products_exact(reaction, reaction);

CREATE OR REPLACE FUNCTION reaction_equals_products_exact(reaction, reaction)
  RETURNS boolean AS
'libpgchem', 'reaction_equals_products_exact'
  LANGUAGE 'c' VOLATILE STRICT
  COST 1;
ALTER FUNCTION reaction_equals_products_exact(reaction, reaction) OWNER TO postgres;

-- Function: reaction_in(bytea)

-- DROP FUNCTION reaction_in(bytea);

CREATE OR REPLACE FUNCTION reaction_in(bytea)
  RETURNS reaction AS
'libpgchem', 'reaction_in_bytea'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION reaction_in(bytea) OWNER TO postgres;

-- Function: reaction_in(cstring)

-- DROP FUNCTION reaction_in(cstring);

CREATE OR REPLACE FUNCTION reaction_in(cstring)
  RETURNS reaction AS
'libpgchem', 'reaction_in'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION reaction_in(cstring) OWNER TO postgres;

-- Function: reaction_in(character varying)

-- DROP FUNCTION reaction_in(character varying);

CREATE OR REPLACE FUNCTION reaction_in(character varying)
  RETURNS reaction AS
'libpgchem', 'reaction_in_varchar'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION reaction_in(character varying) OWNER TO postgres;

-- Function: reaction_in(text)

-- DROP FUNCTION reaction_in(text);

CREATE OR REPLACE FUNCTION reaction_in(text)
  RETURNS reaction AS
'libpgchem', 'reaction_in_text'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION reaction_in(text) OWNER TO postgres;

-- Function: reaction_molecule(reaction, integer)

-- DROP FUNCTION reaction_molecule(reaction, integer);

CREATE OR REPLACE FUNCTION reaction_molecule(reaction, integer)
  RETURNS molecule AS
'libpgchem', 'pgchem_r_molecule_at'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION reaction_molecule(reaction, integer) OWNER TO postgres;

-- Function: reaction_out(reaction)

-- DROP FUNCTION reaction_out(reaction);

CREATE OR REPLACE FUNCTION reaction_out(reaction)
  RETURNS cstring AS
'libpgchem', 'reaction_out'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION reaction_out(reaction) OWNER TO postgres;

-- Function: reaction_recv(internal)

-- DROP FUNCTION reaction_recv(internal);

CREATE OR REPLACE FUNCTION reaction_recv(internal)
  RETURNS reaction AS
'libpgchem', 'reaction_recv'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION reaction_recv(internal) OWNER TO postgres;

-- Function: reaction_send(reaction)

-- DROP FUNCTION reaction_send(reaction);

CREATE OR REPLACE FUNCTION reaction_send(reaction)
  RETURNS bytea AS
'libpgchem', 'reaction_send'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION reaction_send(reaction) OWNER TO postgres;

-- Function: reaction_similarity(reaction, reaction)

-- DROP FUNCTION reaction_similarity(reaction, reaction);

CREATE OR REPLACE FUNCTION reaction_similarity(reaction, reaction)
  RETURNS double precision AS
'libpgchem', 'reaction_similarity'
  LANGUAGE 'c' VOLATILE STRICT
  COST 1;
ALTER FUNCTION reaction_similarity(reaction, reaction) OWNER TO postgres;

-- Function: reaction_similarity_products(reaction, reaction)

-- DROP FUNCTION reaction_similarity_products(reaction, reaction);

CREATE OR REPLACE FUNCTION reaction_similarity_products(reaction, reaction)
  RETURNS double precision AS
'libpgchem', 'reaction_similarity_products'
  LANGUAGE 'c' VOLATILE STRICT
  COST 1;
ALTER FUNCTION reaction_similarity_products(reaction, reaction) OWNER TO postgres;

-- Function: reaction_similarity_reactants(reaction, reaction)

-- DROP FUNCTION reaction_similarity_reactants(reaction, reaction);

CREATE OR REPLACE FUNCTION reaction_similarity_reactants(reaction, reaction)
  RETURNS double precision AS
'libpgchem', 'reaction_similarity_reactants'
  LANGUAGE 'c' VOLATILE STRICT
  COST 1;
ALTER FUNCTION reaction_similarity_reactants(reaction, reaction) OWNER TO postgres;

-- Function: remove_hydrogens(molecule, boolean)

-- DROP FUNCTION remove_hydrogens(molecule, boolean);

CREATE OR REPLACE FUNCTION remove_hydrogens(molecule, boolean)
  RETURNS molecule AS
'libpgchem', 'pgchem_remove_hydrogens'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION remove_hydrogens(molecule, boolean) OWNER TO postgres;

-- Function: rxnfp_compress(internal)

-- DROP FUNCTION rxnfp_compress(internal);

CREATE OR REPLACE FUNCTION rxnfp_compress(internal)
  RETURNS internal AS
'libpgchem', 'rxnfp_compress'
  LANGUAGE 'c' VOLATILE
  COST 1;
ALTER FUNCTION rxnfp_compress(internal) OWNER TO postgres;

-- Function: rxnfp_consistent(internal, internal, integer)

-- DROP FUNCTION rxnfp_consistent(internal, internal, integer);

CREATE OR REPLACE FUNCTION rxnfp_consistent(internal, internal, integer)
  RETURNS boolean AS
'libpgchem', 'rxnfp_consistent'
  LANGUAGE 'c' VOLATILE
  COST 1;
ALTER FUNCTION rxnfp_consistent(internal, internal, integer) OWNER TO postgres;

-- Function: rxnfp_decompress(internal)

-- DROP FUNCTION rxnfp_decompress(internal);

CREATE OR REPLACE FUNCTION rxnfp_decompress(internal)
  RETURNS internal AS
'libpgchem', 'rxnfp_decompress'
  LANGUAGE 'c' VOLATILE
  COST 1;
ALTER FUNCTION rxnfp_decompress(internal) OWNER TO postgres;

-- Function: rxnfp_in(cstring)

-- DROP FUNCTION rxnfp_in(cstring);

CREATE OR REPLACE FUNCTION rxnfp_in(cstring)
  RETURNS rxnfp AS
'libpgchem', 'rxnfp_in'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION rxnfp_in(cstring) OWNER TO postgres;

-- Function: rxnfp_out(rxnfp)

-- DROP FUNCTION rxnfp_out(rxnfp);

CREATE OR REPLACE FUNCTION rxnfp_out(rxnfp)
  RETURNS cstring AS
'libpgchem', 'rxnfp_out'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION rxnfp_out(rxnfp) OWNER TO postgres;

-- Function: rxnfp_penalty(internal, internal, internal)

-- DROP FUNCTION rxnfp_penalty(internal, internal, internal);

CREATE OR REPLACE FUNCTION rxnfp_penalty(internal, internal, internal)
  RETURNS internal AS
'libpgchem', 'rxnfp_penalty'
  LANGUAGE 'c' VOLATILE STRICT
  COST 1;
ALTER FUNCTION rxnfp_penalty(internal, internal, internal) OWNER TO postgres;

-- Function: rxnfp_picksplit(internal, internal)

-- DROP FUNCTION rxnfp_picksplit(internal, internal);

CREATE OR REPLACE FUNCTION rxnfp_picksplit(internal, internal)
  RETURNS internal AS
'libpgchem', 'rxnfp_picksplit'
  LANGUAGE 'c' VOLATILE STRICT
  COST 1;
ALTER FUNCTION rxnfp_picksplit(internal, internal) OWNER TO postgres;

-- Function: rxnfp_same(internal, internal, internal)

-- DROP FUNCTION rxnfp_same(internal, internal, internal);

CREATE OR REPLACE FUNCTION rxnfp_same(internal, internal, internal)
  RETURNS internal AS
'libpgchem', 'rxnfp_same'
  LANGUAGE 'c' VOLATILE
  COST 1;
ALTER FUNCTION rxnfp_same(internal, internal, internal) OWNER TO postgres;

-- Function: rxnfp_union(internal, internal)

-- DROP FUNCTION rxnfp_union(internal, internal);

CREATE OR REPLACE FUNCTION rxnfp_union(internal, internal)
  RETURNS internal AS
'libpgchem', 'rxnfp_union'
  LANGUAGE 'c' VOLATILE
  COST 1;
ALTER FUNCTION rxnfp_union(internal, internal) OWNER TO postgres;

-- Function: smartsmatch(text, molecule)

-- DROP FUNCTION smartsmatch(text, molecule);

CREATE OR REPLACE FUNCTION smartsmatch(text, molecule)
  RETURNS boolean AS
'libpgchem', 'pgchem_smartsfilter'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION smartsmatch(text, molecule) OWNER TO postgres;

-- Function: smartsmatch_count(text, molecule)

-- DROP FUNCTION smartsmatch_count(text, molecule);

CREATE OR REPLACE FUNCTION smartsmatch_count(text, molecule)
  RETURNS integer AS
'libpgchem', 'pgchem_smartsfilter_count'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION smartsmatch_count(text, molecule) OWNER TO postgres;

-- Function: smiles(molecule)

-- DROP FUNCTION smiles(molecule);

CREATE OR REPLACE FUNCTION smiles(molecule)
  RETURNS text AS
'libpgchem', 'pgchem_molecule_to_smiles'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION smiles(molecule) OWNER TO postgres;

-- Function: smiles(reaction)

-- DROP FUNCTION smiles(reaction);

CREATE OR REPLACE FUNCTION smiles(reaction)
  RETURNS text AS
'libpgchem', 'pgchem_r_reaction_to_smiles'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION smiles(reaction) OWNER TO postgres;

-- Function: strip_rxninfo(molecule)

-- DROP FUNCTION strip_rxninfo(molecule);

CREATE OR REPLACE FUNCTION strip_rxninfo(molecule)
  RETURNS molecule AS
'libpgchem', 'pgchem_reaction_mol_strip_rxninfo'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION strip_rxninfo(molecule) OWNER TO postgres;

-- Function: strip_salts(molecule, boolean)

-- DROP FUNCTION strip_salts(molecule, boolean);

CREATE OR REPLACE FUNCTION strip_salts(molecule, boolean)
  RETURNS molecule AS
'libpgchem', 'pgchem_strip_salts'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION strip_salts(molecule, boolean) OWNER TO postgres;

-- Function: total_charge(molecule)

-- DROP FUNCTION total_charge(molecule);

CREATE OR REPLACE FUNCTION total_charge(molecule)
  RETURNS integer AS
'libpgchem', 'pgchem_total_charge'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION total_charge(molecule) OWNER TO postgres;

-- Function: v3000(molecule)

-- DROP FUNCTION v3000(molecule);

CREATE OR REPLACE FUNCTION v3000(molecule)
  RETURNS text AS
'libpgchem', 'pgchem_molecule_to_V3000'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;
ALTER FUNCTION v3000(molecule) OWNER TO postgres;

-- Function: validate_cas_no(character varying)

-- DROP FUNCTION validate_cas_no(character varying);

CREATE OR REPLACE FUNCTION validate_cas_no(character varying)
  RETURNS boolean AS
$BODY$
DECLARE checksum_from_cas_no varchar;
DECLARE cas_no_left varchar;
DECLARE cas_no_right varchar;
DECLARE cas_no_full varchar;
DECLARE tmpsum int;
DECLARE position_multiplier int;
DECLARE caslen int;
BEGIN
caslen:=length($1);

IF caslen<5 OR caslen>12 THEN RETURN FALSE;
END IF;

checksum_from_cas_no:=split_part($1,'-',3)::int;
cas_no_left:=split_part($1,'-',1);
cas_no_right:=split_part($1,'-',2);
cas_no_full:=cas_no_left || cas_no_right;

if(length(cas_no_left)>7 OR length(cas_no_right)>2 OR length(checksum_from_cas_no)!=1) THEN 
return false; 
END IF;

caslen:=length(cas_no_full);
tmpsum:=0;
position_multiplier:=1;

 FOR i IN REVERSE caslen..1 LOOP
  tmpsum:=tmpsum+substr(cas_no_full,i,1)::int*position_multiplier;
  position_multiplier:=position_multiplier+1;
 END LOOP;
 RETURN tmpsum % 10 = checksum_from_cas_no::int;
END;
$BODY$
  LANGUAGE 'plpgsql' IMMUTABLE STRICT
  COST 100;
ALTER FUNCTION validate_cas_no(character varying) OWNER TO postgres;

CREATE OR REPLACE FUNCTION baldi_tanimoto_hi(struct molecule, similarity double precision)
  RETURNS integer AS
$BODY$
BEGIN
RETURN ceil(nbits_set(fp2string(struct))/similarity)::integer;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION baldi_tanimoto_lo(struct molecule, similarity double precision)
  RETURNS integer AS
$BODY$
BEGIN
RETURN floor(nbits_set(fp2string(struct))*similarity)::integer;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION fpmaccsstring(molecule)
  RETURNS bit varying AS
'libpgchem', 'pgchem_fp_MACCS'
  LANGUAGE 'c' IMMUTABLE STRICT
  COST 1;

CREATE OR REPLACE FUNCTION tversky(molecule, molecule, double precision, double precision)
  RETURNS double precision AS
'libpgchem', 'pgchem_tversky'
  LANGUAGE 'c' VOLATILE STRICT
  COST 1;

-- Function: dice(molecule, molecule)

-- DROP FUNCTION dice(molecule, molecule);

CREATE OR REPLACE FUNCTION dice(prototype molecule, variant molecule)
  RETURNS double precision AS
$BODY$
BEGIN
RETURN tversky(prototype, variant, 0.5, 0.5);
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


