-- Database: BASE
-- 1. Βρες το πλήθος των υποχρεωτικών μαθημάτων σε κάθε εξαμήνο σπουδών
SELECT typical_year, typical_season, COUNT(*) as num
FROM "Course"
WHERE obligatory=true
GROUP BY typical_year, typical_season;

-- 2. plhthos units upoxreotikon se kathe etos me order desc(units)
SELECT typical_year, SUM(units) as total
FROM "Course"
WHERE obligatory
GROUP BY typical_year
ORDER BY total DESC;


-- 3. Βρες τα εξάμηνα σπουδών που έχουν πάνω από 5 κατ' επιλογήν υποχρεωτικά μαθήματα
SELECT typical_year, typical_season
FROM "Course"
WHERE NOT obligatory
GROUP BY typical_year, typical_season;
HAVING COUNT(*)>5;


-- 4. Δείξε ταξινομημένα σε αντίστροφη αλφαβητική σειρά τους τίτλους 
--    των εργαστηρίων και το πλήθος των γνωστικών περιοχών καθενός
-- You may write it with USING:
SELECT l.lab_title, COUNT(*)
FROM "Lab" l INNER JOIN "Covers" s USING (sector_code)
GROUP BY l.lab_code
ORDER BY l.lab_title DESC;
-- Or use NATURAL JOIN:
SELECT l.lab_title, COUNT(*)
FROM "Lab" l NATURAL JOIN "Covers" s
GROUP BY l.lab_code
ORDER BY l.lab_title DESC;
-- Also with ON:
SELECT l.lab_title, COUNT(*)
FROM "Lab" l INNER JOIN "Covers" f ON l.sector_code = f.sector_code
GROUP BY l.lab_code
ORDER BY l.lab_title DESC;

-- 5. Megisto plithos units se ola ta eksamina

select max(total_units) 
from (select c1.typical_year,c1.typical_season, sum(c1.units) 
	  as total_units 
	  from "Course" c1 
	  where c1.obligatory=true 
	  group by c1.typical_year, c1.typical_season ) X ;

-- 6. eksamina me MEGISTA units ypoxreotikon mathimaton
select max(total_units),typical_year, typical_season
from (select c1.typical_year,c1.typical_season, sum(c1.units) 
	  as total_units 
	  from "Course" c1 
	  where c1.obligatory=true 
	  group by c1.typical_year, c1.typical_season ) X 
GROUP BY typical_year, typical_season;
--i allios
select c1.typical_year,c1.typical_season 
from "Course" c1 
where c1.obligatory=true 
group by c1.typical_year, c1.typical_season 
having sum(c1.units)=(select max(total_units) 
					  from (select c1.typical_year,c1.typical_season, sum(c1.units) as total_units from "Course" c1 
							where c1.obligatory=true 
							group by c1.typical_year, c1.typical_season 
							order by sum(c1.units) desc) X) 

-- 7. Βρες ζεύγη κωδικών για μαθήματα που εξαρτώνται άμεσα ή έμμεσα 
--    το ένα από το άλλο μέσω προαπαιτουμένων μαθημάτων.
WITH RECURSIVE Required(anc,des) AS (
	SELECT main as anc,dependent as des 
	FROM "Course_depends" 
	WHERE mode='required'
	UNION
	SELECT r.anc as anc,d.dependent as des
	FROM Required r, "Course_depends" d
	WHERE r.des = d.main AND mode='required'
)
SELECT * FROM Required

--test no reqursion
SELECT dependent,main
	FROM "Course_depends" 
	WHERE mode='required'
UNION
SELECT f.dependent,s.main
FROM
(SELECT dependent,main
	FROM "Course_depends" 
	WHERE mode='required') f
INNER JOIN
(SELECT dependent,main 
	FROM "Course_depends" 
	WHERE mode='required') s
	ON f.main=s.dependent
