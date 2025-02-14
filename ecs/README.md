posgresql connection 
```sh
PGPASSWORD=secure_password psql -h <RDS endpoint> -U todo_user -d tododb -p 5432
```

```sh
CREATE TABLE IF NOT EXISTS todo (
    todo_id SERIAL PRIMARY KEY,
    description VARCHAR(255)
);
```
