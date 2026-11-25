create table jogadores (
id_jogador SERIAL PRIMARY KEY,
usuario VARCHAR(50) NOT NULL UNIQUE,
email VARCHAR(100) NOT NULL UNIQUE,
senha VARCHAR(100) NOT NULL,
status VARCHAR(15) NOT NULL
CHECK (status IN ('ativo', 'inativo', 'banido'))
)

create table modalidades (
id serial primary key,
modalidade varchar (100),
categoria varchar (100)
)

create table torneios (
id serial primary key,
nome varchar (100) not null,
data_inicio date not null,
data_fim date not null,
id_modalidade int not null

 FOREIGN KEY (id_modalidade)
    REFERENCES modalidades(id_modalidade),

    CHECK (data_fim >= data_inicio)
)

CREATE TABLE partidas (
    id_partida SERIAL PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    data_agendamento TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL
    CHECK (status IN ('agendada', 'em andamento', 'finalizada', 'cancelada')),

    id_jogador INT NOT NULL,
    id_torneio INT NOT NULL,

    data_criacao TIMESTAMP,

    FOREIGN KEY (id_jogador)
    REFERENCES jogadores(id_jogador),

    FOREIGN KEY (id_torneio)
    REFERENCES torneios(id_torneio)
);

CREATE TABLE historico_partidas (
    id_historico SERIAL PRIMARY KEY,
    id_partida INT NOT NULL,
    descricao TEXT NOT NULL,
    data_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_partida)
    REFERENCES partidas(id_partida)
);

INSERT INTO jogadores (nickname, email, senha, status)
VALUES
('Shadow', 'shadow@email.com', '123456', 'ativo'),
('Ninja', 'ninja@email.com', 'abcdef', 'ativo'),
('Ghost', 'ghost@email.com', '654321', 'ativo'),
('PlayerBanido', 'banido@email.com', 'senha123', 'banido');

INSERT INTO modalidades (nome, categoria)
VALUES
('Valorant', 'FPS'),
('League of Legends', 'MOBA'),
('Counter Strike 2', 'FPS');

INSERT INTO torneios (nome, data_inicio, data_fim, id_modalidade)
VALUES
('Copa Valorant', '2026-12-01', '2026-12-15', 1),
('Campeonato LOL', '2026-12-05', '2026-12-20', 2),
('CS Championship', '2026-12-10', '2026-12-25', 3);

CREATE OR REPLACE FUNCTION fn_validar_partida()
RETURNS TRIGGER AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM jogadores
        WHERE id_jogador = NEW.id_jogador
        AND status = 'ativo'
    ) THEN

        RAISE EXCEPTION
        'A partida só pode ser vinculada a um jogador ativo.';

    END IF;

    NEW.data_criacao := CURRENT_TIMESTAMP;

    RETURN NEW;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_partida
BEFORE INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION fn_validar_partida();
CREATE OR REPLACE FUNCTION fn_registrar_historico()
RETURNS TRIGGER AS $$
BEGIN

    INSERT INTO historico_partidas
    (id_partida, descricao)

    VALUES (
        NEW.id_partida,
        'Nova partida criada: ' || NEW.titulo
    );

    RETURN NEW;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_registrar_historico
AFTER INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_historico();


INSERT INTO partidas
(titulo, data_agendamento, status, id_jogador, id_torneio)
VALUES
('Shadow vs Ninja', '2026-12-02 14:00:00', 'agendada', 1, 1),

('Ninja vs Ghost', '2026-12-06 16:00:00', 'agendada', 2, 2),

('Ghost vs Shadow', '2026-12-12 18:00:00', 'agendada', 3, 3);

CREATE OR REPLACE FUNCTION fn_buscar_jogadores(termo TEXT)

RETURNS TABLE (
    id INT,
    nickname VARCHAR(50),
    email VARCHAR(100),
    status VARCHAR(15)
)

AS $$

BEGIN

    RETURN QUERY

    SELECT
        j.id_jogador,
        j.nickname,
        j.email,
        j.status

    FROM jogadores j

    WHERE
        j.nickname ILIKE '%' || termo || '%'
        OR
        j.email ILIKE '%' || termo || '%';

END;

$$ LANGUAGE plpgsql;

CREATE OR REPLACE VIEW vw_painel_principal AS

SELECT
    j.nickname,
    p.titulo AS titulo_partida,
    m.categoria,
    p.data_agendamento AS data_partida,
    p.status

FROM partidas p

INNER JOIN jogadores j
ON p.id_jogador = j.id_jogador

INNER JOIN torneios t
ON p.id_torneio = t.id_torneio

INNER JOIN modalidades m
ON t.id_modalidade = m.id_modalidade;


CREATE OR REPLACE VIEW vw_cronograma_partidas AS

SELECT
    p.id_partida,
    p.titulo,
    p.data_agendamento,
    p.status,

    (p.data_agendamento::DATE - CURRENT_DATE)
    AS dias_restantes,

    j.nickname AS jogador_responsavel

FROM partidas p

INNER JOIN jogadores j
ON p.id_jogador = j.id_jogador

ORDER BY p.data_agendamento ASC;


SELECT * FROM jogadores;



SELECT * FROM modalidades;



SELECT * FROM torneios;



SELECT * FROM partidas;



SELECT * FROM historico_partidas;



SELECT * FROM fn_buscar_jogadores('Shadow');



SELECT * FROM vw_painel_principal;



SELECT * FROM vw_cronograma_partidas;




INSERT INTO partidas
(titulo, data_agendamento, status, id_jogador, id_torneio)
VALUES
('Partida inválida', '2026-12-20 15:00:00',
 'agendada', 4, 1);
