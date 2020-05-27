EXPLAIN ANALYSE SELECT *
FROM "Register" r NATURAL JOIN
(SELECT s.name, s.amka
FROM "Student" s NATURAL JOIN "Name" n
WHERE n.sex='F') sb
WHERE r.course_code='ΠΛΗ 302' and r.final_grade='7.6'