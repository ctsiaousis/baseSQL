CREATE TABLE public.AB(
id INTEGER PRIMARY KEY,
item_type character varying(5) NOT NULL,
item_type_id INTEGER
);

CREATE TABLE typeA(
typeA_id INTEGER PRIMARY KEY
);

CREATE TABLE typeB(
typeB_id INTEGER PRIMARY KEY
);

CREATE OR REPLACE FUNCTION check_type(id integer, tp varchar(5))
returns boolean as
$BODY$
DECLARE
	isfound boolean = false;
BEGIN
	IF tp = 'A' THEN 
		SELECT count(*) INTO isfound FROM typea WHERE typea_id=id;
	ELSEIF tp='B' THEN
		SELECT count(*) INTO isfound FROM typeb WHERE typeb_id=id;
	END IF;
	
	RETURN isfound;
END;
$BODY$
LANGUAGE plpgsql;


ALTER TABLE AB ADD CONSTRAINT "checkids" CHECK(check_type(item_type_id,item_type));