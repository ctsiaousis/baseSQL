-- Table: public."Room"

-- DROP TABLE public."Room";

CREATE TYPE enum_room_type AS ENUM ('lecture_room','computer_room','lab_room','office');

CREATE TABLE public."Room"
(
    room_id character(6) COLLATE pg_catalog."default" NOT NULL,
    capacity integer NOT NULL,
    room_type enum_room_type NOT NULL,
    CONSTRAINT "Room_pkey" PRIMARY KEY (room_id)
)

TABLESPACE pg_default;

ALTER TABLE public."Room"
    OWNER to postgres;