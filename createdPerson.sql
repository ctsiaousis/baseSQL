-- Table: public."Person"

-- DROP TABLE public."Person";

CREATE OR REPLACE FUNCTION reject_not_existing_amka_for_person()
    RETURNS "trigger" AS
    $BODY$
        BEGIN
            IF NEW.amka NOT IN (SELECT amka FROM "Student" UNION SELECT amka FROM "LabStaff" UNION SELECT amka FROM "Professor") THEN
                RAISE EXCEPTION 'The person amka % does not exist', NEW.amka;
            END IF;
            RETURN NEW;
        END;
    $BODY$
        LANGUAGE 'plpgsql' VOLATILE;

CREATE TRIGGER tr_before_insert_or_update
    BEFORE INSERT OR UPDATE OF amka
    ON "Person"
    FOR EACH ROW
    EXECUTE PROCEDURE reject_not_existing_amka_for_person();
	

CREATE TABLE public."Person"
(
    amka integer NOT NULL DEFAULT nextval('"Student_amka_seq"'::regclass),
    tieisai person_roles NOT NULL,
	CONSTRAINT "Person_pkey" PRIMARY KEY (amka)
)

TABLESPACE pg_default;

ALTER TABLE public."Person"
    OWNER to postgres;