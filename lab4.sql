-- Table: public."Name"

-- DROP TABLE public."Name";
	
--lab4 D1---------------------------------------------------------
--		bres ta ergastiria kai tous tomeis tous

SELECT s.sector_title,l.lab_title
FROM "Sector" s,"Lab" l
WHERE s.sector_code = l.sector_code;
--SELECT s.sector_title,l.lab_title
--FROM "Sector" s JOIN "Lab" l USING (sector_code)
--SELECT s.sector_title,l.lab_title
--FROM "Sector" s JOIN "Lab" l ON (s.sector_code=l.sector_code)


--     D2--------------------------------------------------------
--		bres tis sunolikes ores mathimaton (fthinousa seira)

SELECT c.course_code,c.course_title,c.lecture_hours+c.tutorial_hours+c.lab_hours as total_hours
FROM "Course" c
ORDER BY total_hours DESC;


--     D3--------------------------------------------------------
--		se mia stili ola ta lab kai sector mesw union

(SELECT sector_title as title FROM "Sector")
UNION
(SELECT lab_title as title FROM "Lab");


--     D4--------------------------------------------------------
--		oles oi gnotikes perioxes 4ou kai 5ou etous

(SELECT left(course_code,3) FROM "Course" WHERE typical_year=4)
INTERSECT
(SELECT left(course_code,3) FROM "Course" WHERE typical_year=5);


--     D5--------------------------------------------------------
--		mathimata 2ou, opou kaluptontai apo lab me sector=8

SELECT course_code
FROM "Course"
WHERE typical_year=2 AND
left(course_code,3) IN
(SELECT field_code FROM "Covers" WHERE lab_code=8);


--     D6--------------------------------------------------------
--		idio me D6 alla anti gia IN me EXISTS

SELECT course_code
FROM "Course"
WHERE typical_year=2 AND
EXISTS (SELECT field_code FROM "Covers" WHERE lab_code=8 AND
left(course_code,3)=field_code);


--     D7--------------------------------------------------------
--		bres mathimata etous me ta ligotera units ap ta upoloipa

SELECT course_code
FROM "Course"
WHERE typical_year= 4 AND
units <= ALL ( SELECT units
FROM "Course"
WHERE typical_year=4) ;


--     D8--------------------------------------------------------
--		bres mathimata etous p dn exoun tis perissoteres DM ap ta upoloipa

SELECT course_code,course_title,units
FROM "Course"
WHERE typical_year=1 AND
units < ANY (SELECT units
FROM "Course"
WHERE typical_year=1);


--     D9--------------------------------------------------------
--		titlos kai plithos gnostikon perioxon ergasthriou

select lab_title , count(field_code)
from
"Lab" natural join "Covers"
group by lab_title
order by count(field_code) DESC;



