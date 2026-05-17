const host = "localhost:27017";

try {
  rs.initiate({
    _id: "rs0",
    members: [{ _id: 0, host }]
  });
} catch (e) {
  print("Replica set ya inicializado:", e);
}
