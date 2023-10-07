chars = [
  { "name": "alice", "speed": 10, "progress": 0.0 },
  { "name": "bob", "speed": 20, "progress": 0.0 },
  { "name": "carol", "speed": 5, "progress": 0.0 },
  { "name": "dave", "speed": 7, "progress": 0.0 },
]

target = 1
for i in range(100):
  char_remaining = [(target - char["progress"])/char["speed"] for char in chars]
  progress = min(char_remaining)
  for char in chars:
    char["progress"] += progress * char["speed"]
  turn_order = [char for char in chars if char["progress"] >= target]
  turn_order.sort(key=lambda char: -char["speed"])
  for char in turn_order:
    print(char["name"])
    char["progress"] -= target