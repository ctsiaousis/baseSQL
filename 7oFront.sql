-- 1 --
select count(*), typical_year, typical_season from "Course"
where obligatory
group by typical_year, typical_season;

-- 2 --
select SUM(lab_hours), count(*) from "Course"
where typical_year=1 and typical_season='winter';

-- 3 --
select course_code,course_description from "Course"
where units <= ALL (SELECT units
FROM "Course");

-- 4 --
select max(total_units)
from (select c1.typical_year,c1.typical_season, sum(c1.units) as total_units
from "Course" c1
where c1.obligatory
group by c1.typical_year, c1.typical_season )x;

-- 5 --
select course_code
from "Course"
EXCEPT
select dependent
from "Course_depends";