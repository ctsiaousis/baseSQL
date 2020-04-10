CREATE TABLE student_audit
(
id SERIAL PRIMARY KEY,
operation character(1),
operation_time timestamp with time zone,
am character(50),
message character varying
);

create or replace function student_update() RETURNS trigger AS
$$
BEGIN
IF (TG_OP = 'DELETE') THEN
insert into student_audit(operation,operation_time,am,message)
values ('D',now(),OLD.am, concat('Deleteion attempted! ',OLD.name,' ',OLD.surname));
return NULL;
END IF;
END;
$$
LANGUAGE plpgsql;

create trigger student_monitor BEFORE INSERT OR UPDATE OR DELETE ON public."lab6_student"
FOR EACH ROW EXECUTE PROCEDURE student_update()