-- Create Extensions
CREATE EXTENSION vector;
CREATE EXTENSION ai cascade;

-- Get dataset
SELECT ai.load_dataset(
    'Cohere/movies',
    if_table_exists := 'drop' 
);

-- Create table with 20 rows
CREATE TABLE movies_dataset AS
SELECT *
FROM movies
LIMIT 20;

-- view your table
SELECT * FROM movies_dataset ;

-- Add embeddings column
ALTER TABLE movies_dataset ADD COLUMN embedding vector (1024);

--Set up cohere API Key
SELECT set_config('ai.cohere_api_key','<YOUR-API-KEY>', false)

-- Populate embeddings column in the table 
UPDATE movies_dataset
SET embedding = ai.cohere_embed(
'embed-english-v3.0',
CONCAT(title,'. ',overview,'. ',genres,'. ',"cast"),
input_style => 'search_document'
);

--Create index on table for enhanced searches
CREATE INDEX ON movies_dataset USING hnsw (embedding vector_cosine_ops);

--Set up query and test your semantic search
WITH q AS (
    SELECT ai.cohere_embed(
    'embed-english-v3.0',
    'show me action packed movies', -- user query
    input_type =>'search_query'
    ) AS q
)
SELECT title,overview, genres, "cast"
FROM movies_dataset
ORDER BY embedding <-> (SELECT q FROM q LIMIT 1)
LIMIT 5; -- controls the number of retrieved output
