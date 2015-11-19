function CreateDatabase()
  db = sqlite3.open(PLUGIN:GetLocalFolder() .. "/database.sqlite3")

  -- Create tables and insert default records
  stmt = db:prepare("CREATE TABLE test (name, address)")
  stmt:step()
  stmt:finalize()

  stmt = db:prepare("INSERT INTO test (name, address) VALUES ('Bart', 'Borculoseweg 44')")
  stmt:step()
  stmt:finalize()

  db:close()
end
