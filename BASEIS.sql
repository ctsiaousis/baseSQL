--INSERT INTO public."Course"("course_code","course_title","units","ects","weight","lecture_hours","tutorial_hours","lab_hours","typical_year","typical_season","obligatory","course_description")
--VALUES('ΤΣΤ101','Τεστ εισαγωγής','4','5','1.5','4','2','2','4','winter','false','TestΤΕΣΤ 123 εδω βαζω ενα μαθημα');

SELECT * FROM public."Course" --edo thelei autakia giati to public.asfsf den einai case sensitive
WHERE course_code LIKE 'ΤΗΛ %' AND NOT obligatory = false
ORDER BY lab_hours DESC;

SELECT * FROM "Course"
WHERE typical_year=1
ORDER BY units DESC;