CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL
);

INSERT INTO users (name, email) VALUES 
('Alice', 'alice@example.com'), 
('Bob', 'bob@example.com'),
('Charlie', 'charlie@example.com');
('Moko', 'moko@example.com');
