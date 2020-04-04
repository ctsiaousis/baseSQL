-- Table: public."LearningActivity"

-- DROP TABLE public."LearningActivity";

CREATE TYPE enum_activity_type AS ENUM ('lecture','tutorial','computer_lab','lab','office_hours');

CREATE TABLE public."LearningActivity"
(
    room_id character(6) COLLATE pg_catalog."default" NOT NULL,
    weekday integer NOT NULL,
    start_time numeric NOT NULL,
    end_time numeric NOT NULL,
	activity_type enum_activity_type NOT NULL,
    CONSTRAINT "LearningActivity_pkey" PRIMARY KEY (room_id, weekday,start_time,end_time),
    CONSTRAINT "LearningActivity_roomTakesPlace_fkey" FOREIGN KEY (room_id)
        REFERENCES public."Room" (room_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE public."LearningActivity"
    OWNER to postgres;