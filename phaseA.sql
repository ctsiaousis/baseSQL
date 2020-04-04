-- erwthma 3.1-------------------------------------------------------------------
CREATE OR REPLACE FUNCTION create_students(year integer, num integer)
RETURNS TABLE (am CHARACTER(10), surname character(50), name character(50)) AS
$$
BEGIN
RETURN QUERY
SELECT create_am(year,n.id), adapt_surname(s.surname,n.sex), n.name
FROM random_names(num) n JOIN random_surnames(num) s USING (id);
END;
$$
LANGUAGE 'plpgsql' VOLATILE;

select * from create_students(2020, 123456)
--         ---------------------------------------------------------------------